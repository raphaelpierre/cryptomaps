import SwiftUI

struct WatchlistView: View {
    @StateObject private var viewModel = WatchlistViewModel()
    @ObservedObject var cryptoViewModel: CryptoViewModel
    @State private var selectedToken: Cryptocurrency?
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading watchlist...")
                        .font(.headline)
                } else if let error = viewModel.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        Text("Error loading watchlist")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            viewModel.fetchWatchlistData()
                        }
                        .buttonStyle(.card)
                    }
                    .padding()
                } else if viewModel.watchlistCryptos.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        Text("Your watchlist is empty")
                            .font(.headline)
                        Text("Add cryptocurrencies from the Market tab")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 400), spacing: 24)
                        ], spacing: 24) {
                            ForEach(viewModel.watchlistCryptos) { crypto in
                                Button {
                                    selectedToken = crypto
                                } label: {
                                    TokenCard(token: crypto)
                                }
                                .buttonStyle(.card)
                            }
                        }
                        .padding(32)
                    }
                }
            }
            .navigationTitle("Watchlist")
            #if os(iOS) || os(macOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            viewModel.fetchWatchlistData()
        }
        .sheet(item: $selectedToken) { token in
            TokenDetailView(token: token, watchlistViewModel: viewModel, cryptoViewModel: cryptoViewModel)
        }
    }
}

#Preview {
    WatchlistView(cryptoViewModel: CryptoViewModel())
} 