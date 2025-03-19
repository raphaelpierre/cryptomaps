import SwiftUI

struct SectorDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var currencySettings: CurrencySettings
    @ObservedObject var cryptoViewModel: CryptoViewModel
    let sector: Sector
    
    // Cache formatted values
    private let marketCapFormatted: String
    private let changeFormatted: String
    private let coinUrls: [String]
    
    init(cryptoViewModel: CryptoViewModel, sector: Sector) {
        self.cryptoViewModel = cryptoViewModel
        self.sector = sector
        
        // Pre-compute formatted values to avoid recalculation during rendering
        if let marketCap = sector.marketCap {
            let billion = 1_000_000_000.0
            let million = 1_000_000.0
            
            if marketCap >= billion {
                self.marketCapFormatted = String(format: "%.2fB", marketCap / billion)
            } else if marketCap >= million {
                self.marketCapFormatted = String(format: "%.2fM", marketCap / million)
            } else {
                self.marketCapFormatted = String(format: "%.2f", marketCap)
            }
        } else {
            self.marketCapFormatted = "N/A"
        }
        
        if let change = sector.marketCapChange24h {
            self.changeFormatted = String(format: "%.1f", change)
        } else {
            self.changeFormatted = "0.0"
        }
        
        // Cache a copy of the coin URLs to avoid repeated array access
        self.coinUrls = Array(sector.top3Coins.prefix(3))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header - simplified layout
                    headerView
                    
                    // Content cards - extracted to separate views
                    VStack(spacing: 20) {
                        // Market Cap
                        if let marketCap = sector.marketCap {
                            marketCapCard(marketCap: marketCap)
                        }
                        
                        // Description
                        if let content = sector.content {
                            descriptionCard(content: content)
                        }
                        
                        // Top Coins
                        if !coinUrls.isEmpty {
                            topCoinsCard
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle(sector.name)
            #if os(iOS) || os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Extracted Views for Better Performance
    
    private var headerView: some View {
        HStack(spacing: 16) {
            // Icon with fixed size to avoid layout shifts
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                Image(systemName: sector.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(.primary)
            }
            .frame(width: 70, height: 70)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(sector.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let change = sector.marketCapChange24h {
                    Text("\(changeFormatted)% (24h)")
                        .font(.headline)
                        .foregroundColor(change >= 0 ? .green : .red)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func marketCapCard(marketCap: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Market Cap")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(currencySettings.currencySymbol)\(marketCapFormatted)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
    }
    
    private func descriptionCard(content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true) // Ensures text layout is calculated once
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
    }
    
    private var topCoinsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Coins")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                ForEach(coinUrls, id: \.self) { coinUrl in
                    CoinImageView(imageUrl: coinUrl)
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
    }
    
    // Shared background for all cards
    private var cardBackground: some View {
        Color.secondary.opacity(0.1)
    }
}

// MARK: - Helper Components

struct CoinImageView: View {
    let imageUrl: String
    
    var body: some View {
        AsyncImage(url: URL(string: imageUrl)) { phase in
            switch phase {
            case .empty:
                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 64, height: 64)
                    ProgressView()
                }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
            case .failure:
                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 64, height: 64)
                    Image(systemName: "bitcoinsign.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(12)
                        .foregroundColor(.orange)
                }
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: 64, height: 64)
    }
}

#Preview {
    let sectorJSON = """
    {
        "id": "defi",
        "name": "DeFi",
        "market_cap": 45000000000,
        "market_cap_change_24h": 2.5,
        "content": "Decentralized Finance (DeFi) is an emerging financial technology based on secure distributed ledgers similar to those used by cryptocurrencies.",
        "top_3_coins": [
            "https://assets.coingecko.com/coins/images/12632/small/IMG_0440.PNG",
            "https://assets.coingecko.com/coins/images/13442/small/aave.png",
            "https://assets.coingecko.com/coins/images/10775/small/COMP.png"
        ]
    }
    """
    let mockSector = try! JSONDecoder().decode(Sector.self, from: sectorJSON.data(using: .utf8)!)
    
    return SectorDetailView(
        cryptoViewModel: CryptoViewModel(),
        sector: mockSector
    )
    .environmentObject(CurrencySettings())
} 