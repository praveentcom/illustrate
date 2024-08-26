import SwiftUI
import OnboardingUI

struct WelcomeView: View {
    var action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
    
    var body: some View {
        OnboardingSheetView {
            OnboardingTitle("Welcome to\nIllustrate")
        } content: {
            OnboardingItem(systemName: "sparkles", primary: .accentColor) {
                OnboardingSubtitle("Generative AI Sandbox")
                OnboardingContent("Generate, enhance and edit images with your secure private sandbox. All data calls are processed on-device.")
            }
            
            OnboardingItem(systemName: "lock.icloud", primary: .accentColor) {
                OnboardingSubtitle("Synced to your iCloud")
                OnboardingContent("The images you generate are synced privately in your iCloud account and can be accessed across your devices.")
            }
            
            OnboardingItem(systemName: "hand.raised", primary: .accentColor) {
                OnboardingSubtitle("Transparent about privacy")
                OnboardingContent("We don't collect any of the data from this application, be it for analytics or data processing. This is forever, period.")
            }
        } link: {
            Link("Read more on privacy...", destination: URL(string: "https://illustrate.so/docs/privacy-policy")!)
                .foregroundStyle(Color.accentColor)
        } button: {
            ContinueButton(color: .accentColor, action: action)
        }
    }
}
