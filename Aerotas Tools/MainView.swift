//
//  MainView.swift
//  Aerotas Tools
//
//  Created by Roberto Molina on 12/29/23.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: FileSelectionView().environmentObject(CoordinatesContainer())) {
                    Text("Polyline Converter")
                }
                .buttonStyle(AerotasButtonStyle()) // Apply the AerotasButtonStyle
            }
            .navigationTitle("Main Page")
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
//test
