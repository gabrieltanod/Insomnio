//
//  Item.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 23/02/26.
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
