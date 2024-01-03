//
//  GCPPlannerView.swift
//  Aerotas Tools
//
//  Created by Roberto Molina on 1/2/24.
//

import SwiftUI
import CoreLocation
import AppKit
import UniformTypeIdentifiers

struct GCPPlannerView: View {
    @State private var selectedMode: GCPMode = .RTK
    @State private var selectedFileURL: URL?

    var body: some View {
        VStack {
            FilePicker(selectedFileURL: $selectedFileURL)

            Picker("Mode", selection: $selectedMode) {
                Text("RTK").tag(GCPMode.RTK)
                Text("Non-RTK").tag(GCPMode.NonRTK)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(maxWidth: 300) // Adjust width as needed

            Button("Generate") {
                generateProcessedFile()
            }
            .buttonStyle(AerotasButtonStyle())
            .disabled(selectedFileURL == nil)
        }
        .padding()
        .navigationTitle("GCP Planner")
    }

    func generateProcessedFile() {
        switch selectedMode {
        case .RTK:
            // Placeholder for RTK mode processing logic
            print("Processing file in RTK mode")
            // TODO: Implement RTK mode processing logic

        case .NonRTK:
            // Placeholder for Non-RTK mode processing logic
            print("Processing file in Non-RTK mode")
            // TODO: Implement Non-RTK mode processing logic
        }
    }
}

enum GCPMode: String, CaseIterable, Identifiable {
    case RTK, NonRTK
    var id: String { self.rawValue }
}

// FilePicker implementation here (as previously provided)


// Preview provider
struct GCPPlannerView_Previews: PreviewProvider {
    static var previews: some View {
        GCPPlannerView()
    }
}
