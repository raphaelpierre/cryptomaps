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
    private let cacheExpirationTime: TimeInterval = 30 // 30 seconds cache
    private let rateLimitInterval: TimeInterval = 10 // 10 seconds between requests
    
    init() {
        print("CryptoViewModel initialized")
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
            }
        }
        fetchCryptocurrencies()
    }
    
    func fetchCryptocurrencies() {
        // Check rate limiting
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < rateLimitInterval {
            print("Rate limiting: Waiting before next request")
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
    
    func fetchPriceHistory(for symbol: String) {
        // Implementation for fetching price history using CoinGecko API
    }
    
    private func sortCryptocurrencies(_ cryptocurrencies: [Cryptocurrency]) -> [Cryptocurrency] {
        return cryptocurrencies.sorted { $0.volume > $1.volume }
    }
} 