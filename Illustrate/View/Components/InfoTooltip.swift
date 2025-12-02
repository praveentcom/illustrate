//
//  InfoTooltip.swift
//  Illustrate
//
//  Created by Praveen on 2025-12-02.
//

import SwiftUI

/// A reusable info icon with tooltip for displaying help text
struct InfoTooltip: View {
    let helpText: Text

    init(helpText: Text) {
        self.helpText = helpText
    }

    var body: some View {
        Image(systemName: "info.circle")
            .foregroundColor(.secondary)
            .help(helpText)
    }
}

/// Convenience initializer for string-based help text
extension InfoTooltip {
    init(_ helpText: String) {
        self.init(helpText: Text(helpText))
    }
}
