import Foundation
import Combine

class SectorsViewModel: ObservableObject {
    @Published var sectors: [Sector] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "https://api.coingecko.com/api/v3"
    private var lastFetchTime: Date?
    private let rateLimitInterval: TimeInterval = 10 // 10 seconds between requests
    private let cacheExpirationTime: TimeInterval = 600 // 10 minutes cache
    private let requestTimeout: TimeInterval = 15 // 15 seconds timeout
    private var requestRetryCount = 0
    private let maxRetryAttempts = 3
    private var isRetrying = false
    
    // In-memory cache for faster access
    private var inMemorySectors: [Sector]?
    private var inMemoryLastFetch: Date?
    
    init() {
        loadCaches()
    }
    
    private func loadCaches() {
        print("Loading SectorsViewModel caches...")
        // Load cached data if available
        if let cachedData = UserDefaults.standard.data(forKey: "cachedSectorsData"),
           let lastFetch = UserDefaults.standard.object(forKey: "lastSectorsFetch") as? Date,
           Date().timeIntervalSince(lastFetch) < cacheExpirationTime {
            do {
                let cached = try JSONDecoder().decode([Sector].self, from: cachedData)
                // Store in memory for faster access next time
                self.inMemorySectors = cached
                self.inMemoryLastFetch = lastFetch
                
                // Sort and update the published sectors
                self.sectors = sortSectors(cached)
                print("Loaded sectors data from cache (last updated: \(formatTimeAgo(from: lastFetch)))")
            } catch {
                print("Error decoding cached sectors data: \(error)")
                fetchSectors()
            }
        } else {
            fetchSectors()
        }
    }
    
    private func formatTimeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 {
            return "\(Int(seconds))s ago"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))m ago"
        } else {
            return "\(Int(seconds / 3600))h ago"
        }
    }
    
    func fetchSectors(forceRefresh: Bool = false) {
        // Check if we're already loading
        if isLoading && !isRetrying {
            print("Already loading sectors data")
            return
        }
        
        // Check in-memory cache first (fastest)
        if !forceRefresh, 
           let cached = inMemorySectors,
           let lastFetch = inMemoryLastFetch,
           Date().timeIntervalSince(lastFetch) < cacheExpirationTime {
            print("Using in-memory cached sectors data (last updated: \(formatTimeAgo(from: lastFetch)))")
            self.sectors = sortSectors(cached)
            return
        }
        
        // Check rate limiting
        if !forceRefresh && !isRetrying,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < rateLimitInterval {
            print("Rate limiting: Waiting before next sectors data request")
            return
        }
        
        isLoading = true
        lastFetchTime = Date()
        
        let urlString = "\(baseURL)/coins/categories"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = requestTimeout
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                }
                
                if httpResponse.statusCode == 429 {
                    throw NSError(domain: "", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded. Please try again later."])
                }
                
                if httpResponse.statusCode != 200 {
                    throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
                }
                
                return data
            }
            .decode(type: [Sector].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .retry(2) // Retry up to 2 times on network issues
            .sink { [weak self] completion in
                guard let self = self else { return }
                
                if case .failure(let error) = completion {
                    print("Error fetching sectors data: \(error.localizedDescription)")
                    
                    // Try to use most recent cache if it exists
                    if let cached = self.inMemorySectors {
                        print("Using previous cached data despite fetch error")
                        self.sectors = sortSectors(cached)
                    } else {
                        self.error = error
                    }
                    
                    // Implement retry logic
                    if self.requestRetryCount < self.maxRetryAttempts && !self.isRetrying {
                        self.requestRetryCount += 1
                        print("Retrying sectors data fetch (attempt \(self.requestRetryCount)/\(self.maxRetryAttempts))")
                        self.isRetrying = true
                        
                        // Exponential backoff for retries (2^retry_count seconds)
                        let delay = pow(2.0, Double(self.requestRetryCount))
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            self.isRetrying = false
                            self.fetchSectors(forceRefresh: true)
                        }
                    } else {
                        // Reset retry counter
                        self.requestRetryCount = 0
                        self.isLoading = false
                        self.isRetrying = false
                    }
                } else {
                    // Success - reset retry counter
                    self.requestRetryCount = 0
                    self.isRetrying = false
                    self.isLoading = false
                }
            } receiveValue: { [weak self] sectors in
                guard let self = self else { return }
                
                // Update in-memory cache
                self.inMemorySectors = sectors
                self.inMemoryLastFetch = Date()
                
                // Cache to UserDefaults
                if let encoded = try? JSONEncoder().encode(sectors) {
                    UserDefaults.standard.set(encoded, forKey: "cachedSectorsData")
                    UserDefaults.standard.set(Date(), forKey: "lastSectorsFetch")
                    print("Cached sectors data")
                }
                
                // Sort and update the published sectors
                self.sectors = sortSectors(sectors)
                self.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    private func sortSectors(_ sectors: [Sector]) -> [Sector] {
        // Sort sectors by market cap, putting null values at the end
        return sectors.sorted { s1, s2 in
            switch (s1.marketCap, s2.marketCap) {
            case (let mc1?, let mc2?):
                return mc1 > mc2
            case (nil, .some(_)):
                return false
            case (.some(_), nil):
                return true
            case (nil, nil):
                return s1.name < s2.name // Sort by name if both market caps are nil
            }
        }
    }
    
    // Utility method to purge cache when needed
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: "cachedSectorsData")
        UserDefaults.standard.removeObject(forKey: "lastSectorsFetch")
        inMemorySectors = nil
        inMemoryLastFetch = nil
        print("Sectors data cache cleared")
        
        fetchSectors(forceRefresh: true)
    }
} 