//
//  Swift File for Aerotas Mapping Tools
//  Developed by OpenAI Assistant for Roberto Alexis Molina
//
//  Copyright © 2023 Aerotas. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var coordinatesContainer: CoordinatesContainer

    var body: some View {
        VStack {
            FileSelectionView()
            if !coordinatesContainer.coordinates.isEmpty {
                MapView(coordinates: coordinatesContainer.coordinates)
            }
        }
    }
}
