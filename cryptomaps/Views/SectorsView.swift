import SwiftUI

struct SectorsView: View {
    @StateObject private var viewModel = SectorsViewModel()
    @EnvironmentObject private var currencySettings: CurrencySettings
    @State private var selectedSector: Sector?
    @State private var showingDetail = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading sectors...")
                        .font(.headline)
                } else if let error = viewModel.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        Text("Error loading sectors")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            viewModel.fetchSectors()
                        }
                        .buttonStyle(.card)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 400), spacing: 24)
                        ], spacing: 24) {
                            ForEach(viewModel.sectors) { sector in
                                Button {
                                    selectedSector = sector
                                    showingDetail = true
                                } label: {
                                    SectorCard(sector: sector)
                                }
                                .buttonStyle(.card)
                            }
                        }
                        .padding(32)
                    }
                }
            }
            .navigationTitle("Sectors")
        }
        .onAppear {
            viewModel.fetchSectors()
        }
        .fullScreenCover(isPresented: $showingDetail) {
            if let sector = selectedSector {
                SectorDetailView(sector: sector)
            }
        }
    }
}

struct SectorCard: View {
    @EnvironmentObject private var currencySettings: CurrencySettings
    @FocusState private var isFocused: Bool
    let sector: Sector
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: sector.iconName)
                    .font(.system(size: 48))
                    .foregroundColor(.white)
                    .frame(width: 60)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(sector.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let change = sector.marketCapChange24h {
                        Text("\(String(format: "%.1f", change))%")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(change >= 0 ? .green : .red)
                    }
                }
            }
            .padding(.vertical, 8)
            
            // Market Data
            if let marketCap = sector.marketCap {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Market Cap")
                        .font(.title3)
                        .foregroundColor(.gray)
                    Text("\(currencySettings.currencySymbol)\(formatLargeNumber(marketCap))")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            
            // Description
            if let content = sector.content {
                Text(content)
                    .font(.body)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            // Top 3 Coins
            if !sector.top3Coins.isEmpty {
                HStack(spacing: 8) {
                    ForEach(sector.top3Coins.prefix(3), id: \.self) { coinUrl in
                        AsyncImage(url: URL(string: coinUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 24, height: 24)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                            case .failure:
                                Image(systemName: "bitcoinsign.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                            @unknown default:
                                Image(systemName: "bitcoinsign.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(Color(white: 0.1))
        .cornerRadius(16)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .shadow(radius: isFocused ? 10 : 5)
        .animation(.spring(), value: isFocused)
        .focused($isFocused)
    }
    
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
} 