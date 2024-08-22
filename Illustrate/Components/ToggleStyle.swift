import SwiftUI
import Foundation

struct IllustrateToggleStyle: ToggleStyle {    
    func makeBody(configuration: Configuration) -> some View {
#if os(macOS)
        CheckboxToggleStyle().makeBody(configuration: configuration)
#else
        DefaultToggleStyle().makeBody(configuration: configuration)
#endif
    }
}
