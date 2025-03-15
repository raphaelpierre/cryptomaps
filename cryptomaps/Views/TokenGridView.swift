import SwiftUI

struct TokenGridView: View {
    let tokens: [Cryptocurrency]
    @State private var selectedToken: Cryptocurrency?
    @State private var showingDetail = false
    @State private var showingWatchlistMenu = false
    @StateObject private var watchlistViewModel = WatchlistViewModel()
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 400), spacing: 24)
            ], spacing: 24) {
                ForEach(tokens) { token in
                    Button {
                        selectedToken = token
                        showingDetail = true
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
                            if watchlistViewModel.isInWatchlist(token) {
                                watchlistViewModel.toggleWatchlist(for: token)
                            } else {
                                watchlistViewModel.toggleWatchlist(for: token)
                            }
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
        .fullScreenCover(isPresented: $showingDetail) {
            if let token = selectedToken {
                TokenDetailView(token: token)
            }
        }
    }
}

struct PriceInfoRow: View {
    let title: String
    let value: String
    var valueColor: Color = .white
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
        }
    }
}

// Preview Provider
struct TokenGridView_Previews: PreviewProvider {
    static var previews: some View {
        TokenGridView(tokens: [])
    }
} 