import SwiftUI
import Charts

struct PriceChartView: View {
    let priceHistory: [PriceHistory]
    let currencySymbol: String
    
    // Calculate min and max values for proper scaling
    private var minValue: Double {
        return priceHistory.map { $0.value }.min() ?? 0
    }
    
    private var maxValue: Double {
        return priceHistory.map { $0.value }.max() ?? 0
    }
    
    // Format date for axis labels
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    // Format price for tooltip
    private func formatPrice(_ price: Double) -> String {
        return "\(currencySymbol)\(String(format: "%.2f", price))"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Price History (7 Days)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, *) {
                Chart {
                    ForEach(priceHistory) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.timestamp),
                            y: .value("Price", dataPoint.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            priceHistory.first?.value ?? 0 <= priceHistory.last?.value ?? 0 ? Color.green : Color.red
                        )
                        
                        AreaMark(
                            x: .value("Date", dataPoint.timestamp),
                            y: .value("Price", dataPoint.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            .linearGradient(
                                colors: [
                                    (priceHistory.first?.value ?? 0 <= priceHistory.last?.value ?? 0 ? Color.green : Color.red).opacity(0.3),
                                    (priceHistory.first?.value ?? 0 <= priceHistory.last?.value ?? 0 ? Color.green : Color.red).opacity(0.01)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .chartYScale(domain: minValue * 0.95...maxValue * 1.05)
                .chartXAxis {
                    AxisMarks(position: .bottom, values: .automatic(desiredCount: 5)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(formatDate(date))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                        if let price = value.as(Double.self) {
                            AxisValueLabel {
                                Text(formatPrice(price))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 200)
            } else {
                // Fallback for older OS versions
                LegacyChartView(priceHistory: priceHistory, currencySymbol: currencySymbol)
            }
        }
    }
}

struct LegacyChartView: View {
    let priceHistory: [PriceHistory]
    let currencySymbol: String
    
    var body: some View {
        // Basic line chart for older OS versions
        GeometryReader { geometry in
            if !priceHistory.isEmpty {
                Path { path in
                    let maxValue = priceHistory.map { $0.value }.max() ?? 0
                    let minValue = priceHistory.map { $0.value }.min() ?? 0
                    let range = maxValue - minValue
                    
                    let step = geometry.size.width / CGFloat(priceHistory.count - 1)
                    
                    var xPosition: CGFloat = 0
                    
                    path.move(to: CGPoint(
                        x: xPosition,
                        y: geometry.size.height * (1 - CGFloat((priceHistory[0].value - minValue) / range))
                    ))
                    
                    for i in 1..<priceHistory.count {
                        xPosition += step
                        let yPosition = geometry.size.height * (1 - CGFloat((priceHistory[i].value - minValue) / range))
                        path.addLine(to: CGPoint(x: xPosition, y: yPosition))
                    }
                }
                .stroke(
                    priceHistory.first?.value ?? 0 <= priceHistory.last?.value ?? 0 ? Color.green : Color.red,
                    lineWidth: 2
                )
                
                // Add some data point indicators
                ForEach(0..<min(priceHistory.count, 5), id: \.self) { index in
                    let i = index * (priceHistory.count / 5)
                    if i < priceHistory.count {
                        let maxValue = priceHistory.map { $0.value }.max() ?? 0
                        let minValue = priceHistory.map { $0.value }.min() ?? 0
                        let range = maxValue - minValue
                        
                        let xPosition = geometry.size.width * (CGFloat(i) / CGFloat(priceHistory.count - 1))
                        let yPosition = geometry.size.height * (1 - CGFloat((priceHistory[i].value - minValue) / range))
                        
                        Circle()
                            .fill(priceHistory.first?.value ?? 0 <= priceHistory.last?.value ?? 0 ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                            .position(x: xPosition, y: yPosition)
                    }
                }
            } else {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .frame(height: 200)
        .overlay(
            VStack(alignment: .leading) {
                if let minPrice = priceHistory.map({ $0.value }).min(),
                   let maxPrice = priceHistory.map({ $0.value }).max() {
                    Text("\(currencySymbol)\(String(format: "%.2f", maxPrice))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 160)
                    
                    Text("\(currencySymbol)\(String(format: "%.2f", minPrice))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 4),
            alignment: .topLeading
        )
    }
}

#Preview("Price Chart") {
    // Sample data for preview
    let sampleData = (0..<20).map { i in
        PriceHistory(
            timestamp: Date().addingTimeInterval(Double(i) * 3600 * 24),
            value: 40000.0 + Double.random(in: -5000...5000)
        )
    }
    
    PriceChartView(priceHistory: sampleData, currencySymbol: "$")
        .padding()
} 