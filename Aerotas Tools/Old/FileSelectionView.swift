//
//  FileSelectionView.swift
//  Polyline to Polygon V2
//
//  Created by Roberto Molina on 9/26/23.
//  Updated for macOS 14 and Swift 5.x
//

import SwiftUI
import CoreLocation
import ZIPFoundation
import UniformTypeIdentifiers

struct AerotasButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 2)
            )
            .padding([.leading, .trailing], 10)
    }
}

struct PlaceholderMapView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 2)
                .background(Color.gray.opacity(0.1))
            
            VStack {
                Image(systemName: "mappin.circle.fill") // SF Symbols Icon
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
                    .foregroundColor(Color.gray)
                Text("Map will be displayed here.")
                    .foregroundColor(Color.gray)
            }
        }
    }
}

struct FileSelectionView: View {
    @EnvironmentObject var coordinatesContainer: CoordinatesContainer

    var body: some View {
        VStack(spacing: 20) {
            DropButton(title: "Select KML/KMZ File", onClick: {
                openFile()
            }, onDrop: { url in
                processFile(url: url)
            })
            .buttonStyle(AerotasButtonStyle()) // Apply the custom style here
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50) // Adjust the frame properties

            Button("Convert to Polygon") {
                exportKMLFile()
            }
            .buttonStyle(AerotasButtonStyle()) // Apply the custom style here
            .frame(minHeight: 50) // Ensuring at least a minimum height

            Spacer().frame(height: 20)

            if !coordinatesContainer.coordinates.isEmpty {
                MapView(coordinates: coordinatesContainer.coordinates)
                    .edgesIgnoringSafeArea(.all)
            } else {
                PlaceholderMapView()
                    .frame(maxHeight: .infinity) // Allow it to take as much space as available
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensuring the VStack takes up all available space
    }
    
    // MARK: - File Handling
    
    func openFile() {
        let openFileDialog = NSOpenPanel()
        openFileDialog.allowedContentTypes = [UTType(filenameExtension: "kml")!, UTType(filenameExtension: "kmz")!]
        
        openFileDialog.begin { response in
            if response == .OK {
                if let url = openFileDialog.urls.first {
                    processFile(url: url)
                }
            }
        }
    }
    
    func exportKMLFile() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType(filenameExtension: "kml")!]
        
        savePanel.begin { response in
            if response == .OK {
                if let saveURL = savePanel.url {
                    let kmlContent = generateKMLContentForPolygon(coordinates: coordinatesContainer.coordinates)
                    do {
                        try kmlContent.write(to: saveURL, atomically: true, encoding: .utf8)
                    } catch {
                        print("Error saving KML file: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func processFile(url: URL) {
        if url.pathExtension == "kmz" {
            if let kmlContent = extractKMLFromKMZ(url: url) {
                parseKMLContent(kmlContent)
            } else {
                print("Extraction or parsing failed.")
            }
        } else if url.pathExtension == "kml" {
            do {
                let kmlContent = try String(contentsOf: url, encoding: .utf8)
                parseKMLContent(kmlContent)
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - KML Parsing & Generation
    
    func generateKMLContentForPolygon(coordinates: [CLLocationCoordinate2D]) -> String {
        var kml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <kml xmlns="http://www.opengis.net/kml/2.2">
            <Document>
            <Placemark>
            <Style>
            <LineStyle>
            <color>ff0000ff</color> <!-- Blue outline color -->
            <width>2</width> <!-- Adjust the line width as needed -->
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
        
        for coordinate in coordinates {
            kml += "\(coordinate.longitude),\(coordinate.latitude) "
        }
        
        kml += """
            </coordinates>
            </LinearRing>
            </outerBoundaryIs>
            </Polygon>
            </Placemark>
            </Document>
            </kml>
            """
        
        return kml
    }
    
    func parseKMLContent(_ kmlContent: String) {
        if let coordinates = extractCoordinatesFromKML(kmlContent) {
            self.coordinatesContainer.coordinates = coordinates
        } else {
            print("Failed to convert KML content to data.")
        }
    }
    
    func extractKMLFromKMZ(url: URL) -> String? {
        do {
            // Create a temporary directory for extracting files
            let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
            
            // Unzip the KMZ file using ZIPFoundation
            try FileManager.default.unzipItem(at: url, to: tempDirectory)
            
            // Find the first KML file in the directory
            let kmlFiles = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil).filter { $0.pathExtension == "kml" }
            
            if let kmlFile = kmlFiles.first {
                // Read and return the KML content
                let kmlContent = try String(contentsOf: kmlFile, encoding: .utf8)
                
                // Clean up the temporary directory
                try FileManager.default.removeItem(at: tempDirectory)
                
                return kmlContent
            } else {
                // Handle the case where no KML file is found in the KMZ archive
                
                // Clean up the temporary directory
                try FileManager.default.removeItem(at: tempDirectory)
                
                return nil
            }
        }
        catch {
            // Handle any errors during extraction or file operations
            print("Error extracting KMZ: \(error.localizedDescription)")
            return nil
        }
    }
    
    func extractCoordinatesFromKML(_ kmlContent: String) -> [CLLocationCoordinate2D]? {
        do {
            let xmlDoc = try XMLDocument(xmlString: kmlContent, options: [])
            
            // Find all coordinates in the KML document
            let placemarkElements = try xmlDoc.nodes(forXPath: "//coordinates")
            
            var coordinates: [CLLocationCoordinate2D] = []
            
            for placemarkElement in placemarkElements {
                if let coordinatesString = placemarkElement.stringValue {
                    // Split the coordinates by whitespace and newline characters
                    let coordinateStrings = coordinatesString.components(separatedBy: CharacterSet.whitespacesAndNewlines)
                    for coordinateString in coordinateStrings {
                        // Split each coordinate string by commas to get latitude and longitude
                        let components = coordinateString.components(separatedBy: ",")
                        if components.count >= 2,
                           let latitude = Double(components[1]),
                           let longitude = Double(components[0]) {
                            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            coordinates.append(coordinate)
                        }
                    }
                }
            }
            
            if !coordinates.isEmpty {
                return coordinates
            } else {
                return nil
            }
        } catch {
            print("Error parsing KML content: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Drag & Drop Support

struct DropView: NSViewRepresentable {
    var onDrop: ((URL) -> Void)
    var onClick: (() -> Void)?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.registerForDraggedTypes([.fileURL])
        let tap = NSClickGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap))
        view.addGestureRecognizer(tap)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSDraggingDestination {
        var parent: DropView

        init(_ parent: DropView) {
            self.parent = parent
        }

        @objc func handleTap(gesture: NSClickGestureRecognizer) {
            parent.onClick?()
        }

        func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
            print("Dragging Entered") // Diagnostic print
            return .copy
        }

        func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
            guard let item = sender.draggingPasteboard.pasteboardItems?.first,
                  let urlString = item.string(forType: .fileURL),
                  let url = URL(string: urlString) else { return false }

            print("File Dropped: \(url)") // Diagnostic print
            parent.onDrop(url)
            return true
        }
    }
}

struct DropButton: NSViewRepresentable {
    var title: String
    var onClick: (() -> Void)?
    var onDrop: ((URL) -> Void)?

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton()
        button.title = title
        button.bezelStyle = .rounded // Apply the rounded style here
        button.contentTintColor = NSColor.white // Set text color to white
        button.target = context.coordinator
        button.action = #selector(context.coordinator.handleTap)
        button.registerForDraggedTypes([.fileURL])
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        nsView.title = title // Update the button title if it changes
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: DropButton

        init(_ parent: DropButton) {
            self.parent = parent
        }

        @objc func handleTap() {
            parent.onClick?()
        }
    }
}


// Common styling function for NSButtons
func styleNSButton(button: NSButton) {
    button.bezelStyle = .rounded
    button.title = "NSButton Title"
    button.font = NSFont.systemFont(ofSize: 15)
    // Add more styling attributes as needed
}
