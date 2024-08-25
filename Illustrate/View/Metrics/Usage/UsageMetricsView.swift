import SwiftUI
import SwiftData
import Charts

struct UsageMetricsView: View {
    @Query var connectionKeys: [ConnectionKey]
    @State private var selectedConnectionKey: ConnectionKey?
    
    // Sample Data
    @State private var dailyMetrics: [DailyMetric] = [
        DailyMetric(date: Date(), sizeUtilized: 500, costIncurred: 20, totalGenerations: 10),
        DailyMetric(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, sizeUtilized: 300, costIncurred: 15, totalGenerations: 8),
        // Add more sample data here
    ]
    
    var body: some View {
        ScrollView {
            Form {
                Section("Select Connection") {
                    Picker("Connection", selection: $selectedConnectionKey) {
                        ForEach(connectionKeys, id: \.connectionId) { connectionKey in
                            let connection = getConnection(connectionId: connectionKey.connectionId)
                            
                            Text(connection?.connectionName ?? "").tag(connectionKey as ConnectionKey?)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            
            let columns: [GridItem] = {
                #if os(macOS)
                return Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)
                #else
                return Array(repeating: GridItem(.flexible(), spacing: 20), count: UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1)
                #endif
            }()

            if let _ = selectedConnectionKey {
                LazyVGrid(columns: columns, spacing: 20) {
                    Chart(dailyMetrics) { metric in
                        LineMark(
                            x: .value("Date", metric.date),
                            y: .value("Size Utilized", metric.sizeUtilized)
                        )
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 200)
                    .padding(.all, 24)
                    .background(quaternarySystemFill)
                    .cornerRadius(8)

                    // Cost Incurred Chart
                    Chart(dailyMetrics) { metric in
                        BarMark(
                            x: .value("Date", metric.date),
                            y: .value("Cost Incurred", metric.costIncurred)
                        )
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 200)
                    .padding(.all, 24)
                    .background(quaternarySystemFill)
                    .cornerRadius(8)

                    // Total Generations Chart
                    Chart(dailyMetrics) { metric in
                        AreaMark(
                            x: .value("Date", metric.date),
                            y: .value("Total Generations", metric.totalGenerations)
                        )
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 200)
                    .padding(.all, 24)
                    .background(quaternarySystemFill)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)
            } else {
                Text("Please select a Connection to view metrics")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .navigationTitle("Usage Metrics")
    }
}

struct DailyMetric: Identifiable {
    var id: UUID = UUID()
    var date: Date
    var sizeUtilized: Double
    var costIncurred: Double
    var totalGenerations: Int
}
