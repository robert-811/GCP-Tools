//
//  DragButton.swift
//  Aerotas Tools
//
//  Created by Roberto Molina on 9/27/23.
//

import SwiftUI
import Foundation

class DragButton: NSButton {
    
    var onDropHandler: ((URL) -> Void)?
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func performDragOperation(_ draggingInfo: NSDraggingInfo) -> Bool {
        guard let item = draggingInfo.draggingPasteboard.pasteboardItems?.first,
              let urlString = item.string(forType: .fileURL),
              let url = URL(string: urlString) else { return false }
        
        onDropHandler?(url)
        return true
    }
}
