import SwiftData
import SwiftUI

struct WorkspaceView: View {
    @Environment(\.modelContext) private var modelContext

    var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good morning"
        } else if hour < 18 {
            return "Good afternoon"
        } else {
            return "Good evening"
        }
    }

    let columns: [GridItem] = {
        #if os(macOS)
            return Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
        #else
            return Array(repeating: GridItem(.flexible(), spacing: 12), count: UIDevice.current.userInterfaceIdiom == .pad ? 4 : 1)
        #endif
    }()

    private var connectionKeysCount: Int {
        let descriptor = FetchDescriptor<ConnectionKey>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        return count
    }

    private var generationsCount: Int {
        let descriptor = FetchDescriptor<Generation>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        return count
    }

    private var shouldShowOnboarding: Bool {
        return connectionKeysCount == 0 || generationsCount == 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading) {
                    Text("\(timeBasedGreeting), let's Illustrate ✍🏼")
                        .fontWeight(.semibold)
                    Text("What do you want to generate today?")
                }

                if shouldShowOnboarding {
                    VStack(alignment: .leading) {
                        Text("Welcome, let's get you started.")
                            .font(.caption)
                            .textCase(.uppercase)
                            .opacity(0.5)
                        OnboardingView()
                    }
                }

                VStack(alignment: .leading) {
                    Text("Image Generation")
                        .font(.caption)
                        .textCase(.uppercase)
                        .opacity(0.5)
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(sectionItems(section: EnumNavigationSection.ImageGenerations), id: \.self) { item in
                            WorkspaceGenerateShortcut(item: item)
                        }
                    }
                }

                VStack(alignment: .leading) {
                    Text("Video Generation")
                        .font(.caption)
                        .textCase(.uppercase)
                        .opacity(0.5)
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(sectionItems(section: EnumNavigationSection.VideoGenerations), id: \.self) { item in
                            WorkspaceGenerateShortcut(item: item)
                        }
                    }
                }

                VStack(alignment: .leading) {
                    Text("Supported Connections and Models")
                        .font(.caption)
                        .textCase(.uppercase)
                        .opacity(0.5)
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(connections, id: \.self) { item in
                            WorkspaceConnectionShortcut(
                                item: item,
                                setType: nil,
                                showModels: false
                            )
                        }
                    }
                }
            }
            .padding(.all, 16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .navigationTitle("Illustrate")
    }
}

struct WorkspaceGenerateShortcut: View {
    var item: EnumNavigationItem
    @State private var isHovered: Bool = false

    var body: some View {
        NavigationLink(value: item) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: iconForItem(item))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text(labelForItem(item))
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                Text(subLabelForItem(item))
                    .multilineTextAlignment(.leading)
                    .opacity(0.8)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(minHeight: 72, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.accentColor.opacity(isHovered ? 0.2 : 0.1))
            .background(tertiarySystemFill)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

struct WorkspaceConnectionShortcut: View {
    @Query private var connectionKeys: [ConnectionKey]
    @State var isConnectionDetailsOpen: Bool = false
    @State private var isHovered: Bool = false

    var item: Connection
    var setType: EnumSetType? = nil
    var showModels: Bool

    var isConnected: Bool {
        connectionKeys.contains { $0.connectionId == item.connectionId }
    }

    func getModelsForConnection() -> [ConnectionModel] {
        if setType != nil {
            return ConnectionService.shared.models(for: setType!).filter { $0.connectionId == item.connectionId }
        } else {
            return ConnectionService.shared.models(for: item.connectionId)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image("\(item.connectionCode)_square".lowercased())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text(item.connectionName)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            if showModels {
                Text("\(getModelsForConnection().map { $0.modelName }.joined(separator: ", "))")
                    .multilineTextAlignment(.leading)
                    .opacity(0.7)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            } else {
                Text("\(getModelsForConnection().count) variation\(getModelsForConnection().count == 1 ? "" : "s") available")
                    .multilineTextAlignment(.leading)
                    .opacity(0.7)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(minHeight: 72, maxHeight: .infinity, alignment: .topLeading)
        .background(
            Color.mint.opacity(
                isConnected ? (isHovered ? 0.2 : 0.1) : (isHovered ? 0.1 : 0)
            )
        )
        .background(tertiarySystemFill)
        .cornerRadius(8)
        .onTapGesture {
            DispatchQueue.main.async {
                isConnectionDetailsOpen = true
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .sheet(isPresented: $isConnectionDetailsOpen) {
            ConnectionDetailsView(isPresented: $isConnectionDetailsOpen, selectedConnection: item)
        }
    }
}
