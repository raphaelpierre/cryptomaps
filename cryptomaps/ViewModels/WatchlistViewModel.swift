import Foundation
import Combine

class WatchlistViewModel: ObservableObject {
    @Published var watchlistCryptos: [Cryptocurrency] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let watchlistManager = WatchlistManager()
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "https://api.coingecko.com/api/v3"
    
    func fetchWatchlistData() {
        let symbols = watchlistManager.getWatchlist()
        if symbols.isEmpty {
            watchlistCryptos = []
            return
        }
        
        isLoading = true
        
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
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] cryptocurrencies in
                self?.watchlistCryptos = cryptocurrencies
            }
            .store(in: &cancellables)
    }
    
    func toggleWatchlist(for crypto: Cryptocurrency) {
        if watchlistManager.isInWatchlist(crypto.id) {
            watchlistManager.removeFromWatchlist(crypto.id)
        } else {
            watchlistManager.addToWatchlist(crypto.id)
        }
        fetchWatchlistData()
    }
    
    func isInWatchlist(_ crypto: Cryptocurrency) -> Bool {
        return watchlistManager.isInWatchlist(crypto.id)
    }
} 