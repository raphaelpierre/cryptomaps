import Foundation

struct Sector: Decodable, Identifiable {
    let id: String
    let name: String
    let marketCap: Double?
    let volume24h: Double
    let marketCapChange24h: Double?
    let top3Coins: [String]
    let content: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case marketCap = "market_cap"
        case marketCapChange24h = "market_cap_change_24h"
        case content
        case top3Coins = "top_3_coins"
        // Note: volume_24h is not provided in the API response, defaulting to 0
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        marketCap = try container.decodeIfPresent(Double.self, forKey: .marketCap)
        marketCapChange24h = try container.decodeIfPresent(Double.self, forKey: .marketCapChange24h)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        top3Coins = try container.decodeIfPresent([String].self, forKey: .top3Coins) ?? []
        volume24h = 0 // Default value since it's not provided in the API
    }
    
    var iconName: String {
        switch id {
        case "decentralized-finance-defi": return "dollarsign.circle"
        case "non-fungible-tokens-nft": return "paintpalette"
        case "gaming": return "gamecontroller"
        case "metaverse": return "vr"
        case "privacy": return "lock.shield"
        case "smart-contract-platform": return "1.circle"
        case "scaling": return "2.circle"
        case "exchange-based-tokens": return "arrow.2.squarepath"
        case "layer-1": return "network"
        case "infrastructure": return "server.rack"
        case "stablecoins": return "equal.circle"
        case "meme-token": return "face.smiling"
        default: return "circle.hexagongrid"
        }
    }
} 