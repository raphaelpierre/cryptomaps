import Foundation
import Combine

class GlobalViewModel: ObservableObject {
    @Published var marketCapPercentages: [(symbol: String, percentage: Double, marketCap: Double, image: String)] = []
    @Published var totalMarketCap: Double?
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "https://api.coingecko.com/api/v3"
    private var lastFetchTime: Date?
    private let rateLimitInterval: TimeInterval = 10 // 10 seconds between requests
    private let cacheExpirationTime: TimeInterval = 600 // 10 minutes cache (increased from 5 minutes)
    private var coinImagesCache: [String: String] = [:] // Cache for coin images
    private var isLoadingCoins = false
    private var requestRetryCount = 0
    private let maxRetryAttempts = 3
    private let requestTimeout: TimeInterval = 15 // 15 seconds timeout
    
    // In-memory cache for faster access
    private var inMemoryGlobalData: GlobalData?
    private var inMemoryLastFetch: Date?
    
    // Flag to indicate if we're in a retry state
    private var isRetrying = false
    
    init() {
        loadCaches()
    }
    
    private func loadCaches() {
        print("Loading GlobalViewModel caches...")
        // Load cached data if available
        if let cachedData = UserDefaults.standard.data(forKey: "cachedGlobalData"),
           let lastFetch = UserDefaults.standard.object(forKey: "lastGlobalFetch") as? Date,
           Date().timeIntervalSince(lastFetch) < cacheExpirationTime {
            do {
                let cached = try JSONDecoder().decode(GlobalData.self, from: cachedData)
                // Store in memory for faster access next time
                self.inMemoryGlobalData = cached
                self.inMemoryLastFetch = lastFetch
                
                updatePublishedData(from: cached)
                print("Loaded global data from cache (last updated: \(formatTimeAgo(from: lastFetch)))")
                
                // Load coin images cache
                loadCoinImagesCache(with: cached)
            } catch {
                print("Error decoding cached global data: \(error)")
                fetchGlobalData()
            }
        } else {
            fetchGlobalData()
        }
    }
    
    private func loadCoinImagesCache(with globalData: GlobalData? = nil) {
        if let cachedImageData = UserDefaults.standard.data(forKey: "cachedCoinImages"),
           let coinImages = try? JSONDecoder().decode([String: String].self, from: cachedImageData) {
            self.coinImagesCache = coinImages
            print("Loaded coin images from cache: \(coinImages.count) items")
            updateMarketCapPercentagesWithCachedImages()
            
            // Check if we need to fetch any missing images
            if let globalData = globalData ?? inMemoryGlobalData {
                let topCoins = globalData.data.marketCapPercentage
                    .sorted { $0.value > $1.value }
                    .prefix(15) // Fetch a few more than we display for future use
                    .map { $0.key }
                
                // Only fetch missing images
                let missingCoins = topCoins.filter { !coinImagesCache.keys.contains($0.lowercased()) }
                if !missingCoins.isEmpty {
                    print("Missing images for \(missingCoins.count) coins, will fetch them")
                    fetchCoinImages(for: Array(missingCoins))
                }
            }
        } else if let globalData = globalData ?? inMemoryGlobalData {
            // If we have global data but no images cache, fetch all images
            let topCoins = globalData.data.marketCapPercentage
                .sorted { $0.value > $1.value }
                .prefix(15)
                .map { $0.key }
            
            fetchCoinImages(for: Array(topCoins))
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
    
    func fetchGlobalData(forceRefresh: Bool = false) {
        // Check if we're already loading
        if isLoading && !isRetrying {
            print("Already loading global data")
            return
        }
        
        // Check in-memory cache first (fastest)
        if !forceRefresh, 
           let cached = inMemoryGlobalData,
           let lastFetch = inMemoryLastFetch,
           Date().timeIntervalSince(lastFetch) < cacheExpirationTime {
            print("Using in-memory cached global data (last updated: \(formatTimeAgo(from: lastFetch)))")
            updatePublishedData(from: cached)
            return
        }
        
        // Check rate limiting
        if !forceRefresh && !isRetrying,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < rateLimitInterval {
            print("Rate limiting: Waiting before next global data request")
            return
        }
        
        isLoading = true
        lastFetchTime = Date()
        
        guard let url = URL(string: "\(baseURL)/global") else {
            isLoading = false
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = requestTimeout
        
        print("Fetching global market data...")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: GlobalData.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .retry(3) // Retry up to 3 times on network issues
            .sink { [weak self] completion in
                guard let self = self else { return }
                
                if case .failure(let error) = completion {
                    // Handle the error but continue using cached data if available
                    print("Error fetching global data: \(error.localizedDescription)")
                    
                    // Try to use most recent cache if it exists
                    if let cached = self.inMemoryGlobalData {
                        print("Using previous cached data despite fetch error")
                        self.updatePublishedData(from: cached)
                    } else {
                        self.error = error
                    }
                    
                    // Implement retry logic
                    if self.requestRetryCount < self.maxRetryAttempts && !self.isRetrying {
                        self.requestRetryCount += 1
                        print("Retrying global data fetch (attempt \(self.requestRetryCount)/\(self.maxRetryAttempts))")
                        self.isRetrying = true
                        
                        // Exponential backoff for retries (2^retry_count seconds)
                        let delay = pow(2.0, Double(self.requestRetryCount))
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            self.isRetrying = false
                            self.fetchGlobalData(forceRefresh: true)
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
                }
            } receiveValue: { [weak self] globalData in
                guard let self = self else { return }
                
                // Update in-memory cache
                self.inMemoryGlobalData = globalData
                self.inMemoryLastFetch = Date()
                
                // Cache to UserDefaults
                if let encoded = try? JSONEncoder().encode(globalData) {
                    UserDefaults.standard.set(encoded, forKey: "cachedGlobalData")
                    UserDefaults.standard.set(Date(), forKey: "lastGlobalFetch")
                    print("Cached global market data")
                }
                
                // Update the UI with the global data
                self.updatePublishedData(from: globalData)
                
                // Get the top coins by market cap percentage
                let topCoins = globalData.data.marketCapPercentage
                    .sorted { $0.value > $1.value }
                    .prefix(15) // Get more than we need for future use
                    .map { $0.key }
                
                // Fetch coin images if we don't have them cached
                let missingCoins = topCoins.filter { !self.coinImagesCache.keys.contains($0.lowercased()) }
                if !missingCoins.isEmpty {
                    self.fetchCoinImages(for: Array(missingCoins))
                } else {
                    self.isLoading = false
                    self.updateMarketCapPercentagesWithCachedImages()
                    print("Used cached coin images")
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchCoinImages(for symbols: [String]) {
        // Avoid duplicate fetches
        if isLoadingCoins {
            print("Already fetching coin images")
            return
        }
        
        // If no symbols needed, return early
        if symbols.isEmpty {
            isLoadingCoins = false
            return
        }
        
        isLoadingCoins = true
        print("Fetching coin data for symbols: \(symbols.joined(separator: ", "))")
        
        // Then fetch detailed coin data using symbols
        let coinsUrl = "\(self.baseURL)/coins/markets?vs_currency=usd&symbols=\(symbols.joined(separator: ","))&order=market_cap_desc&per_page=\(symbols.count)&sparkline=false"
        guard let coinsUrlObj = URL(string: coinsUrl) else {
            isLoading = false
            isLoadingCoins = false
            return
        }
        
        var coinsRequest = URLRequest(url: coinsUrlObj)
        coinsRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        coinsRequest.timeoutInterval = requestTimeout
        
        URLSession.shared.dataTaskPublisher(for: coinsRequest)
            .map(\.data)
            .decode(type: [Cryptocurrency].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .retry(2) // Retry up to 2 times for image fetching
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                self.isLoadingCoins = false
                
                if case .failure(let error) = completion {
                    print("Error fetching coin data: \(error)")
                    // Still use what we have in cache
                    self.updateMarketCapPercentagesWithCachedImages()
                }
            } receiveValue: { [weak self] coins in
                guard let self = self else { return }
                print("Received \(coins.count) coins")
                
                // Create a dictionary mapping symbols to image URLs
                let newCoinImages = Dictionary(uniqueKeysWithValues: coins.map { ($0.symbol.lowercased(), $0.image) })
                
                // Update our cache
                var updated = false
                for (symbol, imageUrl) in newCoinImages {
                    if self.coinImagesCache[symbol] == nil || self.coinImagesCache[symbol] != imageUrl {
                        self.coinImagesCache[symbol] = imageUrl
                        updated = true
                    }
                }
                
                // Only save to UserDefaults if there were actual updates
                if updated {
                    if let encoded = try? JSONEncoder().encode(self.coinImagesCache) {
                        UserDefaults.standard.set(encoded, forKey: "cachedCoinImages")
                        print("Cached \(self.coinImagesCache.count) coin images")
                    }
                }
                
                // Update market cap percentages with images
                self.updateMarketCapPercentagesWithCachedImages()
                
                self.isLoading = false
                self.isLoadingCoins = false
            }
            .store(in: &self.cancellables)
    }
    
    private func updatePublishedData(from globalData: GlobalData) {
        // Get total market cap in USD
        totalMarketCap = globalData.data.totalMarketCap["usd"]
        
        // Convert dictionary to sorted array with market cap data
        marketCapPercentages = globalData.data.marketCapPercentage
            .map { (
                symbol: $0.key.uppercased(),
                percentage: $0.value,
                marketCap: (totalMarketCap ?? 0) * $0.value / 100,
                image: coinImagesCache[$0.key.lowercased()] ?? ""  // Use cached image if available
            )}
            .sorted { $0.percentage > $1.percentage }
    }
    
    private func updateMarketCapPercentagesWithCachedImages() {
        // Update the image URLs in our market cap percentages array
        marketCapPercentages = marketCapPercentages.map { item in
            let symbol = item.symbol.lowercased()
            return (
                symbol: item.symbol,
                percentage: item.percentage,
                marketCap: item.marketCap,
                image: coinImagesCache[symbol] ?? item.image
            )
        }
    }
    
    // Utility method to purge cache when needed
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: "cachedGlobalData")
        UserDefaults.standard.removeObject(forKey: "lastGlobalFetch")
        inMemoryGlobalData = nil
        inMemoryLastFetch = nil
        print("Global data cache cleared")
        
        // Don't clear image cache as that rarely changes
        fetchGlobalData(forceRefresh: true)
    }
} 