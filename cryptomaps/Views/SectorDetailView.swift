import SwiftUI

struct SectorDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var currencySettings: CurrencySettings
    @FocusState private var isCloseButtonFocused: Bool
    let sector: Sector
    
    private func formatLargeNumber(_ number: Double) -> String {
        let billion = 1_000_000_000.0
        let million = 1_000_000.0
        
        if number >= billion {
            return String(format: "%.2fB", number / billion)
        } else if number >= million {
            return String(format: "%.2fM", number / million)
        } else {
            return String(format: "%.2f", number)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                HStack(spacing: 20) {
                    Image(systemName: sector.iconName)
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(sector.name)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        if let change = sector.marketCapChange24h {
                            Text("\(String(format: "%.1f", change))% (24h)")
                                .font(.title)
                                .foregroundColor(change >= 0 ? .green : .red)
                        }
                    }
                    
                    Spacer()
                    
                    // Close Button
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                            .font(.title2)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.card)
                    .focused($isCloseButtonFocused)
                }
                .padding(.top, 32)
                
                // Market Data
                if let marketCap = sector.marketCap {
                    VStack(spacing: 24) {
                        HStack {
                            Text("Market Cap")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(currencySettings.currencySymbol)\(formatLargeNumber(marketCap))")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(40)
                    .background(Color(white: 0.15))
                    .cornerRadius(20)
                }
                
                // Description
                if let content = sector.content {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text(content)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(40)
                    .background(Color(white: 0.15))
                    .cornerRadius(20)
                }
                
                // Top Coins
                if !sector.top3Coins.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Top Coins")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 24) {
                            ForEach(sector.top3Coins.prefix(3), id: \.self) { coinUrl in
                                AsyncImage(url: URL(string: coinUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 64, height: 64)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 64, height: 64)
                                    case .failure:
                                        Image(systemName: "bitcoinsign.circle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 64, height: 64)
                                    @unknown default:
                                        Image(systemName: "bitcoinsign.circle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 64, height: 64)
                                    }
                                }
                            }
                        }
                    }
                    .padding(40)
                    .background(Color(white: 0.15))
                    .cornerRadius(20)
                }
                
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 32)
        }
        .background(Color.black)
        .onAppear {
            isCloseButtonFocused = true
        }
    }
} 