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
            .frame(maxWidth: 300)
            
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
        guard let fileURL = selectedFileURL else { return }

        parseKML(from: fileURL) { polygonCoordinates in
            let mainCorners = distributeGCPsAcrossPolygon(polygonCoordinates, mode: selectedMode)

            // Handle KMZ files
            let isKMZ = fileURL.pathExtension.lowercased() == "kmz"
            if isKMZ {
                guard let extractedKML = extractKMLFromKMZ(fileURL: fileURL) else {
                    print("Failed to extract KML from KMZ")
                    return
                }
                // Use extractedKML here if needed
            } else {
                // Read KML content from fileURL
                do {
                    let kmlContent = try String(contentsOf: fileURL)
                    // Use kmlContent here
                } catch {
                    print("Failed to read KML content: \(error.localizedDescription)")
                    return
                }
            }

            // Distribute GCPs across the polygon
            let gcpCoordinates = distributeGCPsAcrossPolygon(polygonCoordinates, mode: selectedMode)
            
            // Generate new KML content with GCPs
            let newKMLContent = generateKMLContentForGCPs(originalPolygonCoordinates: polygonCoordinates, gcpCoordinates: gcpCoordinates)
            saveKMLToFile(kmlContent: newKMLContent, originalFileURL: fileURL)
        }
    }


    
    // Include the GCPMode enum and other utility functions here
    // ...
    
    // Implement the FilePicker view
    // ...
    
    func generateKMLContentForGCPs(originalPolygonCoordinates: [CLLocationCoordinate2D], gcpCoordinates: [CLLocationCoordinate2D]) -> String {
        var kml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
        <Placemark>
        <Style>
        <LineStyle>
            <color>ff0000ff</color> <!-- Blue outline color -->
            <width>2</width>
        </LineStyle>
        <PolyStyle>
            <fill>0</fill> <!-- No fill -->
        </PolyStyle>
        </Style>
        <Polygon>
        <outerBoundaryIs>
        <LinearRing>
        <coordinates>
        """

        // Add original polygon coordinates
        for coordinate in originalPolygonCoordinates {
            kml += "\(coordinate.longitude),\(coordinate.latitude) "
        }

        kml += """
        </coordinates>
        </LinearRing>
        </outerBoundaryIs>
        </Polygon>
        </Placemark>
        """

        // Add GCP markers
        for gcp in gcpCoordinates {
            kml += """
            <Placemark>
            <Point>
            <coordinates>\(gcp.longitude),\(gcp.latitude)</coordinates>
            </Point>
            </Placemark>
            """
        }

        kml += """
        </Document>
        </kml>
        """

        return kml
    }

    
    
    func saveKMLToFile(kmlContent: String, originalFileURL: URL) {
        let originalFileName = originalFileURL.lastPathComponent
        let newFileName = "Aerotas_\(originalFileName)"
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType(filenameExtension: "kml")!]
        savePanel.nameFieldStringValue = newFileName

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try kmlContent.write(to: url, atomically: true, encoding: .utf8)
                    print("Saved KML to \(url.path)")
                } catch {
                    print("Failed to save KML: \(error.localizedDescription)")
                }
            } else {
                // Handle the case where the user cancels or dismisses the save panel
                print("Save panel dismissed")
            }
        }
    }

    
    func readKMLContent(from fileURL: URL) -> String? {
        do {
            return try String(contentsOf: fileURL)
        } catch {
            print("Error reading KML content: \(error)")
            return nil
        }
    }
    
    // Preview provider
    struct GCPPlannerView_Previews: PreviewProvider {
        static var previews: some View {
            GCPPlannerView()
        }
    }
}
