import SwiftUI

struct OnboardingSubtitleView: View {
    let subtitle: String

    init(_ subtitle: String) {
        self.subtitle = subtitle
    }

    var body: some View {
        Text(subtitle)
            .font(.callout)
            .fontWeight(.medium)
    }
}
