
//
//  Swift File for Aerotas Mapping Tools
//  Developed by OpenAI Assistant for Roberto Alexis Molina
//
//  Copyright © 2023 Aerotas. All rights reserved.
//

//
//  KMLUtilities.swift
//  Aerotas Tools
//
//  Created by Roberto Molina on 9/26/23.
//

import CoreLocation
import ZIPFoundation
import Foundation

func exportKML(coordinates: [CLLocationCoordinate2D]) -> String {
    // This is the logic from generateKMLContentForPolygon(coordinates:)
    var kml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
        <Placemark>
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

// KML Utility functions
func parseKML(from kmlContent: String, completion: @escaping ([CLLocationCoordinate2D]) -> Void) {
    let data = kmlContent.data(using: .utf8)!
    let parser = XMLParser(data: data)
    let delegate = KMLParserDelegate(coordinatesHandler: completion)
    parser.delegate = delegate
    parser.parse()
}
