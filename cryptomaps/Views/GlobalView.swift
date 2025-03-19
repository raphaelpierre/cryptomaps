import SwiftUI

struct GlobalView: View {
    @StateObject private var viewModel = GlobalViewModel()
    @EnvironmentObject private var currencySettings: CurrencySettings
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedCryptoDominance: (symbol: String, percentage: Double, marketCap: Double, image: String)?
    @State private var showingDetail = false
    
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
                                    selectedCryptoDominance = item
                                    showingDetail = true
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
            #if os(iOS) || os(macOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            viewModel.fetchGlobalData()
        }
        .sheet(isPresented: $showingDetail) {
            if let coin = selectedCryptoDominance {
                NavigationView {
                    GlobalDetailView(coin: coin, totalMarketCap: viewModel.totalMarketCap ?? 0)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .environmentObject(currencySettings)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingDetail = false
                                }
                            }
                        }
                }
                .accentColor(.primary)
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
    }
}

struct TotalMarketCapCard: View {
    @EnvironmentObject private var currencySettings: CurrencySettings
    @Environment(\.colorScheme) private var colorScheme
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
                        .foregroundColor(.primary)
                        .frame(width: 60, height: 60)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Market Cap")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        Text("\(currencySettings.currencySymbol)\(formatLargeNumber(marketCap))")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.1))
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
    @Environment(\.colorScheme) private var colorScheme
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
                            .foregroundColor(.blue)
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(symbol.uppercased())
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(String(format: "%.1f", percentage))%")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Market Cap")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Text("\(currencySettings.currencySymbol)\(formatLargeNumber(marketCap))")
                    .font(.title2)
                    .foregroundColor(.primary)
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
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .shadow(radius: isFocused ? 10 : 5)
        .animation(.spring(), value: isFocused)
        .focused($isFocused)
    }
}

struct GlobalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var currencySettings: CurrencySettings
    
    // Tuple holding the coin information
    let coin: (symbol: String, percentage: Double, marketCap: Double, image: String)
    let totalMarketCap: Double
    
    // Cache formatted values to avoid recalculating
    private let formattedPercentage: String
    private let formattedRestPercentage: String
    
    init(coin: (symbol: String, percentage: Double, marketCap: Double, image: String), totalMarketCap: Double) {
        self.coin = coin
        self.totalMarketCap = totalMarketCap
        self.formattedPercentage = String(format: "%.1f", coin.percentage)
        self.formattedRestPercentage = String(format: "%.1f", 100 - coin.percentage)
    }
    
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
        ScrollView {
            VStack(spacing: 16) {
                // Header with coin logo and symbol
                headerView
                
                // Key information cards with fixed dimensions to prevent layout issues
                marketCapView
                dominanceView
                comparisonView
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .navigationTitle("\(coin.symbol) Dominance")
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
    }
    
    // MARK: - Component Views
    
    private var headerView: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                if let imageUrl = URL(string: coin.image) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                        case .failure:
                            Image(systemName: "bitcoinsign.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        @unknown default:
                            Image(systemName: "bitcoinsign.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                }
            }
            .frame(width: 80, height: 80)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(coin.symbol)
                    .font(.system(size: 28, weight: .bold))
                
                Text("Market Dominance")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formattedPercentage)
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("%")
                        .font(.title3)
                }
                .foregroundColor(.blue)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var marketCapView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Market Cap")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(currencySettings.currencySymbol)
                    .font(.title3)
                
                Text(formatLargeNumber(coin.marketCap))
                    .font(.system(size: 24, weight: .bold))
            }
            .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var dominanceView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Market Dominance")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Fixed height container to prevent layout issues
            VStack {
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 20)
                    
                    // Progress arc
                    Circle()
                        .trim(from: 0, to: CGFloat(min(coin.percentage / 100, 1.0)))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    // Central text
                    VStack(spacing: 0) {
                        Text(formattedPercentage + "%")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("dominance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var comparisonView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Market Comparison")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                // Coin's Market Cap
                VStack(spacing: 8) {
                    Text(coin.symbol)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(formattedPercentage + "%")
                        .font(.title3.bold())
                        .foregroundColor(.blue)
                    
                    Text(currencySettings.currencySymbol + formatLargeNumber(coin.marketCap))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Rest of Market
                VStack(spacing: 8) {
                    Text("Rest of Market")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(formattedRestPercentage + "%")
                        .font(.title3.bold())
                        .foregroundColor(.green)
                    
                    let restValue = totalMarketCap - coin.marketCap
                    Text(currencySettings.currencySymbol + formatLargeNumber(restValue))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Helper Components

struct CoinLogoView: View {
    let imageUrl: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(0.1))
                .frame(width: 80, height: 80)
            
            AsyncImage(url: URL(string: imageUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
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
                        .foregroundColor(.blue)
                @unknown default:
                    EmptyView()
                }
            }
        }
        .frame(width: 80, height: 80)
    }
}

struct ComparisonItem: View {
    let title: String
    let percentage: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("\(percentage)%")
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
} 