import OnboardingUI
import SwiftUI

struct WelcomeView: View {
    var action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        OnboardingSheetView {
            OnboardingTitleView("Welcome to\nIllustrate")
        } content: {
            OnboardingItem(systemName: "sparkles", primary: .accentColor) {
                OnboardingSubtitleView("Generative AI Sandbox")
                OnboardingContentView("Generate, enhance and edit images with your secure private sandbox. All data calls are processed on-device.")
            }

            OnboardingItem(systemName: "lock.icloud", primary: .accentColor) {
                OnboardingSubtitleView("Synced to your iCloud")
                OnboardingContentView("The images you generate are synced privately in your iCloud account and can be accessed across your devices.")
            }

            OnboardingItem(systemName: "hand.raised", primary: .accentColor) {
                OnboardingSubtitleView("Transparent about privacy")
                OnboardingContentView("We don't collect any of the data from this application, be it for analytics or data processing. This is forever, period.")
            }
        } link: {
            Link("Read more on privacy...", destination: URL(string: "https://illustrate.help/privacy")!)
                .foregroundStyle(Color.accentColor)
        } button: {
            ContinueButton(color: .accentColor, action: action)
        }
    }
}
