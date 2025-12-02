import SwiftUI

struct OnboardingTitleView: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
    }
}

#Preview {
    OnboardingTitleView("Welcome to\nIllustrate")
        .padding()
}
