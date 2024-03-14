import Foundation
import CoreLocation

struct GCPPlacementLogic {
    static let maxDistanceMeters: Double = 426.72 // 1400 feet in meters

    // Haversine Formula Implementation
    static func haversineDistance(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> Double {
        let radius: Double = 6371000 // Earth's radius in meters
        let dLat = (coord2.latitude - coord1.latitude).degreesToRadians
        let dLon = (coord2.longitude - coord1.longitude).degreesToRadians
        let a = sin(dLat/2) * sin(dLat/2) + cos(coord1.latitude.degreesToRadians) * cos(coord2.latitude.degreesToRadians) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return radius * c
    }

    // Calculate GCPs along the perimeter of the polygon
    static func calculatePerimeterGCPs(for polygon: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        var gcpCoordinates = [CLLocationCoordinate2D]()
        for i in 0..<polygon.count {
            let start = polygon[i]
            let end = polygon[(i + 1) % polygon.count]
            gcpCoordinates.append(start)
            
            var currentPoint = start
            while haversineDistance(from: currentPoint, to: end) > maxDistanceMeters {
                currentPoint = intermediatePoint(from: currentPoint, to: end, atDistance: maxDistanceMeters)
                gcpCoordinates.append(currentPoint)
            }
        }
        return gcpCoordinates
    }

    // Calculate an intermediate point between two points given a distance
    static func intermediatePoint(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, atDistance distance: Double) -> CLLocationCoordinate2D {
        let totalDistance = haversineDistance(from: start, to: end)
        let fraction = distance / totalDistance
        
        let lat1 = start.latitude.degreesToRadians
        let lon1 = start.longitude.degreesToRadians
        let lat2 = end.latitude.degreesToRadians
        let lon2 = end.longitude.degreesToRadians
        
        let a = sin((1 - fraction) * totalDistance) / sin(totalDistance)
        let b = sin(fraction * totalDistance) / sin(totalDistance)
        let x = a * cos(lat1) * cos(lon1) + b * cos(lat2) * cos(lon2)
        let y = a * cos(lat1) * sin(lon1) + b * cos(lat2) * sin(lon2)
        let z = a * sin(lat1) + b * sin(lat2)
        
        let newLat = atan2(z, sqrt(x * x + y * y))
        let newLon = atan2(y, x)
        
        return CLLocationCoordinate2D(latitude: newLat.radiansToDegrees, longitude: newLon.radiansToDegrees)
    }

    // Placeholder for interior GCP calculation - to be implemented based on specific requirements
    static func fillInteriorWithGCPs(for polygon: [CLLocationCoordinate2D], existingGCPs: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        // Implement logic to fill the interior with GCPs, ensuring each is within 1400 feet of another
        return []
    }
}

extension Double {
    var degreesToRadians: Double { return self * .pi / 180 }
    var radiansToDegrees: Double { return self * 180 / .pi }
}
