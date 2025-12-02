import Foundation
import SwiftUI

struct MobileView: View {
    @StateObject private var navigationManager = NavigationManager()
    @EnvironmentObject var queueService: GenerationQueueService
    @State private var homeNavigationPath = NavigationPath()
    @State private var generationsNavigationPath = NavigationPath()
    @State private var historyNavigationPath = NavigationPath()
    @State private var settingsNavigationPath = NavigationPath()
    @State private var showQueueSheet: Bool = false

    var body: some View {
        TabView {
            NavigationStack(path: $homeNavigationPath) {
                WorkspaceView()
                    .navigationDestination(for: EnumNavigationItem.self) { item in
                        viewForItem(item)
                    }
            }
            .tabItem {
                Label("Workspace", systemImage: "house")
            }

            NavigationStack(path: $generationsNavigationPath) {
                GenerateView()
                    .navigationDestination(for: EnumNavigationItem.self) { item in
                        viewForItem(item)
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showQueueSheet = true
                            }) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "list.bullet.clipboard")
                                    if !queueService.queueItems.isEmpty {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 4, y: -4)
                                    }
                                }
                            }
                        }
                    }
            }
            .tabItem {
                Label("Generate", systemImage: "paintbrush")
            }

            NavigationStack(path: $historyNavigationPath) {
                HistoryView()
                    .navigationDestination(for: EnumNavigationItem.self) { item in
                        viewForItem(item)
                    }
            }
            .tabItem {
                Label("History", systemImage: "photo.on.rectangle.angled")
            }

            NavigationStack(path: $settingsNavigationPath) {
                SettingsView()
                    .navigationDestination(for: EnumNavigationItem.self) { item in
                        viewForItem(item)
                    }
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .environmentObject(navigationManager)
        .sheet(isPresented: $showQueueSheet) {
            NavigationStack {
                MobileQueueView()
                    .navigationTitle("Queue")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showQueueSheet = false
                            }
                        }
                    }
            }
        }
    }
}

struct MobileQueueView: View {
    @EnvironmentObject var queueService: GenerationQueueService
    
    var body: some View {
        if queueService.queueItems.isEmpty {
            VStack {
                Spacer()
                
                Image(systemName: "tray")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                
                Text("No items in queue")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.top, 16)
                
                Spacer()
            }
        } else {
            List {
                ForEach(queueService.queueItems) { item in
                    MobileQueueItemRow(item: item)
                }
            }
        }
    }
}

struct MobileQueueItemRow: View {
    let item: QueueItem
    @State private var showingResult: Bool = false
    
    var body: some View {
        Button(action: {
            if item.status == .SUCCESSFUL, item.setId != nil {
                showingResult = true
            }
        }) {
            HStack(spacing: 12) {
                // Status Icon
                Image(systemName: statusIcon)
                    .font(.system(size: 24))
                    .foregroundColor(statusColor)
                    .frame(width: 40)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.request?.prompt ?? "Generation Request")
                        .font(.body)
                        .lineLimit(2)
                    
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if item.status == .FAILED, let error = item.errorMessage {
                        Text(error)
                            .font(.caption2)
                            .foregroundColor(.red)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if item.status == .SUCCESSFUL {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .disabled(item.status != .SUCCESSFUL)
        .sheet(isPresented: $showingResult) {
            if let setId = item.setId {
                NavigationStack {
                    ResultView(setId: setId)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Close") {
                                    showingResult = false
                                }
                            }
                        }
                }
            }
        }
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
}
