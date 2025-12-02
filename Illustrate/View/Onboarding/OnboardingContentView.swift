import SwiftUI

struct OnboardingContentView: View {
    let content: String

    init(_ content: String) {
        self.content = content
    }

    var body: some View {
        Text(content)
            .font(.body)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .opacity(0.8)
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingTitleView("Welcome")
        OnboardingSubtitleView("Generative AI Sandbox")
        OnboardingContentView("Generate, enhance and edit images with your secure private sandbox. All data calls are processed on-device.")
    }
    .padding()
}