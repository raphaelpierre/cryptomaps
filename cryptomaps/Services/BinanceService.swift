import Foundation
import Combine

struct BinanceService {
    private let baseURL = "https://api.binance.com/api/v3"
    
    func fetchTickers() -> AnyPublisher<[Cryptocurrency], Error> {
        guard let url = URL(string: "\(baseURL)/ticker/24hr") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        print("Fetching data from Binance...")
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response in
                print("Received data from Binance")
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                
                // Print the raw JSON for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON (first 200 chars): \(String(jsonString.prefix(200)))")
                }
                
                return data
            }
            .decode(type: [Cryptocurrency].self, decoder: JSONDecoder())
            .map { cryptocurrencies in
                print("Successfully decoded \(cryptocurrencies.count) cryptocurrencies")
                return cryptocurrencies
            }
            .catch { error in
                print("Error fetching/decoding data: \(error)")
                return Empty<[Cryptocurrency], Error>()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func fetchPriceHistory(for symbol: String, interval: String = "1d") -> AnyPublisher<[PriceHistory], Error> {
        guard let url = URL(string: "\(baseURL)/klines?symbol=\(symbol)&interval=\(interval)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [[String]].self, decoder: JSONDecoder())
            .map { klines in
                klines.map { kline in
                    let timestamp = Date(timeIntervalSince1970: (Double(kline[0]) ?? 0) / 1000)
                    let value = Double(kline[4]) ?? 0
                    return PriceHistory(timestamp: timestamp, value: value)
                }
            }
            .eraseToAnyPublisher()
    }
} 