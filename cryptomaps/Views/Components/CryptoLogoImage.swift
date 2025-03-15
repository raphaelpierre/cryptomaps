import SwiftUI

struct CryptoLogoImage: View {
    let symbol: String
    let size: CGFloat
    
    var body: some View {
        if let url = URL(string: "https://assets.coingecko.com/coins/images/1/large/\(symbol.lowercased()).png") {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    // Fallback icon when logo can't be loaded
                    Image(systemName: "bitcoinsign.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                @unknown default:
                    Image(systemName: "bitcoinsign.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .frame(width: size, height: size)
        }
    }
} 