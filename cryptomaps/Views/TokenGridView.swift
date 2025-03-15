import SwiftUI

struct TokenGridView: View {
    let tokens: [Cryptocurrency]
    @State private var selectedToken: Cryptocurrency?
    @State private var showingDetail = false
    
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
                    }
                    .buttonStyle(.card)
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

struct TokenDetailView: View {
    let token: Cryptocurrency
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCloseButtonFocused: Bool
    
    private func formatLargeNumber(_ number: Double) -> String {
        let billion = 1_000_000_000.0
        let million = 1_000_000.0
        
        if number >= billion {
            return String(format: "$%.2fB", number / billion)
        } else if number >= million {
            return String(format: "$%.2fM", number / million)
        } else {
            return String(format: "$%.2f", number)
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 32) {
                // Header with logo and name
                HStack(spacing: 20) {
                    AsyncImage(url: URL(string: token.image)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 120, height: 120)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                        case .failure:
                            Image(systemName: "bitcoinsign.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                        @unknown default:
                            Image(systemName: "bitcoinsign.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(token.name)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        Text(token.symbol.uppercased())
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 60)
                
                // Price information
                VStack(spacing: 24) {
                    PriceInfoRow(title: "Current Price", value: "$\(String(format: "%.2f", token.lastPrice))")
                    
                    PriceInfoRow(
                        title: "24h Change",
                        value: "\(String(format: "%.2f", token.priceChangePercentOrZero))%",
                        valueColor: token.priceChangePercentOrZero >= 0 ? .green : .red
                    )
                    
                    PriceInfoRow(title: "24h Volume", value: formatLargeNumber(token.volume))
                    
                    PriceInfoRow(title: "Market Cap", value: formatLargeNumber(token.marketCap))
                }
                .padding(40)
                .background(Color(white: 0.15))
                .cornerRadius(20)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.title2)
                        .padding(.horizontal, 60)
                        .padding(.vertical, 20)
                }
                .buttonStyle(.card)
                .focused($isCloseButtonFocused)
                .onAppear {
                    isCloseButtonFocused = true
                }
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 60)
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