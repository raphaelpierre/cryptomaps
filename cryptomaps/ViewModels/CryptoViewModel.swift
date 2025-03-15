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
    
    init() {
        print("CryptoViewModel initialized")
        fetchCryptocurrencies()
    }
    
    func fetchCryptocurrencies() {
        // Rate limiting: Wait at least 10 seconds between requests
        if let lastFetch = lastFetchTime, Date().timeIntervalSince(lastFetch) < 10 {
            print("Rate limiting: Waiting before next request")
            return
        }
        
        isLoading = true
        lastFetchTime = Date()
        print("Starting to fetch cryptocurrencies...")
        
        let urlString = "\(baseURL)/coins/markets?vs_currency=usd&order=volume_desc&per_page=100&page=1&sparkline=false"
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
                print("Received \(cryptocurrencies.count) cryptocurrencies")
                self?.cryptocurrencies = cryptocurrencies.sorted { $0.volume > $1.volume }
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