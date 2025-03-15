import SwiftUI

struct GlobalView: View {
    @StateObject private var viewModel = GlobalViewModel()
    @EnvironmentObject private var currencySettings: CurrencySettings
    
    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Loading global data...")
                        .font(.headline)
                } else if let error = viewModel.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        Text("Error loading data")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            viewModel.fetchGlobalData()
                        }
                        .buttonStyle(.card)
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 32) {
                        // Total Market Cap Card
                        if let totalMarketCap = viewModel.totalMarketCap {
                            TotalMarketCapCard(marketCap: totalMarketCap)
                                .buttonStyle(.card)
                        }
                        
                        // Market Share Grid
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 400), spacing: 24)
                        ], spacing: 24) {
                            ForEach(viewModel.marketCapPercentages, id: \.symbol) { item in
                                Button {
                                    // Add haptic feedback or selection handling if needed
                                } label: {
                                    MarketCapCard(symbol: item.symbol, 
                                                percentage: item.percentage, 
                                                marketCap: item.marketCap,
                                                image: item.image)
                                }
                                .buttonStyle(.card)
                            }
                        }
                    }
                    .padding(32)
                }
            }
            .navigationTitle("Global Market")
        }
        .onAppear {
            viewModel.fetchGlobalData()
        }
    }
}

struct TotalMarketCapCard: View {
    @EnvironmentObject private var currencySettings: CurrencySettings
    @FocusState private var isFocused: Bool
    let marketCap: Double
    
    private func formatLargeNumber(_ number: Double) -> String {
        let trillion = 1_000_000_000_000.0
        let billion = 1_000_000_000.0
        
        let convertedNumber = currencySettings.convertPrice(number)
        
        if convertedNumber >= trillion {
            return String(format: "%.2fT", convertedNumber / trillion)
        } else if convertedNumber >= billion {
            return String(format: "%.2fB", convertedNumber / billion)
        } else {
            return String(format: "%.2f", convertedNumber)
        }
    }
    
    var body: some View {
        Button {
            // Add haptic feedback or selection handling if needed
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color(white: 0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Market Cap")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(currencySettings.currencySymbol)\(formatLargeNumber(marketCap))")
                            .font(.system(size: 28))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(white: 0.1))
            .cornerRadius(16)
        }
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .shadow(radius: isFocused ? 10 : 5)
        .animation(.spring(), value: isFocused)
        .focused($isFocused)
    }
}

struct MarketCapCard: View {
    @EnvironmentObject private var currencySettings: CurrencySettings
    @FocusState private var isFocused: Bool
    let symbol: String
    let percentage: Double
    let marketCap: Double
    let image: String
    
    private func formatLargeNumber(_ number: Double) -> String {
        let trillion = 1_000_000_000_000.0
        let billion = 1_000_000_000.0
        
        let convertedNumber = currencySettings.convertPrice(number)
        
        if convertedNumber >= trillion {
            return String(format: "%.2fT", convertedNumber / trillion)
        } else if convertedNumber >= billion {
            return String(format: "%.2fB", convertedNumber / billion)
        } else {
            return String(format: "%.2f", convertedNumber)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                AsyncImage(url: URL(string: image)) { phase in
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
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(symbol.uppercased())
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(String(format: "%.1f", percentage))%")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Market Cap")
                    .font(.title3)
                    .foregroundColor(.gray)
                Text("\(currencySettings.currencySymbol)\(formatLargeNumber(marketCap))")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 8)
                        .opacity(0.3)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(width: max(0, min(geometry.size.width * CGFloat(percentage) / 100, geometry.size.width)))
                        .frame(height: 8)
                        .foregroundColor(.blue)
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
        .padding(24)
        .background(Color(white: 0.1))
        .cornerRadius(16)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .shadow(radius: isFocused ? 10 : 5)
        .animation(.spring(), value: isFocused)
        .focused($isFocused)
    }
} 