
//
//  AerotasToolsApp.swift
//  Aerotas Tools
//
//  Created by Roberto Molina on 9/26/23.
//  Updated for macOS 14 and Swift 5.x
//

import SwiftUI

@main
struct AerotasToolsApp: App {
    @StateObject var coordinatesContainer = CoordinatesContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinatesContainer)
        }
    }
}
