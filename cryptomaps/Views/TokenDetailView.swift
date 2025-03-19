import SwiftUI
import Combine

struct TokenDetailView: View {
    @EnvironmentObject private var currencySettings: CurrencySettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var watchlistViewModel: WatchlistViewModel
    // Use shared CryptoViewModel instance if passed, or create a new one
    @ObservedObject private var cryptoViewModel: CryptoViewModel
    
    let token: Cryptocurrency
    @State private var priceHistory: [PriceHistory] = []
    @State private var isLoadingChart = false
    @State private var chartError: Error?
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var cancellables = Set<AnyCancellable>()
    
    // Cache for loaded timeframes to avoid redundant API calls
    @State private var loadedTimeframes: Set<TimeFrame> = []
    
    // Cached values to avoid redundant calculations
    private let tokenName: String
    private let tokenSymbol: String
    
    enum TimeFrame: String, CaseIterable, Identifiable {
        case day = "24h"
        case week = "7d"
        case month = "30d"
        
        var id: String { self.rawValue }
        
        var days: Int {
            switch self {
            case .day: return 1
            case .week: return 7
            case .month: return 30
            }
        }
    }
    
    // Initialize with existing ViewModels to prevent duplicated API calls
    init(token: Cryptocurrency, 
         watchlistViewModel: WatchlistViewModel = WatchlistViewModel(),
         cryptoViewModel: CryptoViewModel = CryptoViewModel()) {
        self.token = token
        self._watchlistViewModel = ObservedObject(wrappedValue: watchlistViewModel)
        self._cryptoViewModel = ObservedObject(wrappedValue: cryptoViewModel)
        
        // Pre-calculate values that won't change
        self.tokenName = token.name
        self.tokenSymbol = token.symbol.uppercased()
    }
    
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
    
    // Cache computed values that don't need to be recalculated on every render
    private var formattedPrice: String {
        "\(currencySettings.currencySymbol)\(String(format: "%.2f", currencySettings.convertPrice(token.lastPrice)))"
    }
    
    private var formattedPriceChange: String {
        "\(String(format: "%.2f", token.priceChangePercentOrZero))%"
    }
    
    private var formattedVolume: String {
        "\(currencySettings.currencySymbol)\(formatLargeNumber(token.volume))"
    }
    
    private var formattedMarketCap: String {
        "\(currencySettings.currencySymbol)\(formatLargeNumber(token.marketCap))"
    }
    
    // Memoize the color to avoid recomputation
    private var priceChangeColor: Color {
        token.priceChangePercentOrZero >= 0 ? .green : .red
    }
    
    private func loadPriceHistory() {
        // Skip if already loading
        if isLoadingChart {
            return
        }
        
        // Check if this timeframe was already loaded
        if loadedTimeframes.contains(selectedTimeFrame) && !priceHistory.isEmpty {
            print("Using cached price history for \(token.symbol) (\(selectedTimeFrame.rawValue))")
            return
        }
        
        isLoadingChart = true
        chartError = nil
        
        print("Loading price history for \(token.symbol) (\(selectedTimeFrame.rawValue))...")
        
        cryptoViewModel.fetchPriceHistory(for: token.id, days: selectedTimeFrame.days)
            .sink { completion in
                isLoadingChart = false
                if case .failure(let error) = completion {
                    chartError = error
                    print("Error loading price history: \(error.localizedDescription)")
                }
            } receiveValue: { history in
                self.priceHistory = history
                self.isLoadingChart = false
                // Mark this timeframe as loaded
                self.loadedTimeframes.insert(self.selectedTimeFrame)
                print("Successfully loaded price history for \(token.symbol) (\(selectedTimeFrame.rawValue))")
            }
            .store(in: &cancellables)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background - cross-platform compatible approach
                (colorScheme == .dark ? Color.black : Color.white)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Header with logo and name
                        tokenHeaderView
                        
                        // Price info
                        tokenPriceInfoView
                        
                        // Price chart
                        tokenPriceChartView
                        
                        // Market stats
                        tokenMarketStatsView
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(tokenName)
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
            .onAppear {
                loadPriceHistory()
            }
            #if os(tvOS)
            // Fix for tvOS 17.0 deprecation
            .onChange(of: selectedTimeFrame) { _, _ in
                loadPriceHistory()
            }
            #else
            // For iOS and macOS
            .onChange(of: selectedTimeFrame) { _ in
                loadPriceHistory()
            }
            #endif
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Extracted Views for Better Performance
    
    private var tokenHeaderView: some View {
        HStack(spacing: 16) {
            // Use standard AsyncImage with cached image extension
            AsyncImage(url: URL(string: token.image)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 80, height: 80)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    Image(systemName: "bitcoinsign.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.orange)
                @unknown default:
                    EmptyView()
                }
            }
            .cacheImage()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tokenName)
                    .font(.system(size: sizeClass == .regular ? 32 : 24, weight: .bold))
                Text(tokenSymbol)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Watchlist Button
            Button {
                watchlistViewModel.toggleWatchlist(for: token)
            } label: {
                Image(systemName: watchlistViewModel.isInWatchlist(token) ? "star.fill" : "star")
                    .font(.system(size: 24))
                    .foregroundColor(watchlistViewModel.isInWatchlist(token) ? .yellow : .gray)
                    .padding(12)
            }
        }
        .padding(.top)
    }
    
    private var tokenPriceInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formattedPrice)
                .font(.system(size: 32, weight: .bold))
            
            HStack(spacing: 8) {
                Text(formattedPriceChange)
                    .font(.headline)
                    .foregroundColor(priceChangeColor)
                
                Image(systemName: token.priceChangePercentOrZero >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.subheadline)
                    .foregroundColor(priceChangeColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var tokenPriceChartView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Price Chart")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Time frame picker
            HStack {
                ForEach(TimeFrame.allCases) { timeframe in
                    Button {
                        selectedTimeFrame = timeframe
                    } label: {
                        Text(timeframe.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTimeFrame == timeframe ? .bold : .regular)
                            .foregroundColor(selectedTimeFrame == timeframe ? .primary : .secondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                selectedTimeFrame == timeframe ? 
                                    Color.accentColor.opacity(0.2) : Color.clear
                            )
                            .cornerRadius(16)
                    }
                }
            }
            
            // Price chart or loading indicator
            if isLoadingChart {
                ProgressView("Loading chart data...")
                    .frame(height: 200)
            } else if let error = chartError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.yellow)
                    
                    Text("Error loading chart data")
                        .font(.headline)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        loadPriceHistory()
                    }
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(height: 200)
            } else {
                PriceChartView(priceHistory: priceHistory, currencySymbol: currencySettings.currencySymbol)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var tokenMarketStatsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Market Stats")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Volume
            HStack {
                Text("Volume (24h)")
                    .font(.body)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formattedVolume)
                    .font(.body)
                    .fontWeight(.semibold)
            }
            
            Divider()
            
            // Market Cap
            HStack {
                Text("Market Cap")
                    .font(.body)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formattedMarketCap)
                    .font(.body)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Preview Provider
#Preview {
    TokenDetailView(
        token: Cryptocurrency(
            id: "bitcoin",
            symbol: "btc",
            name: "Bitcoin",
            lastPrice: 35000,
            priceChangePercent: 2.5,
            volume: 25000000000,
            marketCap: 650000000000,
            image: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png"
        )
    )
    .environmentObject(CurrencySettings())
}

// Extension to help with image caching
extension View {
    func cacheImage() -> some View {
        self.onAppear {
            URLCache.shared.diskCapacity = 1024 * 1024 * 100 // 100 MB
            URLCache.shared.memoryCapacity = 1024 * 1024 * 30 // 30 MB
            
            let configuration = URLSessionConfiguration.default
            configuration.requestCachePolicy = .returnCacheDataElseLoad
            configuration.urlCache = URLCache.shared
            
            URLSession.shared.configuration.urlCache = URLCache.shared
        }
    }
} 