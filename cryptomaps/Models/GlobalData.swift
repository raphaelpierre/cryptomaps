import Foundation

struct GlobalData: Codable {
    let data: GlobalMarketData
}

struct GlobalMarketData: Codable {
    let marketCapPercentage: [String: Double]
    let totalMarketCap: [String: Double]
    
    enum CodingKeys: String, CodingKey {
        case marketCapPercentage = "market_cap_percentage"
        case totalMarketCap = "total_market_cap"
    }
}

struct CoinData: Codable {
    let id: String
    let symbol: String
    let image: String
} 