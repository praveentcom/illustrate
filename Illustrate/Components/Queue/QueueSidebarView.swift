import Foundation
import SwiftUI
import SwiftData

struct QueueSidebarView: View {
    @EnvironmentObject var queueService: GenerationQueueService
    @State private var selectedQueueItem: QueueItem?
    @State private var showingResult: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Generation Queue")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 12)
                
                Spacer()
                
                Menu {
                    Button("Clear Successful") {
                        queueService.clearSuccessfulItems()
                    }
                    .disabled(queueService.queueItems.filter { $0.status == .SUCCESSFUL }.isEmpty)
                    
                    Button("Clear Failed") {
                        queueService.clearFailedItems()
                    }
                    .disabled(queueService.queueItems.filter { $0.status == .FAILED }.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .padding(.trailing)
                .padding(.top, 12)
            }
            
            Divider()
                .padding(.top, 8)
            
            // Queue List
            if queueService.queueItems.isEmpty {
                VStack {
                    Spacer()
                    
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No items in queue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(queueService.queueItems) { item in
                            QueueItemRow(item: item) {
                                if item.status == .SUCCESSFUL, let setId = item.setId {
                                    selectedQueueItem = item
                                    showingResult = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(minWidth: 280, maxWidth: 320)
        #if os(macOS)
        .background(Color(nsColor: .controlBackgroundColor))
        #else
        .background(Color(uiColor: .systemGroupedBackground))
        #endif
        .sheet(isPresented: $showingResult) {
            if let item = selectedQueueItem, let setId = item.setId {
                NavigationStack {
                    ResultView(setId: setId)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    showingResult = false
                                }
                            }
                        }
                }
            }
        }
    }
}

struct QueueItemRow: View {
    let item: QueueItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            if item.status == .SUCCESSFUL {
                onTap()
            }
        }) {
            HStack(alignment: .top, spacing: 12) {
                // Status Icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: statusIcon)
                        .font(.system(size: 16))
                        .foregroundColor(statusColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.request?.prompt ?? "Generation Request")
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if item.status == .FAILED, let error = item.errorMessage {
                        Text(error)
                            .font(.caption2)
                            .foregroundColor(.red)
                            .lineLimit(1)
                    }
                    
                    Text(timeAgo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if item.status == .SUCCESSFUL {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    #if os(macOS)
                    .fill(Color(nsColor: .textBackgroundColor))
                    #else
                    .fill(Color(uiColor: .systemBackground))
                    #endif
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(item.status != .SUCCESSFUL)
    }
    
    private var statusColor: Color {
        switch item.status {
        case .IN_PROGRESS:
            return .blue
        case .SUCCESSFUL:
            return .green
        case .FAILED:
            return .red
        }
    }
    
    private var statusIcon: String {
        switch item.status {
        case .IN_PROGRESS:
            return "clock.fill"
        case .SUCCESSFUL:
            return "checkmark.circle.fill"
        case .FAILED:
            return "xmark.circle.fill"
        }
    }
    
    private var statusText: String {
        switch item.status {
        case .IN_PROGRESS:
            return "Generating..."
        case .SUCCESSFUL:
            return "Complete - Tap to view"
        case .FAILED:
            return "Failed"
        }
    }
    
    private var timeAgo: String {
        let interval = Date().timeIntervalSince(item.updatedAt)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// Result view navigation - uses existing GenerationImageView
struct ResultView: View {
    let setId: UUID
    @Environment(\.modelContext) private var modelContext
    @Query private var imageSets: [ImageSet]
    
    var imageSet: ImageSet? {
        imageSets.first { $0.id == setId }
    }
    
    var body: some View {
        if let set = imageSet {
            if set.setType == .VIDEO_IMAGE {
                GenerationVideoView(setId: setId)
            } else {
                GenerationImageView(setId: setId)
            }
        } else {
            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("Result not found")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .frame(minWidth: 400, minHeight: 300)
            .padding()
        }
    }
}
