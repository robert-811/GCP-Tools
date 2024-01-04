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
import MapKit

struct PolygonCreatorView: View {
    @State private var centerCoordinateInput: String = ""
    @State private var acreageInput: String = ""
    @State private var polygonCoordinates: [CLLocationCoordinate2D] = []
    @State private var mapRegion: MKCoordinateRegion?

    let defaultCoordinate = CLLocationCoordinate2D(latitude: 36.723910, longitude: -116.977501)
    init() {
        _mapRegion = State(initialValue: MKCoordinateRegion(
            center: defaultCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1) // Adjust the span as needed
        ))
    }

    var body: some View {
        VStack {
            TextField("Enter Center Coordinates (lat, long)", text: $centerCoordinateInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: centerCoordinateInput) { _ in
                    updatePolygonCoordinates()
                }
            
            TextField("Enter Acreage", text: $acreageInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            MapView(coordinates: polygonCoordinates, region: $mapRegion)
                .frame(height: 300)

            Button("Create Polygon", action: createPolygon)
                .buttonStyle(AerotasButtonStyle())
        }
        .padding()
        .navigationTitle("Polygon Creator")
        .onChange(of: acreageInput) { _ in
            updatePolygonCoordinates()
        }
    }

    func updatePolygonCoordinates() {
        let centerCoordinate: CLLocationCoordinate2D
        if let parsedCoordinate = parseCenterCoordinate() {
            centerCoordinate = parsedCoordinate
        } else {
            centerCoordinate = defaultCoordinate
        }

        guard let acreage = Double(acreageInput), acreage > 0 else {
            polygonCoordinates = []
            return
        }

        polygonCoordinates = calculateSquarePolygonCoordinates(center: centerCoordinate, acreage: acreage)
        updateMapRegion(centerCoordinate: centerCoordinate, acreage: acreage)
    }

    func parseCenterCoordinate() -> CLLocationCoordinate2D? {
        let coordinateComponents = centerCoordinateInput
            .replacingOccurrences(of: "°", with: "")
            .split { $0 == " " || $0 == "," }
            .map(String.init)
        
        guard coordinateComponents.count == 2,
              let latitude = Double(coordinateComponents[0]),
              let longitude = Double(coordinateComponents[1]) else {
            return nil
        }
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func calculateSquarePolygonCoordinates(center: CLLocationCoordinate2D, acreage: Double) -> [CLLocationCoordinate2D] {

        let sideLength = sqrt(acreage * 4046.86) // Convert acreage to square meters
        let distanceToCorner = sideLength / sqrt(2) // Distance from center to a corner
        
        // Bearings for the four corners: NE, SE, SW, NW
        let bearings = [45, 135, 225, 315].map { $0 * Double.pi / 180 }
        
        var coordinates = bearings.map { bearing in
            destinationPoint(from: center, distance: distanceToCorner, bearing: bearing)
        }
        
        // Ensure the polygon is closed by repeating the first coordinate at the end
        if let firstCoordinate = coordinates.first {
            coordinates.append(firstCoordinate)
        }
        
        return coordinates
    }
    
    func updateMapRegion(centerCoordinate: CLLocationCoordinate2D, acreage: Double) {
        let areaInSquareMeters = acreage * 4046.86 // Convert acres to square meters
        let sideLength = sqrt(areaInSquareMeters) // Calculate the side length of the square

        let latitudeDelta = sideLength / 111320 // 1 degree latitude is approximately 111.32 km
        let longitudeDelta = sideLength / (111320 * cos(centerCoordinate.latitude * .pi / 180))

        mapRegion = MKCoordinateRegion(center: centerCoordinate, span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
    }
    
    func parseInput() -> (CLLocationCoordinate2D, Double?) {
        let defaultCoordinate = CLLocationCoordinate2D(latitude: 36.723910, longitude: -116.977501)
        let coordinateComponents = centerCoordinateInput
            .replacingOccurrences(of: "°", with: "")
            .split { $0 == " " || $0 == "," }
            .map(String.init)
        let centerCoordinate: CLLocationCoordinate2D
        if coordinateComponents.count == 2,
           let latitude = Double(coordinateComponents[0]),
           let longitude = Double(coordinateComponents[1]) {
            centerCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        } else {
            centerCoordinate = defaultCoordinate
        }
        
        let acreage = Double(acreageInput)
        return (centerCoordinate, acreage)
    }
    
    func createPolygon() {
        let input = parseInput()
        let centerCoordinate = input.0  // centerCoordinate is always non-optional
        
        guard let acreage = input.1 else {
            print("Invalid acreage input")
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

    func destinationPoint(from start: CLLocationCoordinate2D, distance: Double, bearing: Double) -> CLLocationCoordinate2D {
        let radius: Double = 6371e3 // Earth's radius in meters
        let angularDistance = distance / radius
        
        let radLat = start.latitude * Double.pi / 180
        let radLon = start.longitude * Double.pi / 180
        
        let destLat = asin(sin(radLat) * cos(angularDistance) +
                           cos(radLat) * sin(angularDistance) * cos(bearing))
        let destLon = radLon + atan2(sin(bearing) * sin(angularDistance) * cos(radLat),
                                     cos(angularDistance) - sin(radLat) * sin(destLat))
        
        return CLLocationCoordinate2D(latitude: destLat * 180 / Double.pi, longitude: destLon * 180 / Double.pi)
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
    

    
    struct PolygonCreatorView_Previews: PreviewProvider {
        static var previews: some View {
            PolygonCreatorView().environmentObject(CoordinatesContainer())
        }
    }
}
