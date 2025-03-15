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
    private let cacheExpirationTime: TimeInterval = 30 // 30 seconds cache
    
    init() {
        // Load cached data if available
        if let cachedData = UserDefaults.standard.data(forKey: "cachedGlobalData"),
           let lastFetch = UserDefaults.standard.object(forKey: "lastGlobalFetch") as? Date,
           Date().timeIntervalSince(lastFetch) < cacheExpirationTime {
            do {
                let cached = try JSONDecoder().decode(GlobalData.self, from: cachedData)
                updatePublishedData(from: cached)
                print("Loaded global data from cache")
            } catch {
                print("Error decoding cached global data: \(error)")
            }
        }
        fetchGlobalData()
    }
    
    func fetchGlobalData() {
        // Check rate limiting
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < rateLimitInterval {
            print("Rate limiting: Waiting before next request")
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
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: GlobalData.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.isLoading = false
                    self?.error = error
                }
            } receiveValue: { [weak self] globalData in
                guard let self = self else { return }
                
                // Cache the new data
                if let encoded = try? JSONEncoder().encode(globalData) {
                    UserDefaults.standard.set(encoded, forKey: "cachedGlobalData")
                    UserDefaults.standard.set(Date(), forKey: "lastGlobalFetch")
                }
                
                // Get the top coins by market cap percentage
                let topCoins = globalData.data.marketCapPercentage
                    .sorted { $0.value > $1.value }
                    .prefix(10)
                    .map { $0.key }
                
                // Then fetch detailed coin data using symbols
                let coinsUrl = "\(self.baseURL)/coins/markets?vs_currency=usd&symbols=\(topCoins.joined(separator: ","))&order=market_cap_desc&per_page=10&sparkline=false"
                guard let coinsUrlObj = URL(string: coinsUrl) else { return }
                
                var coinsRequest = URLRequest(url: coinsUrlObj)
                coinsRequest.setValue("application/json", forHTTPHeaderField: "Accept")
                
                print("Fetching coin data for symbols: \(topCoins.joined(separator: ", "))")
                
                URLSession.shared.dataTaskPublisher(for: coinsRequest)
                    .map(\.data)
                    .decode(type: [Cryptocurrency].self, decoder: JSONDecoder())
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] completion in
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            print("Error fetching coin data: \(error)")
                            self?.error = error
                        }
                    } receiveValue: { [weak self] coins in
                        guard let self = self else { return }
                        print("Received \(coins.count) coins")
                        
                        // Create a dictionary mapping symbols to image URLs
                        let coinImages = Dictionary(uniqueKeysWithValues: coins.map { ($0.symbol.lowercased(), $0.image) })
                        
                        self.totalMarketCap = globalData.data.totalMarketCap["usd"]
                        let totalMC = self.totalMarketCap ?? 0
                        
                        self.marketCapPercentages = globalData.data.marketCapPercentage
                            .map { (
                                symbol: $0.key.uppercased(),
                                percentage: $0.value,
                                marketCap: (totalMC * $0.value / 100),
                                image: coinImages[$0.key.lowercased()] ?? ""
                            )}
                            .sorted { $0.percentage > $1.percentage }
                        
                        print("Available symbols in coinImages: \(coinImages.keys.joined(separator: ", "))")
                        print("Market cap percentages: \(self.marketCapPercentages.map { "\($0.symbol): \($0.image)" }.joined(separator: ", "))")
                    }
                    .store(in: &self.cancellables)
            }
            .store(in: &cancellables)
    }
    
    private func updatePublishedData(from globalData: GlobalData) {
        // Get total market cap in USD
        totalMarketCap = globalData.data.totalMarketCap["usd"]
        
        // Convert dictionary to sorted array with market cap data
        let totalMC = totalMarketCap ?? 0
        marketCapPercentages = globalData.data.marketCapPercentage
            .map { (
                symbol: $0.key.uppercased(),
                percentage: $0.value,
                marketCap: (totalMC * $0.value / 100),
                image: ""  // We'll get the actual images from the /coins/markets endpoint
            )}
            .sorted { $0.percentage > $1.percentage }
    }
} 