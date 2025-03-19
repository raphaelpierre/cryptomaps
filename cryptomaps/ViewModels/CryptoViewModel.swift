import Foundation
import Combine

class CryptoViewModel: ObservableObject {
    @Published var cryptocurrencies: [Cryptocurrency] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedCrypto: Cryptocurrency?
    
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "https://api.coingecko.com/api/v3"
    private var lastFetchTime: Date?
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes cache (increased from 30 seconds)
    private let rateLimitInterval: TimeInterval = 10 // 10 seconds between requests
    
    // Cache for price history data
    private var priceHistoryCache: [String: [String: [PriceHistory]]] = [:]
    
    init() {
        print("CryptoViewModel initialized")
        loadCachedData()
    }
    
    private func loadCachedData() {
        // Load cached data if available
        if let cachedData = UserDefaults.standard.data(forKey: "cachedCryptoData"),
           let lastFetch = UserDefaults.standard.object(forKey: "lastCryptoFetch") as? Date,
           Date().timeIntervalSince(lastFetch) < cacheExpirationTime {
            do {
                let cached = try JSONDecoder().decode([Cryptocurrency].self, from: cachedData)
                self.cryptocurrencies = cached.sorted { $0.marketCap > $1.marketCap }
                print("Loaded \(cached.count) cryptocurrencies from cache")
            } catch {
                print("Error decoding cached data: \(error)")
                fetchCryptocurrencies()
            }
        } else {
            fetchCryptocurrencies()
        }
        
        // Load price history cache
        if let cachedHistoryData = UserDefaults.standard.data(forKey: "cachedPriceHistoryData"),
           let lastHistoryFetch = UserDefaults.standard.object(forKey: "lastPriceHistoryFetch") as? Date,
           Date().timeIntervalSince(lastHistoryFetch) < cacheExpirationTime {
            do {
                let cached = try JSONDecoder().decode([String: [String: [PriceHistory]]].self, from: cachedHistoryData)
                self.priceHistoryCache = cached
                print("Loaded price history cache")
            } catch {
                print("Error decoding price history cache: \(error)")
            }
        }
    }
    
    func fetchCryptocurrencies() {
        // Check rate limiting
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < rateLimitInterval {
            print("Rate limiting: Waiting before next request")
            return
        }
        
        // Skip if already loading
        if isLoading {
            return
        }
        
        isLoading = true
        lastFetchTime = Date()
        print("Starting to fetch cryptocurrencies...")
        
        let urlString = "\(baseURL)/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=false"
        print("URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            isLoading = false
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Set cache policy and timeout
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 15
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                }
                
                print("Response status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 429 {
                    throw NSError(domain: "", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded. Please try again later."])
                }
                
                if httpResponse.statusCode != 200 {
                    throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
                }
                
                return data
            }
            .decode(type: [Cryptocurrency].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("Error fetching data: \(error)")
                    self?.error = error
                }
            } receiveValue: { [weak self] cryptocurrencies in
                guard let self = self else { return }
                print("Received \(cryptocurrencies.count) cryptocurrencies")
                let sorted = cryptocurrencies.sorted { $0.marketCap > $1.marketCap }
                self.cryptocurrencies = sorted
                
                // Cache the new data
                if let encoded = try? JSONEncoder().encode(sorted) {
                    UserDefaults.standard.set(encoded, forKey: "cachedCryptoData")
                    UserDefaults.standard.set(Date(), forKey: "lastCryptoFetch")
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchPriceHistory(for symbol: String, days: Int = 7) -> AnyPublisher<[PriceHistory], Error> {
        // Check if data is in cache
        let cacheKey = "\(days)"
        if let cachedData = priceHistoryCache[symbol]?[cacheKey],
           !cachedData.isEmpty {
            print("Using cached price history data for \(symbol) (\(days) days)")
            return Just(cachedData)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        let urlString = "\(baseURL)/coins/\(symbol)/market_chart?vs_currency=usd&days=\(days)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 15
        
        // Check rate limiting
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < rateLimitInterval {
            // Add a small delay to avoid rate limiting
            return Deferred {
                Future<Data, Error> { promise in
                    // Wait a bit to avoid hitting rate limits
                    DispatchQueue.global().asyncAfter(deadline: .now() + self.rateLimitInterval) {
                        URLSession.shared.dataTask(with: request) { data, response, error in
                            if let error = error {
                                promise(.failure(error))
                                return
                            }
                            if let data = data {
                                promise(.success(data))
                            } else {
                                promise(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                            }
                        }.resume()
                    }
                }
            }
            .tryMap { data -> Data in
                if let httpResponse = URLResponse() as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
                }
                return data
            }
            .decode(type: PriceHistoryResponse.self, decoder: JSONDecoder())
            .map { [weak self] response -> [PriceHistory] in
                let history = response.prices.map { priceData in
                    let timestamp = Date(timeIntervalSince1970: priceData[0] / 1000)
                    let price = priceData[1]
                    return PriceHistory(timestamp: timestamp, value: price)
                }
                
                // Cache the result
                self?.updatePriceHistoryCache(symbol: symbol, days: days, history: history)
                
                return history
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        }
        
        // No rate limiting concerns, proceed normally
        self.lastFetchTime = Date()
        
        return URLSession.shared.dataTaskPublisher(for: request)
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
            .decode(type: PriceHistoryResponse.self, decoder: JSONDecoder())
            .map { [weak self] response -> [PriceHistory] in
                let history = response.prices.map { priceData in
                    let timestamp = Date(timeIntervalSince1970: priceData[0] / 1000)
                    let price = priceData[1]
                    return PriceHistory(timestamp: timestamp, value: price)
                }
                
                // Cache the result
                self?.updatePriceHistoryCache(symbol: symbol, days: days, history: history)
                
                return history
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func updatePriceHistoryCache(symbol: String, days: Int, history: [PriceHistory]) {
        let daysKey = "\(days)"
        
        if priceHistoryCache[symbol] == nil {
            priceHistoryCache[symbol] = [:]
        }
        
        priceHistoryCache[symbol]?[daysKey] = history
        
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(priceHistoryCache) {
            UserDefaults.standard.set(encoded, forKey: "cachedPriceHistoryData")
            UserDefaults.standard.set(Date(), forKey: "lastPriceHistoryFetch")
        }
        
        print("Cached price history for \(symbol) (\(days) days)")
    }
    
    private func sortCryptocurrencies(_ cryptocurrencies: [Cryptocurrency]) -> [Cryptocurrency] {
        return cryptocurrencies.sorted { $0.volume > $1.volume }
    }
}

// Response model for price history data
struct PriceHistoryResponse: Decodable {
    let prices: [[Double]]
    let market_caps: [[Double]]
    let total_volumes: [[Double]]
} 