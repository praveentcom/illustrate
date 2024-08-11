//
//  Item.swift
//  illustrate
//
//  Created by Praveen Thirumurugan on 12/08/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
