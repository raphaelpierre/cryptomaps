import Foundation
import Combine

class WatchlistViewModel: ObservableObject {
    @Published var watchlistCryptos: [Cryptocurrency] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let watchlistManager = WatchlistManager()
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "https://api.coingecko.com/api/v3"
    private var lastFetchTime: Date?
    private let rateLimitInterval: TimeInterval = 10 // 10 seconds between requests
    private let cacheExpirationTime: TimeInterval = 600 // 10 minutes cache
    private let requestTimeout: TimeInterval = 15 // 15 seconds timeout
    private var requestRetryCount = 0
    private let maxRetryAttempts = 3
    private var isRetrying = false
    
    // Cache for the watchlist to avoid frequent calls to UserDefaults
    private var cachedWatchlist: Set<String>?
    
    // In-memory cache for faster access
    private var inMemoryWatchlistData: [Cryptocurrency]?
    private var inMemoryLastFetch: Date?
    
    init() {
        // Load the watchlist from UserDefaults only once during initialization
        cachedWatchlist = watchlistManager.getWatchlist()
        loadCaches()
    }
    
    private func loadCaches() {
        print("Loading WatchlistViewModel caches...")
        // Load cached data if available
        if let cachedData = UserDefaults.standard.data(forKey: "cachedWatchlistData"),
           let lastFetch = UserDefaults.standard.object(forKey: "lastWatchlistFetch") as? Date,
           Date().timeIntervalSince(lastFetch) < cacheExpirationTime {
            do {
                let cached = try JSONDecoder().decode([Cryptocurrency].self, from: cachedData)
                // Store in memory for faster access next time
                self.inMemoryWatchlistData = cached
                self.inMemoryLastFetch = lastFetch
                
                self.watchlistCryptos = cached
                print("Loaded watchlist data from cache (last updated: \(formatTimeAgo(from: lastFetch)))")
            } catch {
                print("Error decoding cached watchlist data: \(error)")
                fetchWatchlistData()
            }
        } else if !cachedWatchlist!.isEmpty {
            // Only fetch if we have watchlist items
            fetchWatchlistData()
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
    
    func fetchWatchlistData(forceRefresh: Bool = false) {
        let symbols = cachedWatchlist ?? watchlistManager.getWatchlist()
        if symbols.isEmpty {
            watchlistCryptos = []
            return
        }
        
        // Check if we're already loading
        if isLoading && !isRetrying {
            print("Already loading watchlist data")
            return
        }
        
        // Check in-memory cache first (fastest)
        if !forceRefresh, 
           let cached = inMemoryWatchlistData,
           let lastFetch = inMemoryLastFetch,
           Date().timeIntervalSince(lastFetch) < cacheExpirationTime {
            print("Using in-memory cached watchlist data (last updated: \(formatTimeAgo(from: lastFetch)))")
            self.watchlistCryptos = cached
            return
        }
        
        // Check rate limiting
        if !forceRefresh && !isRetrying,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < rateLimitInterval {
            print("Rate limiting: Waiting before next watchlist data request")
            return
        }
        
        isLoading = true
        lastFetchTime = Date()
        
        // Create a comma-separated list of symbols
        let symbolsList = Array(symbols).joined(separator: ",")
        let urlString = "\(baseURL)/coins/markets?vs_currency=usd&ids=\(symbolsList)&order=market_cap_desc&sparkline=false"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = requestTimeout
        
        // Add caching headers
        request.cachePolicy = .returnCacheDataElseLoad
        
        print("Fetching watchlist data...")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                }
                
                if httpResponse.statusCode == 429 {
                    throw NSError(domain: "", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded"])
                }
                
                if httpResponse.statusCode != 200 {
                    throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
                }
                
                return data
            }
            .decode(type: [Cryptocurrency].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .retry(2) // Retry up to 2 times on network issues
            .sink { [weak self] completion in
                guard let self = self else { return }
                
                if case .failure(let error) = completion {
                    print("Error fetching watchlist data: \(error.localizedDescription)")
                    
                    // Try to use most recent cache if it exists
                    if let cached = self.inMemoryWatchlistData {
                        print("Using previous cached data despite fetch error")
                        self.watchlistCryptos = cached
                    } else {
                        self.error = error
                    }
                    
                    // Implement retry logic
                    if self.requestRetryCount < self.maxRetryAttempts && !self.isRetrying {
                        self.requestRetryCount += 1
                        print("Retrying watchlist data fetch (attempt \(self.requestRetryCount)/\(self.maxRetryAttempts))")
                        self.isRetrying = true
                        
                        // Exponential backoff for retries (2^retry_count seconds)
                        let delay = pow(2.0, Double(self.requestRetryCount))
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            self.isRetrying = false
                            self.fetchWatchlistData(forceRefresh: true)
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
            } receiveValue: { [weak self] cryptocurrencies in
                guard let self = self else { return }
                
                // Update in-memory cache
                self.inMemoryWatchlistData = cryptocurrencies
                self.inMemoryLastFetch = Date()
                
                // Cache to UserDefaults
                if let encoded = try? JSONEncoder().encode(cryptocurrencies) {
                    UserDefaults.standard.set(encoded, forKey: "cachedWatchlistData")
                    UserDefaults.standard.set(Date(), forKey: "lastWatchlistFetch")
                    print("Cached watchlist data (\(cryptocurrencies.count) items)")
                }
                
                self.watchlistCryptos = cryptocurrencies
                self.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    func toggleWatchlist(for crypto: Cryptocurrency) {
        // Use our cached watchlist to avoid UserDefaults access
        var symbols = cachedWatchlist ?? watchlistManager.getWatchlist()
        let wasInWatchlist = symbols.contains(crypto.id)
        
        if wasInWatchlist {
            symbols.remove(crypto.id)
            watchlistManager.removeFromWatchlist(crypto.id)
            
            // If in-memory data exists, update it to avoid fetching again
            if var currentData = inMemoryWatchlistData {
                currentData.removeAll { $0.id == crypto.id }
                inMemoryWatchlistData = currentData
                watchlistCryptos = currentData
                
                // Update cache in UserDefaults if we made changes
                if let encoded = try? JSONEncoder().encode(currentData) {
                    UserDefaults.standard.set(encoded, forKey: "cachedWatchlistData")
                    UserDefaults.standard.set(Date(), forKey: "lastWatchlistFetch")
                }
            }
        } else {
            symbols.insert(crypto.id)
            watchlistManager.addToWatchlist(crypto.id)
            
            // We need to fetch the latest data for the newly added crypto
            fetchWatchlistData()
        }
        
        // Update our cache
        cachedWatchlist = symbols
    }
    
    func isInWatchlist(_ crypto: Cryptocurrency) -> Bool {
        // Use our cached watchlist to avoid UserDefaults access
        if let cached = cachedWatchlist {
            return cached.contains(crypto.id)
        }
        return watchlistManager.isInWatchlist(crypto.id)
    }
    
    // Utility method to purge cache when needed
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: "cachedWatchlistData")
        UserDefaults.standard.removeObject(forKey: "lastWatchlistFetch")
        inMemoryWatchlistData = nil
        inMemoryLastFetch = nil
        print("Watchlist data cache cleared")
        
        fetchWatchlistData(forceRefresh: true)
    }
} 