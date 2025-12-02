import SwiftUI

private let sharedDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd MMM, HH:mm"
    return formatter
}()

struct QueueSidebarView: View {
    @ObservedObject var queueManager: QueueManager
    @EnvironmentObject var navigationManager: NavigationManager
    
    @State private var hoveredItemId: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            if queueManager.items.isEmpty {
                emptyStateView
            } else {
                queueListView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            VStack(spacing: 6) {
                Text("No items in generation queue")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Text("Once you submit a prompt, it will appear in the queue.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .opacity(0.7)
        .frame(maxWidth: .infinity)
        .padding(32)
    }
    
    private var queueListView: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: []) {
                if !queueManager.inProgressItems.isEmpty {
                    QueueSection(
                        title: "In Progress",
                        items: queueManager.inProgressItems,
                        hoveredItemId: $hoveredItemId,
                        onItemTap: { _ in },
                        onItemRemove: { item in
                            queueManager.cancelItem(item)
                        }
                    )
                }
                
                if !queueManager.successfulItems.isEmpty {
                    QueueSection(
                        title: "Completed",
                        items: queueManager.successfulItems,
                        hoveredItemId: $hoveredItemId,
                        onItemTap: { item in
                            if item.isVideoGeneration, let setId = item.resultVideoSetId {
                                navigationManager.pushDetail(.generationVideo(setId: setId))
                            } else if let setId = item.resultSetId {
                                navigationManager.pushDetail(.generationImage(setId: setId))
                            }
                            queueManager.removeItem(item)
                        },
                        onItemRemove: { item in
                            queueManager.removeItem(item)
                        },
                        showClearAll: true,
                        onClearAll: {
                            queueManager.clearAllCompleted()
                        }
                    )
                }
                
                if !queueManager.failedItems.isEmpty {
                    QueueSection(
                        title: "Failed",
                        items: queueManager.failedItems,
                        hoveredItemId: $hoveredItemId,
                        onItemTap: { _ in },
                        onItemRemove: { item in
                            queueManager.removeItem(item)
                        },
                        showClearAll: true,
                        onClearAll: {
                            queueManager.clearAllFailed()
                        }
                    )
                }
            }
            .padding(.vertical, 8)
        }
        .scrollContentBackground(.hidden)
    }
}

struct QueueSection: View {
    let title: String
    let items: [QueueItem]
    @Binding var hoveredItemId: UUID?
    let onItemTap: (QueueItem) -> Void
    let onItemRemove: (QueueItem) -> Void
    var showClearAll: Bool = false
    var onClearAll: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader
            
            ForEach(items, id: \.id) { item in
                QueueItemRow(
                    data: QueueItemRowData(from: item),
                    isHovered: hoveredItemId == item.id,
                    onTap: { onItemTap(item) },
                    onRemove: { onItemRemove(item) }
                )
                .id(item.id)
                .onHover { isHovered in
                    if isHovered {
                        hoveredItemId = item.id
                    } else if hoveredItemId == item.id {
                        hoveredItemId = nil
                    }
                }
            }
        }
    }
    
    private var sectionHeader: some View {
        HStack (alignment: .top, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("(\(items.count))")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
            
            Spacer()
            
            if showClearAll, let clearAll = onClearAll {
                Button("Clear") {
                    clearAll()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 12)
    }
}

struct QueueItemRowData: Equatable {
    let id: UUID
    let status: QueueItemStatus
    let prompt: String
    let timeAgo: String
    let errorMessage: String?
    let isVideoGeneration: Bool
    
    init(from item: QueueItem) {
        self.id = item.id
        self.status = item.status
        self.prompt = item.prompt
        self.timeAgo = sharedDateFormatter.string(from: item.createdAt)
        self.errorMessage = item.errorMessage
        self.isVideoGeneration = item.isVideoGeneration
    }
}

struct QueueItemRow: View, Equatable {
    let data: QueueItemRowData
    let isHovered: Bool
    let onTap: () -> Void
    let onRemove: () -> Void
    
    static func == (lhs: QueueItemRow, rhs: QueueItemRow) -> Bool {
        lhs.data == rhs.data && lhs.isHovered == rhs.isHovered
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            statusIcon
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                  Text(data.prompt)
                        .font(.callout)
                        .lineLimit(4)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                  HStack(alignment: .center, spacing: 2) {
                    Text(data.timeAgo)
                      .font(.callout)
                      .foregroundColor(.secondary)
                  }
                }
                
                if let error = data.errorMessage, data.status == .failed {
                    Text(error)
                        .font(.callout)
                        .foregroundColor(.red)
                        .textSelection(.enabled)
                }
            }
            
            Spacer(minLength: 4)
            
            if data.status == .inProgress || data.status == .failed {
              Button {
                  onRemove()
              } label: {
                  Image(systemName: data.status == .inProgress ? "stop.circle.fill" : "xmark.circle.fill")
                      .font(.title3)
                      .foregroundColor(isHovered ? .primary : .clear)
              }
              .buttonStyle(.plain)
              .padding(.top, 6)
              .padding(.trailing, 4)
              .help(data.status == .inProgress ? "Cancel" : "Remove")
            }
            
            if data.status == .successful {
                Image(systemName: "chevron.right")
                    .font(.callout)
                    .foregroundColor(.primary)
                    .padding(.top, 8)
                    .padding(.trailing, 8)
            }
        }
        .padding(.all, 8)
        .background(backgroundFill, in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if data.status == .successful {
                onTap()
            }
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch data.status {
        case .inProgress:
            ProgressView()
                .scaleEffect(0.6)
        case .successful:
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.title2)
                .foregroundColor(.red)
        }
    }
    
    private var backgroundFill: Color {
        switch data.status {
        case .inProgress:
            return Color.accentColor.opacity(isHovered ? 0.2 : 0.1)
        case .successful:
            return Color.green.opacity(isHovered ? 0.1 : 0.06)
        case .failed:
            return Color.red.opacity(isHovered ? 0.1 : 0.06)
        }
    }
}
