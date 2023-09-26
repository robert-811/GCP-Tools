//
//  CoordinatesContainer.swift
//  Aerotas Tools
//
//  Created by Roberto Molina on 9/26/23.
//

import CoreLocation
import Combine

class CoordinatesContainer: ObservableObject {
    @Published var coordinates: [CLLocationCoordinate2D] = []
}
