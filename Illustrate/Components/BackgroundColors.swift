//
//  BackgroundColors.swift
//  Illustrate
//
//  Created by Praveen Thirumurugan on 19/08/24.
//

import Foundation
import SwiftUI

var tertiaryBackgroundColor: Color {
#if os(macOS)
    Color(NSColor.tertiarySystemFill)
#else
    Color(UIColor.tertiarySystemFill)
#endif
}

var quaternaryBackgroundColor: Color {
#if os(macOS)
    Color(NSColor.quaternarySystemFill)
#else
    Color(UIColor.quaternarySystemFill)
#endif
}
