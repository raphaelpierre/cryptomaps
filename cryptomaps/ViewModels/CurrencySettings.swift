import Foundation
import Combine

class CurrencySettings: ObservableObject {
    @Published var selectedCurrency: String {
        didSet {
            UserDefaults.standard.set(selectedCurrency, forKey: "preferredCurrency")
            updateCurrencySymbol()
            fetchExchangeRateIfNeeded()
        }
    }
    @Published var currencySymbol: String = "$"
    @Published var exchangeRate: Double = 1.0
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    private var lastExchangeRateFetch: [String: Date] = [:]
    private var cachedExchangeRates: [String: Double] = [:]
    
    init() {
        // Load cached exchange rates
        if let savedRates = UserDefaults.standard.dictionary(forKey: "cachedExchangeRates") as? [String: Double] {
            cachedExchangeRates = savedRates
        }
        if let savedFetchTimes = UserDefaults.standard.dictionary(forKey: "lastExchangeRateFetch") as? [String: Date] {
            lastExchangeRateFetch = savedFetchTimes
        }
        
        self.selectedCurrency = UserDefaults.standard.string(forKey: "preferredCurrency") ?? "USD"
        updateCurrencySymbol()
        fetchExchangeRateIfNeeded()
    }
    
    private func updateCurrencySymbol() {
        switch selectedCurrency {
        case "USD":
            currencySymbol = "$"
        case "EUR":
            currencySymbol = "€"
        case "GBP":
            currencySymbol = "£"
        case "JPY":
            currencySymbol = "¥"
        default:
            currencySymbol = "$"
        }
    }
    
    func convertPrice(_ usdPrice: Double) -> Double {
        return usdPrice * exchangeRate
    }
    
    private func fetchExchangeRateIfNeeded() {
        guard selectedCurrency != "USD" else {
            exchangeRate = 1.0
            return
        }
        
        // Check if we have a recent cached rate
        if let lastFetch = lastExchangeRateFetch[selectedCurrency],
           let cachedRate = cachedExchangeRates[selectedCurrency],
           Date().timeIntervalSince(lastFetch) < cacheExpirationTime {
            exchangeRate = cachedRate
            return
        }
        
        isLoading = true
        
        let urlString = "https://api.coingecko.com/api/v3/simple/price?ids=tether&vs_currencies=\(selectedCurrency.lowercased())"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [String: [String: Double]].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("Error fetching exchange rate: \(error)")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                if let rate = response["tether"]?[self.selectedCurrency.lowercased()] {
                    self.exchangeRate = rate
                    // Cache the new rate
                    self.cachedExchangeRates[self.selectedCurrency] = rate
                    self.lastExchangeRateFetch[self.selectedCurrency] = Date()
                    // Save to UserDefaults
                    UserDefaults.standard.set(self.cachedExchangeRates, forKey: "cachedExchangeRates")
                    UserDefaults.standard.set(self.lastExchangeRateFetch, forKey: "lastExchangeRateFetch")
                }
            }
            .store(in: &cancellables)
    }
} 