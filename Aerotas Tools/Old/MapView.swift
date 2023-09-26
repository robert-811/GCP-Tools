import SwiftUI
import MapKit

struct MapView: NSViewRepresentable {
    var coordinates: [CLLocationCoordinate2D]
    
    // Coordinator for handling MKMapViewDelegate methods
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Create MKMapView
    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    // Update MKMapView
    func updateNSView(_ nsView: MKMapView, context: Context) {
        updateOverlay(from: nsView)
    }

    // Update the map overlay
    private func updateOverlay(from mapView: MKMapView) {
        mapView.removeOverlays(mapView.overlays)
        let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polygon)
    }
    
    // MARK: - Coordinator Class
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
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
