//
//  DropButton.swift
//  Aerotas Tools
//
//  Created by Roberto Molina on 9/28/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct DropButton: View {
    var title: String
    var onClick: (() -> Void)?
    var onDrop: ((URL) -> Void)?

    var body: some View {
        ZStack {
            Color.blue
            Text(title)
                .foregroundColor(.white)
        }
        .frame(width: 200, height: 50)
        .cornerRadius(8)
        .contentShape(Rectangle())  // Makes the entire ZStack clickable
        .onTapGesture {
            onClick?()
        }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: nil) { providers, _ in
            providers.first?.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
                guard let urlData = urlData as? Data, let url = URL(dataRepresentation: urlData, relativeTo: nil) else {
                    return
                }
                onDrop?(url)
            }
            return true
        }
    }
}
