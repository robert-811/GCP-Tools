//
//  GCPPlannerView.swift
//  Aerotas Tools
//
//  Created by Roberto Molina on 1/2/24.
//

import SwiftUI

struct GCPPlannerView: View {
    @State private var selectedMode: GCPMode = .RTK
    @State private var selectedFileURL: URL?

    var body: some View {
        VStack {
            // File import button
            Button("Select KML/KMZ File") {
                // Implement file selection logic
            }

            // Mode selection
            Picker("Mode", selection: $selectedMode) {
                Text("RTK").tag(GCPMode.RTK)
                // Add more modes here
            }
            .pickerStyle(SegmentedPickerStyle())

            // Generate button
            Button("Generate") {
                // Implement generation logic
            }
            .disabled(selectedFileURL == nil) // Disable if no file is selected
        }
        .padding()
        .navigationTitle("GCP Planner")
    }
}

enum GCPMode: String, CaseIterable, Identifiable {
    case RTK
    // Add more modes here

    var id: String { self.rawValue }
}
