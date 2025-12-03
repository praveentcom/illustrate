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
    var totalMetrics: UsageMetricsUnit?
    var totalImages: Int = 0
    var totalVideos: Int = 0
}

struct UsageMetricsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProviderKey.createdAt, order: .reverse) private var providerKeys: [ProviderKey]

    @State private var selectedProviderKey: ProviderKey? = nil

    func getMetrics() -> UsageMetrics {
        if let provider = providers.first(where: { $0.providerId == selectedProviderKey?.providerId }) {
            let models: [ProviderModel] = ProviderService.shared.allModels.filter { $0.providerId == provider.providerId }
            let modelIds: [String] = models.map { $0.modelId.uuidString }
            let videoModelIds: Set<String> = Set(models.filter { 
                $0.modelSetType == .VIDEO_IMAGE || $0.modelSetType == .VIDEO_TEXT || $0.modelSetType == .VIDEO_VIDEO 
            }.map { $0.modelId.uuidString })
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

                let totalMetricsData: [UsageMetricsUnit] = generations
                    .compactMap {
                        .init(
                            date: $0.createdAt,
                            sizeUtilized: Double(String(format: "%.2f", Double($0.size) / 1_000_000.0)) ?? 0.0,
                            costIncurred: $0.creditUsed,
                            totalGenerations: 1
                        )
                    }
                
                let totalVideos = generations.filter { videoModelIds.contains($0.modelId) }.count
                let totalImages = generations.count - totalVideos

                return UsageMetrics(
                    dailyMetrics: dailyMetrics,
                    generationMetrics: generationMetrics,
                    totalMetrics: .init(
                        date: Date(),
                        sizeUtilized: totalMetricsData.reduce(0) { $0 + $1.sizeUtilized },
                        costIncurred: totalMetricsData.reduce(0) { $0 + $1.costIncurred },
                        totalGenerations: totalMetricsData.reduce(0) { $0 + $1.totalGenerations }
                    ),
                    totalImages: totalImages,
                    totalVideos: totalVideos
                )
            } catch {
                print("Error fetching data: \(error)")
            }
        }

        return UsageMetrics(dailyMetrics: [], generationMetrics: [], totalMetrics: nil)
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
            Section("Select Provider") {
                if providerKeys.isEmpty {
                    Text("No providers available to select.")
                        .foregroundStyle(secondaryLabel)
                        .padding()
                } else {
                    Picker("Provider", selection: $selectedProviderKey) {
                        ForEach(providerKeys, id: \.providerId) { providerKey in
                            let provider = getProvider(providerId: providerKey.providerId)

                            Text(provider?.providerName ?? "").tag(providerKey as ProviderKey?)
                        }
                    }
                }

                if selectedProviderKey != nil {
                    HStack {
                        Text("Total Generations")
                        Spacer()
                        Text(getMetrics().totalMetrics?.totalGenerations.formatted() ?? "")
                    }
                    HStack {
                        Text("Images Generated")
                        Spacer()
                        Text(getMetrics().totalImages.formatted())
                    }
                    HStack {
                        Text("Videos Generated")
                        Spacer()
                        Text(getMetrics().totalVideos.formatted())
                    }
                    HStack {
                        Text("Cost Incurred")
                        Spacer()
                        if let doubleValue = getMetrics().totalMetrics?.costIncurred {
                            if getProvider(providerId: selectedProviderKey!.providerId)!.creditCurrency == .USD {
                                Text("$\(doubleValue, specifier: "%.2f")")
                            } else if getProvider(providerId: selectedProviderKey!.providerId)!.creditCurrency == .CREDITS {
                                Text("\(doubleValue, specifier: "%.0f") credits")
                            }
                        }
                    }
                    HStack {
                        Text("Storage Consumed")
                        Spacer()
                        if let doubleValue = getMetrics().totalMetrics?.sizeUtilized {
                            Text("\(doubleValue, specifier: "%.0f") MB")
                        }
                    }
                }
            }

            if selectedProviderKey != nil {
                Section("Metrics for last 30 days") {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Total Generations")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if getMetrics().dailyMetrics.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.secondary)
                                VStack(spacing: 4) {
                                    Text("No generation data")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                    Text("Start generating images to see your usage metrics here")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .frame(height: 200)
                        } else {
                            Chart(getMetrics().dailyMetrics) { metric in
                                BarMark(
                                    x: .value("Date", metric.date),
                                    y: .value("Count", metric.totalGenerations)
                                )
                            }
                            .chartXAxis {
                                AxisMarks { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel {
                                        if let date = value.as(Date.self) {
                                            Text(date, format: .dateTime.month().day())
                                        }
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .padding(.bottom, 8)
                            .frame(height: 200)
                        }
                    }
                    .padding(.all, 12)
                    .frame(alignment: .topLeading)

                    VStack(alignment: .leading, spacing: 24) {
                        Text("Cost Incurred")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if getMetrics().dailyMetrics.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "dollarsign.circle")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.secondary)
                                VStack(spacing: 4) {
                                    Text("No cost data")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                    Text("Start generating images to see your cost metrics here")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .frame(height: 200)
                        } else {
                            Chart(getMetrics().dailyMetrics) { metric in
                                BarMark(
                                    x: .value("Date", metric.date),
                                    y: .value("Cost", metric.costIncurred)
                                )
                            }
                            .chartXAxis {
                                AxisMarks { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel {
                                        if let date = value.as(Date.self) {
                                            Text(date, format: .dateTime.month().day())
                                        }
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel {
                                        if let doubleValue = value.as(Double.self) {
                                            if getProvider(providerId: selectedProviderKey!.providerId)!.creditCurrency == .USD {
                                                Text("$\(doubleValue, specifier: "%.2f")")
                                            } else if getProvider(providerId: selectedProviderKey!.providerId)!.creditCurrency == .CREDITS {
                                                Text("\(doubleValue, specifier: "%.0f") credits")
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 8)
                            .frame(height: 200)
                        }
                    }
                    .padding(.all, 12)
                    .frame(alignment: .topLeading)

                    VStack(alignment: .leading, spacing: 24) {
                        Text("Storage Consumed")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if getMetrics().dailyMetrics.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "internaldrive")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.secondary)
                                VStack(spacing: 4) {
                                    Text("No storage data")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                    Text("Start generating images to see your storage usage here")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .frame(height: 200)
                        } else {
                            Chart(getMetrics().dailyMetrics) { metric in
                                BarMark(
                                    x: .value("Date", metric.date),
                                    y: .value("Storage", metric.sizeUtilized)
                                )
                            }
                            .chartXAxis {
                                AxisMarks { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel {
                                        if let date = value.as(Date.self) {
                                            Text(date, format: .dateTime.month().day())
                                        }
                                    }
                                }
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
        if !providerKeys.isEmpty {
            selectedProviderKey = providerKeys.first
        }
    }
}
