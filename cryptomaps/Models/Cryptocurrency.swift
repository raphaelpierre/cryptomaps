import Foundation

struct Cryptocurrency: Codable, Identifiable {
    let id: String
    let symbol: String
    let name: String
    let lastPrice: Double
    let priceChangePercent: Double?
    let volume: Double
    let marketCap: Double
    let image: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case lastPrice = "current_price"
        case priceChangePercent = "price_change_percentage_24h"
        case volume = "total_volume"
        case marketCap = "market_cap"
        case image
    }
    
    var logoUrl: String? {
        // CoinGecko's URL format for logos
        return "https://assets.coingecko.com/coins/images/1/large/\(symbol.lowercased()).png"
    }
    
    var priceChangePercentOrZero: Double {
        return priceChangePercent ?? 0.0
    }
}

struct PriceHistory: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
} 