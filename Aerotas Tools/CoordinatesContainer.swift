
//
//  Swift File for Aerotas Mapping Tools
//  Developed by OpenAI Assistant for Roberto Alexis Molina
//
//  Copyright © 2023 Aerotas. All rights reserved.
//

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
