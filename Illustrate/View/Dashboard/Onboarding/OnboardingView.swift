import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    var connectionKeysCount: Int {
        let descriptor = FetchDescriptor<ConnectionKey>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0

        return count
    }

    var generationsCount: Int {
        let descriptor = FetchDescriptor<Generation>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0

        return count
    }

    struct OnboardingChecklist {
        let icon: String
        let label: String
        let subLabel: String
        let isCompleted: Bool
        let item: EnumNavigationItem
    }

    func checklist() -> [OnboardingChecklist] {
        [
            OnboardingChecklist(
                icon: "1.circle",
                label: "Connect Models",
                subLabel: "Securely connect to leading AI models",
                isCompleted: connectionKeysCount > 0,
                item: .settingsConnections
            ),
            OnboardingChecklist(
                icon: "2.circle",
                label: "Generate Images",
                subLabel: "Go ahead and generate your first image",
                isCompleted: generationsCount > 0,
                item: .generateGenerate
            ),
        ]
    }

    let columns: [GridItem] = {
        #if os(macOS)
            return Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        #else
            return Array(repeating: GridItem(.flexible(), spacing: 12), count: UIDevice.current.userInterfaceIdiom == .pad ? 3 : 1)
        #endif
    }()

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(checklist(), id: \.item) { checklistItem in
                OnboardingChecklistItem(checklistItem: checklistItem)
            }
        }
    }
}

struct OnboardingChecklistItem: View {
    var checklistItem: OnboardingView.OnboardingChecklist
    @State private var isHovered: Bool = false

    var body: some View {
        NavigationLink(value: checklistItem.item) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: checklistItem.isCompleted ? "checkmark.circle" : checklistItem.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                VStack {
                    Text("\(checklistItem.label) →")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    Text(checklistItem.subLabel)
                        .multilineTextAlignment(.leading)
                        .opacity(0.8)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(minHeight: 72, maxHeight: .infinity, alignment: .topLeading)
            .background(
                Color.mint.opacity(
                    checklistItem.isCompleted ? (isHovered ? 0.2 : 0.1) : (isHovered ? 0.1 : 0)
                )
            )
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
