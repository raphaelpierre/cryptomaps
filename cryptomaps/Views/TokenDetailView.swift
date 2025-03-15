import SwiftUI

struct TokenDetailView: View {
    @EnvironmentObject private var currencySettings: CurrencySettings
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCloseButtonFocused: Bool
    @AppStorage("showPercentageChange") private var showPercentageChange = true
    @StateObject private var watchlistViewModel = WatchlistViewModel()
    let token: Cryptocurrency
    
    private func formatLargeNumber(_ number: Double) -> String {
        let billion = 1_000_000_000.0
        let million = 1_000_000.0
        
        let convertedNumber = currencySettings.convertPrice(number)
        
        if convertedNumber >= billion {
            return String(format: "%.2fB", convertedNumber / billion)
        } else if convertedNumber >= million {
            return String(format: "%.2fM", convertedNumber / million)
        } else {
            return String(format: "%.2f", convertedNumber)
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 32) {
                // Header with logo and name
                HStack(spacing: 20) {
                    AsyncImage(url: URL(string: token.image)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 120, height: 120)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                        case .failure:
                            Image(systemName: "bitcoinsign.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                        @unknown default:
                            Image(systemName: "bitcoinsign.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(token.name)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        Text(token.symbol.uppercased())
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Watchlist Button
                    Button {
                        watchlistViewModel.toggleWatchlist(for: token)
                    } label: {
                        Image(systemName: watchlistViewModel.isInWatchlist(token) ? "star.fill" : "star")
                            .font(.system(size: 32))
                            .foregroundColor(watchlistViewModel.isInWatchlist(token) ? .yellow : .gray)
                            .padding(16)
                    }
                    .buttonStyle(.card)
                }
                .padding(.top, 60)
                
                // Price information
                VStack(spacing: 24) {
                    PriceInfoRow(
                        title: "Current Price",
                        value: "\(currencySettings.currencySymbol)\(String(format: "%.2f", currencySettings.convertPrice(token.lastPrice)))"
                    )
                    
                    if showPercentageChange {
                        PriceInfoRow(
                            title: "24h Change",
                            value: "\(String(format: "%.2f", token.priceChangePercentOrZero))%",
                            valueColor: token.priceChangePercentOrZero >= 0 ? .green : .red
                        )
                    }
                    
                    PriceInfoRow(
                        title: "24h Volume",
                        value: "\(currencySettings.currencySymbol)\(formatLargeNumber(token.volume))"
                    )
                    
                    PriceInfoRow(
                        title: "Market Cap",
                        value: "\(currencySettings.currencySymbol)\(formatLargeNumber(token.marketCap))"
                    )
                }
                .padding(40)
                .background(Color(white: 0.15))
                .cornerRadius(20)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.title2)
                        .padding(.horizontal, 60)
                        .padding(.vertical, 20)
                }
                .buttonStyle(.card)
                .focused($isCloseButtonFocused)
                .onAppear {
                    isCloseButtonFocused = true
                }
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 60)
        }
    }
} 