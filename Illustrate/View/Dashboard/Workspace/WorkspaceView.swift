import SwiftData
import SwiftUI

struct WorkspaceView: View {
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading) {
                    Text("\(timeBasedGreeting), let's Illustrate ✍🏼")
                        .fontWeight(.semibold)
                    Text("What do you want to generate today?")
                }

                VStack(alignment: .leading) {
                    Text("Welcome, let's get you started.")
                        .font(.caption)
                        .textCase(.uppercase)
                        .opacity(0.5)
                    OnboardingView()
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
            .background(Color.accentColor.opacity(0.1))
            .background(tertiarySystemFill)
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkspaceConnectionShortcut: View {
    @State var isConnectionDetailsOpen: Bool = false

    var item: Connection
    var setType: EnumSetType? = nil
    var showModels: Bool

    func getModelsForConnection() -> [ConnectionModel] {
        if setType != nil {
            return connectionModels.filter { $0.connectionId == item.connectionId && $0.modelSetType == setType }
        } else {
            return connectionModels.filter { $0.connectionId == item.connectionId }
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
                    .opacity(0.6)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            } else {
                Text("\(getModelsForConnection().count) model\(getModelsForConnection().count == 1 ? "" : "s") available")
                    .multilineTextAlignment(.leading)
                    .opacity(0.6)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(minHeight: 72, maxHeight: .infinity, alignment: .topLeading)
        #if os(macOS)
            .background(Color(NSColor.secondarySystemFill))
        #else
            .background(Color(UIColor.secondarySystemFill))
        #endif
            .cornerRadius(4)
            .onTapGesture {
                DispatchQueue.main.async {
                    isConnectionDetailsOpen = true
                }
            }
            .sheet(isPresented: $isConnectionDetailsOpen) {
                ConnectionDetailsView(isPresented: $isConnectionDetailsOpen, selectedConnection: item)
            }
    }
}
