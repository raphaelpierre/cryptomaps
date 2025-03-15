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
                        TokenGridView(tokens: viewModel.cryptocurrencies)
                    }
                }
                .navigationTitle("Crypto Market")
            }
            .tabItem {
                Label("Market", systemImage: "chart.line.uptrend.xyaxis")
            }
            
            Text("Watchlist")
                .tabItem {
                    Label("Watchlist", systemImage: "star")
                }
            
            Text("Settings")
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onAppear {
            viewModel.fetchCryptocurrencies()
        }
    }
}

#Preview {
    ContentView()
}
