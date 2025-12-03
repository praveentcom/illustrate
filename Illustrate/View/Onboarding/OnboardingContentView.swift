import SwiftUI

struct OnboardingContentView: View {
    let content: String

    init(_ content: String) {
        self.content = content
    }

    var body: some View {
        Text(content)
            .font(.callout)
            .opacity(0.7)
    }
}
