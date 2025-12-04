import SwiftUI

private let mobileDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd MMM, HH:mm"
    return formatter
}()

struct MobileQueueView: View {
    @EnvironmentObject var queueManager: QueueManager
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                if queueManager.items.isEmpty {
                    emptyStateView
                } else {
                    queueListView
                }
            }
            .navigationTitle("Queue")
            .navigationDestination(for: EnumNavigationItem.self) { item in
                viewForItem(item)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            VStack(spacing: 8) {
                Text("No items in queue")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text("Submit a prompt from the Generate tab and it will appear here.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(32)
    }
    
    private var queueListView: some View {
        List {
            if !queueManager.inProgressItems.isEmpty {
                Section {
                    ForEach(queueManager.inProgressItems, id: \.id) { item in
                        MobileQueueItemRow(item: item)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            queueManager.cancelItem(queueManager.inProgressItems[index])
                        }
                    }
                } header: {
                    MobileQueueSectionHeader(title: "In Progress", count: queueManager.inProgressItems.count)
                }
            }
            
            if !queueManager.successfulItems.isEmpty {
                Section {
                    ForEach(queueManager.successfulItems, id: \.id) { item in
                        MobileQueueItemRow(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if item.isVideoGeneration, let setId = item.resultVideoSetId {
                                    navigationPath.append(EnumNavigationItem.generationVideo(setId: setId))
                                } else if let setId = item.resultSetId {
                                    navigationPath.append(EnumNavigationItem.generationImage(setId: setId))
                                }
                                queueManager.removeItem(item)
                            }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            queueManager.removeItem(queueManager.successfulItems[index])
                        }
                    }
                } header: {
                    HStack {
                        MobileQueueSectionHeader(title: "Completed", count: queueManager.successfulItems.count)
                        Spacer()
                        Button("Clear All") {
                            queueManager.clearAllCompleted()
                        }
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    }
                }
            }
            
            if !queueManager.failedItems.isEmpty {
                Section {
                    ForEach(queueManager.failedItems, id: \.id) { item in
                        MobileQueueItemRow(item: item)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            queueManager.removeItem(queueManager.failedItems[index])
                        }
                    }
                } header: {
                    HStack {
                        MobileQueueSectionHeader(title: "Failed", count: queueManager.failedItems.count)
                        Spacer()
                        Button("Clear All") {
                            queueManager.clearAllFailed()
                        }
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct MobileQueueSectionHeader: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
            Text("(\(count))")
                .foregroundColor(.secondary.opacity(0.7))
        }
    }
}

struct MobileQueueItemRow: View {
    @ObservedObject var item: QueueItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            statusIcon
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.prompt)
                    .font(.body)
                    .lineLimit(3)
                    .foregroundColor(.primary)
                
                Text(mobileDateFormatter.string(from: item.createdAt))
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                if let error = item.errorMessage, item.status == .failed {
                    Text(error)
                        .font(.callout)
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
            }
            
            Spacer(minLength: 0)
            
            if item.status == .successful {
                Image(systemName: "chevron.right")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(.top, 6)
                    .padding(.trailing, 8)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch item.status {
        case .inProgress:
            ProgressView()
        case .successful:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.title3)
                .foregroundColor(.red)
        }
    }
}

