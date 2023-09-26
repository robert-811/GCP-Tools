
//
//  Swift File for Aerotas Mapping Tools
//  Developed by OpenAI Assistant for Roberto Alexis Molina
//
//  Copyright © 2023 Aerotas. All rights reserved.
//


//
//  parseKMLContent.swift
//  Polyline to Polygon V2
//
//  Created by Roberto Molina on 9/26/23.
//  Updated for macOS 14 and Swift 5.x
//

import CoreLocation
import Foundation

class KMLParserDelegate: NSObject, XMLParserDelegate {
    var coordinatesHandler: ([CLLocationCoordinate2D]) -> Void
    var coordinates: [CLLocationCoordinate2D] = []
    
    init(coordinatesHandler: @escaping ([CLLocationCoordinate2D]) -> Void) {
        self.coordinatesHandler = coordinatesHandler
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "coordinates" {
            coordinatesHandler(coordinates)
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let coordinateStrings = string.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        for coordinateString in coordinateStrings {
            let components = coordinateString.components(separatedBy: ",")
            if components.count >= 2, let latitude = Double(components[1]), let longitude = Double(components[0]) {
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                coordinates.append(coordinate)
            }
        }
    }
}

func parseKML(from url: URL, completion: @escaping ([CLLocationCoordinate2D]) -> Void) {
    // Initialize KMLParserDelegate with a coordinates handling closure
    let parserDelegate = KMLParserDelegate(coordinatesHandler: { coordinates in
        DispatchQueue.main.async {
            completion(coordinates)
        }
    })
    
    // Read KML content from URL (assuming it's a file URL)
    guard let kmlContent = try? String(contentsOf: url, encoding: .utf8),
          let xmlData = kmlContent.data(using: .utf8) else {
        // Handle error (e.g., invalid KML content)
        print("Failed to read or encode KML content.")
        return
    }

    // Initialize XMLParser and set its delegate
    let parser = XMLParser(data: xmlData)
    parser.delegate = parserDelegate
    
    // Start parsing
    parser.parse()
}
