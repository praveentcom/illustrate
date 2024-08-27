import Charts
import SwiftData
import SwiftUI

struct UsageMetricsUnit: Identifiable {
    var id: UUID = .init()
    var date: Date
    var sizeUtilized: Double
    var costIncurred: Double
    var totalGenerations: Int
}

struct UsageMetrics {
    var dailyMetrics: [UsageMetricsUnit]
    var generationMetrics: [UsageMetricsUnit]
    var overallMetrics: UsageMetricsUnit?
}

struct UsageMetricsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ConnectionKey.createdAt, order: .reverse) private var connectionKeys: [ConnectionKey]

    @State private var selectedConnectionKey: ConnectionKey? = nil

    func getMetrics() -> UsageMetrics {
        if let connection = connections.first(where: { $0.connectionId == selectedConnectionKey?.connectionId }) {
            let models: [ConnectionModel] = connectionModels.filter { $0.connectionId == connection.connectionId }
            let modelIds: [String] = models.map { $0.modelId.uuidString }
            let dateLimit = Date().addingTimeInterval(-30 * 24 * 60 * 60)
            let fetchDescriptor = FetchDescriptor<Generation>(
                predicate: #Predicate { modelIds.contains($0.modelId) },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )

            do {
                let generations = try modelContext.fetch(fetchDescriptor)
                let generationMetrics: [UsageMetricsUnit] = generations
                    .filter { $0.createdAt >= dateLimit }
                    .compactMap {
                        .init(
                            date: $0.createdAt,
                            sizeUtilized: Double(String(format: "%.2f", Double($0.size) / 1_000_000.0)) ?? 0.0,
                            costIncurred: $0.creditUsed,
                            totalGenerations: 1
                        )
                    }

                let dailyMetrics: [UsageMetricsUnit] = Dictionary(grouping: generationMetrics, by: { Calendar.current.startOfDay(for: $0.date) })
                    .map { date, metrics in
                        UsageMetricsUnit(
                            date: date,
                            sizeUtilized: metrics.reduce(0) { $0 + $1.sizeUtilized },
                            costIncurred: metrics.reduce(0) { $0 + $1.costIncurred },
                            totalGenerations: metrics.reduce(0) { $0 + $1.totalGenerations }
                        )
                    }
                    .sorted(by: { $0.date > $1.date })

                let overallMetrics: [UsageMetricsUnit] = generations
                    .compactMap {
                        .init(
                            date: $0.createdAt,
                            sizeUtilized: Double(String(format: "%.2f", Double($0.size) / 1_000_000.0)) ?? 0.0,
                            costIncurred: $0.creditUsed,
                            totalGenerations: 1
                        )
                    }

                return UsageMetrics(
                    dailyMetrics: dailyMetrics,
                    generationMetrics: generationMetrics,
                    overallMetrics: .init(
                        date: Date(),
                        sizeUtilized: overallMetrics.reduce(0) { $0 + $1.sizeUtilized },
                        costIncurred: overallMetrics.reduce(0) { $0 + $1.costIncurred },
                        totalGenerations: overallMetrics.reduce(0) { $0 + $1.totalGenerations }
                    )
                )
            } catch {
                print("Error fetching data: \(error)")
            }
        }

        return UsageMetrics(dailyMetrics: [], generationMetrics: [], overallMetrics: nil)
    }

    let columns: [GridItem] = {
        #if os(macOS)
            return Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)
        #else
            return Array(repeating: GridItem(.flexible(), spacing: 12), count: UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1)
        #endif
    }()

    var body: some View {
        Form {
            Section("Select Connection") {
                if connectionKeys.isEmpty {
                    Text("No connections available to select.")
                        .foregroundStyle(secondaryLabel)
                        .padding()
                } else {
                    Picker("Connection", selection: $selectedConnectionKey) {
                        ForEach(connectionKeys, id: \.connectionId) { connectionKey in
                            let connection = getConnection(connectionId: connectionKey.connectionId)

                            Text(connection?.connectionName ?? "").tag(connectionKey as ConnectionKey?)
                        }
                    }
                }

                if selectedConnectionKey != nil {
                    HStack {
                        Text("Overall Generations")
                        Spacer()
                        Text(getMetrics().overallMetrics?.totalGenerations.formatted() ?? "")
                    }
                    HStack {
                        Text("Overall Cost")
                        Spacer()
                        if let doubleValue = getMetrics().overallMetrics?.costIncurred {
                            if getConnection(connectionId: selectedConnectionKey!.connectionId)!.creditCurrency == .USD {
                                Text("$\(doubleValue, specifier: "%.2f")")
                            } else if getConnection(connectionId: selectedConnectionKey!.connectionId)!.creditCurrency == .CREDITS {
                                Text("\(doubleValue, specifier: "%.0f") credits")
                            }
                        }
                    }
                    HStack {
                        Text("Overall Storage")
                        Spacer()
                        if let doubleValue = getMetrics().overallMetrics?.sizeUtilized {
                            Text("\(doubleValue, specifier: "%.0f") MB")
                        }
                    }
                }
            }

            if selectedConnectionKey != nil {
                Section("Metrics for last 30 days") {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Total Generations")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Chart(getMetrics().dailyMetrics) { metric in
                            BarMark(
                                x: .value("Date", metric.date),
                                y: .value("Count", metric.totalGenerations)
                            )
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .padding(.bottom, 8)
                        .frame(height: 200)
                    }
                    .padding(.all, 12)
                    .frame(alignment: .topLeading)

                    VStack(alignment: .leading, spacing: 24) {
                        Text("Cost Incurred")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Chart(getMetrics().dailyMetrics) { metric in
                            BarMark(
                                x: .value("Date", metric.date),
                                y: .value("Cost", metric.costIncurred)
                            )
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel {
                                    if let doubleValue = value.as(Double.self) {
                                        if getConnection(connectionId: selectedConnectionKey!.connectionId)!.creditCurrency == .USD {
                                            Text("$\(doubleValue, specifier: "%.2f")")
                                        } else if getConnection(connectionId: selectedConnectionKey!.connectionId)!.creditCurrency == .CREDITS {
                                            Text("\(doubleValue, specifier: "%.0f") credits")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 8)
                        .frame(height: 200)
                    }
                    .padding(.all, 12)
                    .frame(alignment: .topLeading)

                    VStack(alignment: .leading, spacing: 24) {
                        Text("Storage Utilized")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Chart(getMetrics().dailyMetrics) { metric in
                            BarMark(
                                x: .value("Date", metric.date),
                                y: .value("Storage", metric.sizeUtilized)
                            )
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel {
                                    if let doubleValue = value.as(Double.self) {
                                        Text("\(doubleValue, specifier: "%.0f") MB")
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 8)
                        .frame(height: 200)
                    }
                    .padding(.all, 12)
                    .frame(alignment: .topLeading)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            loadData()
        }
        .navigationTitle("Usage Metrics")
    }

    func loadData() {
        if !connectionKeys.isEmpty {
            selectedConnectionKey = connectionKeys.first
        }
    }
}
