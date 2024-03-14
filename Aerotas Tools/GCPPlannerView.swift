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

        // Assuming parseKML(from:completion:) is a function that parses KML and returns polygon coordinates
        parseKML(from: fileURL) { polygonCoordinates in
            // Assuming distributeGCPsAcrossPolygon is now replaced or integrated with new logic
            let gcpCoordinates = GCPPlacementLogic.calculatePerimeterGCPs(for: polygonCoordinates)
            // Future implementation: integrate interior GCP placement here
            
            // Generate new KML content with GCPs
            let newKMLContent = generateKMLContentForGCPs(originalPolygonCoordinates: polygonCoordinates, gcpCoordinates: gcpCoordinates)
            saveKMLToFile(kmlContent: newKMLContent, originalFileURL: fileURL)
        }
    }

    func generateKMLContentForGCPs(originalPolygonCoordinates: [CLLocationCoordinate2D], gcpCoordinates: [CLLocationCoordinate2D]) -> String {
        var kml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
        <name>GCP Plan</name>
        <Style id="gcpStyle">
            <IconStyle>
                <Icon>
                    <href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href>
                </Icon>
            </IconStyle>
        </Style>
        <Placemark>
            <name>Polygon Area</name>
            <styleUrl>#polygonStyle</styleUrl>
            <Polygon>
                <outerBoundaryIs>
                    <LinearRing>
                        <coordinates>
        """
        
        // Add original polygon coordinates
        for coordinate in originalPolygonCoordinates {
            kml += "\(coordinate.longitude),\(coordinate.latitude),0 "
        }
        
        kml += """
                        </coordinates>
                    </LinearRing>
                </outerBoundaryIs>
            </Polygon>
        </Placemark>
        """
        
        // Add GCP markers
        for (index, gcp) in gcpCoordinates.enumerated() {
            kml += """
                <Placemark>
                    <name>GCP \(index + 1)</name>
                    <styleUrl>#gcpStyle</styleUrl>
                    <Point>
                        <coordinates>\(gcp.longitude),\(gcp.latitude),0</coordinates>
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
