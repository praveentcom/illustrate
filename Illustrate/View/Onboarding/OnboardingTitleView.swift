import SwiftUI

struct OnboardingTitleView: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
            .multilineTextAlignment(.center)
    }
}
