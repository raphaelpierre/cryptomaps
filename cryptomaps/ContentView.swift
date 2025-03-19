//
//  ContentView.swift
//  cryptomaps
//
//  Created by Raphael PIERRE on 15.03.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CryptoViewModel()
    
    var body: some View {
        TabView {
            // Market Tab
            NavigationView {
                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading cryptocurrencies...")
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
                                viewModel.fetchCryptocurrencies()
                            }
                            .buttonStyle(.card)
                        }
                        .padding()
                    } else if viewModel.cryptocurrencies.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No cryptocurrencies available")
                                .font(.headline)
                            Button("Refresh") {
                                viewModel.fetchCryptocurrencies()
                            }
                            .buttonStyle(.card)
                        }
                    } else {
                        TokenGridView(
                            tokens: viewModel.cryptocurrencies,
                            cryptoViewModel: viewModel
                        )
                    }
                }
                .navigationTitle("Crypto Market")
            }
            .tabItem {
                Label("Market", systemImage: "chart.line.uptrend.xyaxis")
            }
            
            // Watchlist Tab
            WatchlistView(cryptoViewModel: viewModel)
                .tabItem {
                    Label("Watchlist", systemImage: "star.fill")
                }
            
            // Sectors Tab
            SectorsView(cryptoViewModel: viewModel)
                .tabItem {
                    Label("Sectors", systemImage: "square.grid.2x2")
                }
            
            // Global Tab
            GlobalView()
                .tabItem {
                    Label("Global", systemImage: "globe")
                }
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onAppear {
            // Fetch data once at startup, then let individual views refresh as needed
            if viewModel.cryptocurrencies.isEmpty {
                viewModel.fetchCryptocurrencies()
            }
        }
    }
}

#Preview {
    ContentView()
}
