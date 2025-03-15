import Foundation

class WatchlistManager {
    private let userDefaults = UserDefaults.standard
    private let watchlistKey = "watchlist_symbols"
    
    func getWatchlist() -> Set<String> {
        let symbols = userDefaults.array(forKey: watchlistKey) as? [String] ?? []
        return Set(symbols)
    }
    
    func addToWatchlist(_ symbol: String) {
        var symbols = getWatchlist()
        symbols.insert(symbol)
        userDefaults.set(Array(symbols), forKey: watchlistKey)
    }
    
    func removeFromWatchlist(_ symbol: String) {
        var symbols = getWatchlist()
        symbols.remove(symbol)
        userDefaults.set(Array(symbols), forKey: watchlistKey)
    }
    
    func isInWatchlist(_ symbol: String) -> Bool {
        return getWatchlist().contains(symbol)
    }
} 