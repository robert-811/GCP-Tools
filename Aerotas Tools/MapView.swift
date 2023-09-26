
//
//  MapView.swift
//  Aerotas Mapping Tools
//
//  Created and Updated by OpenAI Assistant for Roberto Alexis Molina
//  Copyright © 2023 Aerotas. All rights reserved.
//

import SwiftUI
import MapKit

struct MapView: NSViewRepresentable {
    var coordinates: [CLLocationCoordinate2D]  // Placeholder for demonstration

    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateNSView(_ nsView: MKMapView, context: Context) {
        // Remove all existing overlays
        nsView.removeOverlays(nsView.overlays)
        
        DispatchQueue.main.async {
            // Add the new polygon overlay
            let polygon = MKPolygon(coordinates: self.coordinates, count: self.coordinates.count)
            nsView.addOverlay(polygon)
            
            // Calculate the bounding box
            let boundingMapRect = polygon.boundingMapRect
            nsView.setVisibleMapRect(boundingMapRect, edgePadding: NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), animated: true)
        }
    }


    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MKPolygon {
                let renderer = MKPolygonRenderer(overlay: overlay)
                renderer.fillColor = NSColor.blue.withAlphaComponent(0.5)
                renderer.strokeColor = NSColor.blue
                renderer.lineWidth = 1
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
