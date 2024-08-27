import Foundation
import SwiftUI

var label: Color {
    #if os(macOS)
        Color(NSColor.labelColor)
    #else
        Color(UIColor.label)
    #endif
}

var secondaryLabel: Color {
    #if os(macOS)
        Color(NSColor.secondaryLabelColor)
    #else
        Color(UIColor.secondaryLabel)
    #endif
}

var secondarySystemFill: Color {
    #if os(macOS)
        Color(NSColor.secondarySystemFill)
    #else
        Color(UIColor.secondarySystemFill)
    #endif
}

var tertiarySystemFill: Color {
    #if os(macOS)
        Color(NSColor.tertiarySystemFill)
    #else
        Color(UIColor.tertiarySystemFill)
    #endif
}

var quaternarySystemFill: Color {
    #if os(macOS)
        Color(NSColor.quaternarySystemFill)
    #else
        Color(UIColor.quaternarySystemFill)
    #endif
}
