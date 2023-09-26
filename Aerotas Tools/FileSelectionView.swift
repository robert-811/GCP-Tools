
//
//  Swift File for Aerotas Mapping Tools
//  Developed by OpenAI Assistant for Roberto Alexis Molina
//
//  Copyright © 2023 Aerotas. All rights reserved.
//

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

struct FileSelectionView: View {
    @EnvironmentObject var coordinatesContainer: CoordinatesContainer

    // Declare the originalFileURL variable
    @State private var originalFileURL: URL?

    var body: some View {
        VStack(spacing: 20) {
            VStack {
                DropButton(title: "Select KML/KMZ File", onClick: {
                    openFile()
                }, onDrop: { url in
                    processFile(url: url)
                })
                .frame(width: 200, height: 50)

                Button("Convert to Polygon") {
                    exportKMLFile()
                }
                .buttonStyle(AerotasButtonStyle())
                .frame(minWidth: 0, maxWidth: 200, minHeight: 50)
            }
            
            Spacer().frame(height: 20)
            
            if !coordinatesContainer.coordinates.isEmpty {
                MapView(coordinates: coordinatesContainer.coordinates)
                    .edgesIgnoringSafeArea(.all)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                PlaceholderMapView()
                    .frame(maxHeight: .infinity)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        
        // Set the default filename
        if let originalFileName = originalFileURL?.lastPathComponent {
            let newFileName = "Updated_\(originalFileName)"
            savePanel.nameFieldStringValue = newFileName
        }
        
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
        // Store the original file URL
        self.originalFileURL = url
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
            DispatchQueue.main.async {
                self.coordinatesContainer.coordinates = coordinates
            }
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



// Common styling function for NSButtons
func styleNSButton(button: NSButton) {
    button.bezelStyle = .rounded
    button.title = "NSButton Title"
    button.font = NSFont.systemFont(ofSize: 15)
    // Add more styling attributes as needed
}
