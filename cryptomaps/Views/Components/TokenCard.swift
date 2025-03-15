import SwiftUI

struct TokenCard: View {
    @EnvironmentObject private var currencySettings: CurrencySettings
    @AppStorage("showPercentageChange") private var showPercentageChange = true
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
        VStack(alignment: .leading, spacing: 16) {
            // Token info
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: token.image)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 60, height: 60)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                    case .failure:
                        Image(systemName: "bitcoinsign.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                    @unknown default:
                        Image(systemName: "bitcoinsign.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(token.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(token.symbol.uppercased())
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            }
            
            // Price info
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Price")
                        .foregroundColor(.gray)
                        .font(.headline)
                    Text("\(currencySettings.currencySymbol)\(String(format: "%.2f", currencySettings.convertPrice(token.lastPrice)))")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                if showPercentageChange {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("24h Change")
                            .foregroundColor(.gray)
                            .font(.headline)
                        HStack(spacing: 4) {
                            Image(systemName: token.priceChangePercentOrZero >= 0 ? "arrow.up.right" : "arrow.down.right")
                            Text("\(String(format: "%.2f", token.priceChangePercentOrZero))%")
                        }
                        .foregroundColor(token.priceChangePercentOrZero >= 0 ? .green : .red)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("24h Volume")
                        .foregroundColor(.gray)
                        .font(.headline)
                    Text("\(currencySettings.currencySymbol)\(formatLargeNumber(token.volume))")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(24)
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }
} 