import SwiftUI

struct OnboardingSubtitleView: View {
    let subtitle: String

    init(_ subtitle: String) {
        self.subtitle = subtitle
    }

    var body: some View {
        Text(subtitle)
            .font(.title2)
            .fontWeight(.semibold)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
    }
}

#Preview {
    VStack {
        OnboardingTitleView("Welcome")
        OnboardingSubtitleView("Generative AI Sandbox")
    }
    .padding()
}