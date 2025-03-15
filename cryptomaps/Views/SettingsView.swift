import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var currencySettings: CurrencySettings
    @AppStorage("refreshInterval") private var refreshInterval = 30.0
    @AppStorage("showPercentageChange") private var showPercentageChange = true
    
    private let currencies = ["USD", "EUR", "GBP", "JPY"]
    private let refreshIntervals = [15.0, 30.0, 60.0, 300.0]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Currency Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Currency")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 24) {
                        ForEach(currencies, id: \.self) { currency in
                            Button {
                                currencySettings.selectedCurrency = currency
                            } label: {
                                Text(currency)
                                    .font(.title3)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.card)
                            .opacity(currency == currencySettings.selectedCurrency ? 1.0 : 0.6)
                        }
                    }
                }
                
                // Refresh Interval Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Refresh Interval")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 24) {
                        ForEach(refreshIntervals, id: \.self) { interval in
                            Button {
                                refreshInterval = interval
                            } label: {
                                Text("\(Int(interval))s")
                                    .font(.title3)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.card)
                            .opacity(interval == refreshInterval ? 1.0 : 0.6)
                        }
                    }
                }
                
                // Show Percentage Change Toggle
                VStack(alignment: .leading, spacing: 16) {
                    Text("Display Options")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Button {
                        showPercentageChange.toggle()
                    } label: {
                        HStack {
                            Text("Show Percentage Change")
                                .font(.title3)
                            Spacer()
                            Image(systemName: showPercentageChange ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(showPercentageChange ? .green : .gray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.card)
                }
                
                // About Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("About")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Data Provider")
                            Spacer()
                            Text("CoinGecko")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(20)
                    .background(Color(white: 0.1))
                    .cornerRadius(16)
                }
                
                Spacer()
            }
            .padding(32)
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
} 