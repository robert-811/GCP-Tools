//
//  PolygonCreatorView.swift
//  Aerotas Tools
//
//  Created by Roberto Molina on 12/29/23.
//

import SwiftUI
import CoreLocation
import AppKit
import UniformTypeIdentifiers

struct PolygonCreatorView: View {
    @State private var centerCoordinateInput: String = ""
    @State private var acreageInput: String = ""
    @EnvironmentObject var coordinatesContainer: CoordinatesContainer
    
    var body: some View {
        VStack {
            TextField("Enter Center Coordinates (lat, long)", text: $centerCoordinateInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Enter Acreage", text: $acreageInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Create Polygon", action: createPolygon)
                .buttonStyle(AerotasButtonStyle())
        }
        .padding()
        .navigationTitle("Polygon Creator")
    }
    
    // Add your new functions here
    
    func parseInput() -> (CLLocationCoordinate2D?, Double?) {
        // Remove the degree symbol if present and split by space
        let coordinateComponents = centerCoordinateInput
            .replacingOccurrences(of: "°", with: "")
            .split { $0 == " " || $0 == "," }
            .map(String.init)
        
        guard coordinateComponents.count == 2,
              let latitude = Double(coordinateComponents[0]),
              let longitude = Double(coordinateComponents[1]),
              let acreage = Double(acreageInput) else {
            return (nil, nil)
        }
        
        let centerCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        return (centerCoordinate, acreage)
    }
    
    func calculateSquarePolygonCoordinates(center: CLLocationCoordinate2D, acreage: Double) -> [CLLocationCoordinate2D] {
        let metersPerAcre = 4046.86
        let totalArea = metersPerAcre * acreage
        let sideLength = sqrt(totalArea)
        
        // Approximate - this will be less accurate the further from the equator you get
        let degreesPerMeterLatitude = 1 / 111320.0
        let degreesPerMeterLongitude = 1 / (111320.0 * cos(center.latitude * .pi / 180))
        
        let halfSide = sideLength / 2
        let deltaLat = degreesPerMeterLatitude * halfSide
        let deltaLong = degreesPerMeterLongitude * halfSide
        
        return [
            CLLocationCoordinate2D(latitude: center.latitude + deltaLat, longitude: center.longitude + deltaLong),
            CLLocationCoordinate2D(latitude: center.latitude + deltaLat, longitude: center.longitude - deltaLong),
            CLLocationCoordinate2D(latitude: center.latitude - deltaLat, longitude: center.longitude - deltaLong),
            CLLocationCoordinate2D(latitude: center.latitude - deltaLat, longitude: center.longitude + deltaLong),
            CLLocationCoordinate2D(latitude: center.latitude + deltaLat, longitude: center.longitude + deltaLong) // Close the loop
        ]
    }
    
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
    
    func saveKMLToFile(kmlContent: String, acreage: Double) {
        let fileName = "\(Int(acreage))Acres_Square.kml"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            try kmlContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Saved KML to \(fileURL.path)")
        } catch {
            print("Failed to save KML: \(error.localizedDescription)")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func createPolygon() {
        let input = parseInput()
        
        guard let centerCoordinate = input.0, let acreage = input.1 else {
            print("Invalid input")
            return
        }
        
        let polygonCoordinates = calculateSquarePolygonCoordinates(center: centerCoordinate, acreage: acreage)
        let kmlContent = generateKMLContentForPolygon(coordinates: polygonCoordinates)
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType(filenameExtension: "kml")!]
        savePanel.nameFieldStringValue = "\(Int(acreage))Acres_Square.kml"
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try kmlContent.write(to: url, atomically: true, encoding: .utf8)
                    print("Saved KML to \(url.path)")
                } catch {
                    print("Failed to save KML: \(error.localizedDescription)")
                }
            }
        }
    }
}
    
    struct PolygonCreatorView_Previews: PreviewProvider {
        static var previews: some View {
            PolygonCreatorView().environmentObject(CoordinatesContainer())
        }
    }
