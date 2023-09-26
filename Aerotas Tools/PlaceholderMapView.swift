//
//  PlaceholderMapView.swift
//  Aerotas Tools
//
//  Created by Roberto Molina on 9/28/23.
//

import SwiftUI

struct PlaceholderMapView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 2)
                .background(Color.gray.opacity(0.1))
            
            VStack {
                Image(systemName: "mappin.circle.fill") // SF Symbols Icon
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
                    .foregroundColor(Color.gray)
                Text("Map will be displayed here.")
                    .foregroundColor(Color.gray)
            }
        }
    }
}
