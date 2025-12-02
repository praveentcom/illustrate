import SwiftUI

struct InfoTooltip: View {
    let helpText: Text

    init(helpText: Text) {
        self.helpText = helpText
    }

    var body: some View {
        Image(systemName: "info.circle")
            .foregroundColor(.secondary)
            .help(helpText)
    }
}

extension InfoTooltip {
    init(_ helpText: String) {
        self.init(helpText: Text(helpText))
    }
}
