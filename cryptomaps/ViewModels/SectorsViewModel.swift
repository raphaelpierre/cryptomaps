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
    
    func fetchSectors() {
        // Check rate limiting
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < rateLimitInterval {
            print("Rate limiting: Waiting before next request")
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
                
                // Print the raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw response: \(jsonString.prefix(500))")
                }
                
                return data
            }
            .decode(type: [Sector].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("Error: \(error)")
                    self?.error = error
                }
            } receiveValue: { [weak self] sectors in
                // Sort sectors by market cap, putting null values at the end
                self?.sectors = sectors.sorted { s1, s2 in
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
            .store(in: &cancellables)
    }
} 