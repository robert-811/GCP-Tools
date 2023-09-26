//
//  DropView.swift
//  Aerotas Tools
//
//  Created by Roberto Molina on 9/28/23.
//  Updated for macOS 14 and Swift 5.x
//

import SwiftUI

// NSView subclass to handle drag and drop functionality
class DropView: NSView {
    
    var onDropHandler: ((URL) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.registerForDraggedTypes([.fileURL])
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.red.cgColor // Test background color
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let item = sender.draggingPasteboard.pasteboardItems?.first,
              let urlString = item.string(forType: .fileURL),
              let url = URL(string: urlString) else { return false }
        
        onDropHandler?(url)
        return true
    }
}

// SwiftUI wrapper for the DropView
struct DropViewRepresentable: NSViewRepresentable {
    typealias NSViewType = DropView
    
    var onDrop: ((URL) -> Void)?
    
    func makeNSView(context: NSViewRepresentableContext<DropViewRepresentable>) -> DropView {
        let dropView = DropView()
        dropView.onDropHandler = onDrop
        return dropView
    }
    
    func updateNSView(_ nsView: DropView, context: NSViewRepresentableContext<DropViewRepresentable>) {
        // Update logic here
    }
}
