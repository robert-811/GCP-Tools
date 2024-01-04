//
//  MainView.swift
//  Aerotas Tools
//
//  Created by Roberto Molina on 12/29/23.
//

import SwiftUI

struct MainView: View {
    @State private var activeLink: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {  // Added spacing between buttons
                Text("Aerotas Tools")
                    .font(.largeTitle)
                    .padding(.top, 40)

                navigationLinkButton("Polyline Converter", destination: FileSelectionView().environmentObject(CoordinatesContainer()), tag: "PolylineConverter")
                navigationLinkButton("Polygon Creator", destination: PolygonCreatorView().environmentObject(CoordinatesContainer()), tag: "PolygonCreator")
                navigationLinkButton("GCP Planner", destination: GCPPlannerView(), tag: "GCPPlanner")
                
                Spacer()  // Pushes content to the top
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .navigationTitle("Main Page")
        }
    }

    private func navigationLinkButton<Destination: View>(_ title: String, destination: Destination, tag: String) -> some View {
        Button(title) {
            activeLink = tag
        }
        .buttonStyle(AerotasButtonStyle())
        .background(
            NavigationLink(tag: tag, selection: $activeLink, destination: { destination }, label: { EmptyView() })
            .hidden()
        )
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
