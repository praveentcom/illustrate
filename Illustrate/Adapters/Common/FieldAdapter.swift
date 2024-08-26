import Foundation
import SwiftUI

extension View {
    func limitText(_ text: Binding<String>, to characterLimit: Int) -> some View {
        self.onChange(of: text.wrappedValue) {
            text.wrappedValue = String(text.wrappedValue.prefix(characterLimit))
        }
    }
}

struct ErrorState {
    var message: String
    var isShowing: Bool
}
