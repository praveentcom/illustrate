import SwiftUI

struct InfoLabel: View {
    let label: Text

    init(label: Text) {
        self.label = label
    }

    var body: some View {
        HStack {
            Image(systemName: "info.circle")
            label
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(.thinMaterial)
        .cornerRadius(8)
    }
}

extension InfoLabel {
    init(_ label: String) {
        self.init(label: Text(label))
    }
}
