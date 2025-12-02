//
//  InfoLabel.swift
//  Illustrate
//
//  Created by Praveen on 2025-12-02.
//

import SwiftUI

/// A reusable info icon with text label in a styled container
struct InfoLabel: View {
    let label: Text

    init(label: Text) {
        self.label = label
    }

    var body: some View {
        HStack {
            Image(systemName: "info.circle")
            label
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(.thinMaterial)
        .cornerRadius(8)
    }
}

/// Convenience initializer for string-based labels
extension InfoLabel {
    init(_ label: String) {
        self.init(label: Text(label))
    }
}
