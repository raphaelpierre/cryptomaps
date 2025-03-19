import SwiftUI

struct TokenGridView: View {
    let tokens: [Cryptocurrency]
    @State private var selectedToken: Cryptocurrency?
    @StateObject private var watchlistViewModel = WatchlistViewModel()
    @ObservedObject var cryptoViewModel: CryptoViewModel
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 400), spacing: 24)
            ], spacing: 24) {
                ForEach(tokens) { token in
                    Button {
                        selectedToken = token
                    } label: {
                        TokenCard(token: token)
                            .overlay(
                                watchlistViewModel.isInWatchlist(token) ?
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                : nil
                            )
                    }
                    .buttonStyle(.card)
                    .contextMenu {
                        Button {
                            watchlistViewModel.toggleWatchlist(for: token)
                        } label: {
                            Label(
                                watchlistViewModel.isInWatchlist(token) ? "Remove from Watchlist" : "Add to Watchlist",
                                systemImage: watchlistViewModel.isInWatchlist(token) ? "star.slash" : "star"
                            )
                        }
                    }
                }
            }
            .padding(32)
        }
        .sheet(item: $selectedToken) { token in
            TokenDetailView(
                token: token, 
                watchlistViewModel: watchlistViewModel,
                cryptoViewModel: cryptoViewModel
            )
        }
    }
}

struct PriceInfoRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

// Preview Provider
struct TokenGridView_Previews: PreviewProvider {
    static var previews: some View {
        TokenGridView(tokens: [], cryptoViewModel: CryptoViewModel())
    }
} 