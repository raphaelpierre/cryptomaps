import SwiftUI

@main
struct CryptoMapApp: App {
    @StateObject private var currencySettings = CurrencySettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(currencySettings)
        }
    }
} 