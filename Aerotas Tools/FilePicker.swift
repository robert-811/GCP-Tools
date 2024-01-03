//
//  FilePicker.swift
//  Aerotas Tools
//
//  Created by Roberto Molina on 1/2/24.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct FilePicker: View {
    @Binding var selectedFileURL: URL?

    var body: some View {
        Button("Select File") {
            let openPanel = NSOpenPanel()
            openPanel.prompt = "Select File"
            openPanel.allowsMultipleSelection = false
            openPanel.canChooseDirectories = false
            openPanel.allowedContentTypes = [UTType(filenameExtension: "kml")!, UTType(filenameExtension: "kmz")!]

            if openPanel.runModal() == .OK {
                self.selectedFileURL = openPanel.url
            }
        }
    }
}
