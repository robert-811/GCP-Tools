
//
//  parseKMLContent.swift
//  Polyline to Polygon V2
//
//  Created by Roberto Molina on 9/26/23.
//  Updated for macOS 14 and Swift 5.x
//

import CoreLocation
import Foundation

func parseKML(from url: URL, completion: @escaping ([CLLocationCoordinate2D]) -> Void) {
    // Initialize KMLParserDelegate with a coordinates handling closure
    let parserDelegate = KMLParserDelegate(coordinatesHandler: completion)
    
    // Read KML content from URL (assuming it's a file URL)
    guard let kmlContent = try? String(contentsOf: url, encoding: .utf8),
          let xmlData = kmlContent.data(using: .utf8) else {
        // Handle error (e.g., invalid KML content)
        return
    }

    // Initialize XMLParser and set its delegate
    let parser = XMLParser(data: xmlData)
    parser.delegate = parserDelegate
    
    // Start parsing
    parser.parse()
}
