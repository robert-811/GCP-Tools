    //
    //  GCPUtilities.swift
    //  Aerotas Tools
    //
    //  Created by Roberto Molina on 1/3/24.
    //

    import CoreLocation

    enum GCPMode {
        case RTK
        case NonRTK
    }

    func calculateCentroid(of coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        let sum = coordinates.reduce((latitude: 0.0, longitude: 0.0)) { (result, coordinate) in
            (latitude: result.latitude + coordinate.latitude, longitude: result.longitude + coordinate.longitude)
        }
        let count = Double(coordinates.count)
        return CLLocationCoordinate2D(latitude: sum.latitude / count, longitude: sum.longitude / count)
    }

    func calculateDistanceBetween(_ coordinate1: CLLocationCoordinate2D, _ coordinate2: CLLocationCoordinate2D) -> Double {
        let earthRadius = 6371.0 // Radius of the Earth in kilometers.
        let dLat = (coordinate2.latitude - coordinate1.latitude) * .pi / 180.0
        let dLon = (coordinate2.longitude - coordinate1.longitude) * .pi / 180.0
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(coordinate1.latitude * .pi / 180.0) * cos(coordinate2.latitude * .pi / 180.0) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c * 1000.0 // Convert to meters
    }

    func addMinimumGCPsIfNeeded(_ mainCorners: [CLLocationCoordinate2D], polygonCoordinates: [CLLocationCoordinate2D], spacing: Double) -> [CLLocationCoordinate2D] {
        var gcpCoordinates = mainCorners

        // Ensure at least 5 GCPs
        while gcpCoordinates.count < 5 {
            // Calculate an interior point
            let interiorPoint = calculateInteriorPoint(polygonCoordinates, excluding: gcpCoordinates)
            if isPointInsidePolygon(interiorPoint, polygonCoordinates) {
                gcpCoordinates.append(interiorPoint)
            }
        }

        return gcpCoordinates
    }

    func calculateInteriorPoint(_ polygonCoordinates: [CLLocationCoordinate2D], excluding excludedPoints: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        // Calculate the average of the polygon coordinates
        let averagePoint = calculateCentroid(of: polygonCoordinates)

        // Adjust the point slightly if it's one of the excluded points
        if excludedPoints.contains(where: { areCoordinatesEqual($0, averagePoint) }) {
            return CLLocationCoordinate2D(
                latitude: averagePoint.latitude + 0.0001,
                longitude: averagePoint.longitude + 0.0001
            )
        }

        return averagePoint
    }


    func findFarthestPointFromGCPs(_ polygonCoordinates: [CLLocationCoordinate2D], existingGCPs: [CLLocationCoordinate2D], corners: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        var farthestPoint = polygonCoordinates.first!
        var maxDistance = 0.0

        for point in polygonCoordinates {
            if existingGCPs.contains(where: { areCoordinatesEqual($0, point) }) || corners.contains(where: { areCoordinatesEqual($0, point) }) {
                continue // Skip this point as it's already a GCP or a corner
            }

            let minDistanceToPoint = existingGCPs.map { calculateDistanceBetween($0, point) }.min() ?? 0.0
            if minDistanceToPoint > maxDistance {
                maxDistance = minDistanceToPoint
                farthestPoint = point
            }
        }

        return farthestPoint
    }



    func areGCPsSufficient(_ gcpCoordinates: [CLLocationCoordinate2D], spacing: Double) -> Bool {
        // Check if there are enough GCPs to form a polygon
        if gcpCoordinates.count < 3 {
            return false
        }

        // Check each GCP against all others to find the nearest neighbor
        for i in 0..<gcpCoordinates.count {
            let currentGCP = gcpCoordinates[i]
            var nearestDistance = Double.infinity

            for j in 0..<gcpCoordinates.count {
                if i != j {
                    let distance = calculateDistanceBetween(currentGCP, gcpCoordinates[j])
                    nearestDistance = min(nearestDistance, distance)
                }
            }

            // If the nearest GCP is further than the allowed spacing, return false
            if nearestDistance > spacing {
                return false
            }
        }

        // All GCPs are within the allowed spacing of their nearest neighbor
        return true
    }


    func findLongestSide(in coordinates: [CLLocationCoordinate2D]) -> (CLLocationCoordinate2D, CLLocationCoordinate2D) {
        var longestDistance = 0.0
        var longestSide = (start: CLLocationCoordinate2D(), end: CLLocationCoordinate2D())

        for i in 0..<coordinates.count {
            let start = coordinates[i]
            let end = coordinates[(i + 1) % coordinates.count] // Wrap around to the first point
            let distance = calculateDistanceBetween(start, end)

            if distance > longestDistance {
                longestDistance = distance
                longestSide = (start, end)
            }
        }

        return longestSide
    }

    func fillInteriorWithGCPs(_ polygonCoordinates: [CLLocationCoordinate2D], existingGCPs: [CLLocationCoordinate2D], mode: GCPMode) -> [CLLocationCoordinate2D] {
        let spacing = (mode == .RTK) ? 1400.0 : 700.0
        var interiorGCPs = existingGCPs

        // Calculate the centroid of the polygon
        let centroid = calculateCentroid(of: polygonCoordinates)

        // Check if the centroid is significantly distant from all existing GCPs
        let isCentroidDistant = existingGCPs.allSatisfy { calculateDistanceBetween($0, centroid) > spacing / 2 }

        // If the centroid is distant, add it as a GCP
        if isCentroidDistant && isPointInsidePolygon(centroid, polygonCoordinates) {
            interiorGCPs.append(centroid)
        }

        return interiorGCPs
    }

    func calculateBoundingBox(_ coordinates: [CLLocationCoordinate2D]) -> (minX: Double, maxX: Double, minY: Double, maxY: Double) {
        let lats = coordinates.map { $0.latitude }
        let lons = coordinates.map { $0.longitude }
        return (minX: lons.min()!, maxX: lons.max()!, minY: lats.min()!, maxY: lats.max()!)
    }

    func isPointInsidePolygon(_ point: CLLocationCoordinate2D, _ polygonCoordinates: [CLLocationCoordinate2D]) -> Bool {
        // Ray-casting algorithm to check if the point is inside the polygon
        var isInside = false
        var j = polygonCoordinates.count - 1
        for i in 0..<polygonCoordinates.count {
            if (polygonCoordinates[i].latitude > point.latitude) != (polygonCoordinates[j].latitude > point.latitude),
               point.longitude < (polygonCoordinates[j].longitude - polygonCoordinates[i].longitude) * (point.latitude - polygonCoordinates[i].latitude) / (polygonCoordinates[j].latitude - polygonCoordinates[i].latitude) + polygonCoordinates[i].longitude {
                isInside.toggle()
            }
            j = i
        }
        return isInside
    }

    func isPointNearExistingGCPs(_ point: CLLocationCoordinate2D, _ existingGCPs: [CLLocationCoordinate2D], spacing: Double) -> Bool {
        for gcp in existingGCPs {
            if calculateDistanceBetween(point, gcp) <= spacing {
                return true
            }
        }
        return false
    }

    func areCoordinatesEqual(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> Bool {
        return coord1.latitude == coord2.latitude && coord1.longitude == coord2.longitude
    }

    // Reuse the calculateDistanceBetween function from earlier


    //New Logic:

    func extractKMLFromKMZ(fileURL: URL) -> String? {
        // Implementation depends on the ZIP library you use
        // Extract the KMZ file and return the KML content
        // This is a placeholder; actual implementation will depend on the ZIP library
        return nil
    }

    func identifyCorners(_ polygonCoordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        // Assuming the first four points are the corners for simplicity
        // You might need a more complex algorithm for irregular polygons
        return Array(polygonCoordinates.prefix(4))
    }

    func isLargePolygon(_ polygonCoordinates: [CLLocationCoordinate2D], spacing: Double) -> Bool {
        // Example: Check if the distance between the farthest points is greater than a threshold
        let maxDistance = polygonCoordinates.flatMap { point1 in
            polygonCoordinates.map { point2 in
                calculateDistanceBetween(point1, point2)
            }
        }.max() ?? 0.0

        return maxDistance > spacing
    }



    func identifyInteriorGCPs(_ polygonCoordinates: [CLLocationCoordinate2D], existingGCPs: [CLLocationCoordinate2D], spacing: Double) -> [CLLocationCoordinate2D] {
        // Calculate the centroid of the polygon
        let centroid = calculateCentroid(of: polygonCoordinates)
        
        // Check if the centroid is inside the polygon and not too close to existing GCPs
        if isPointInsidePolygon(centroid, polygonCoordinates) && !isPointNearExistingGCPs(centroid, existingGCPs, spacing: spacing) {
            return [centroid]
        }
        
        // Calculate the maximum number of interior GCPs based on the 1400 rule
        let maxInteriorGCPs = Int(ceil(calculatePolygonPerimeter(polygonCoordinates) / spacing / 2))
        
        var interiorGCPs = [CLLocationCoordinate2D]()
        
        // Generate additional interior GCPs evenly spaced around the centroid
        for i in 0..<maxInteriorGCPs {
            let angle = 2.0 * .pi * Double(i) / Double(maxInteriorGCPs)
            let offsetX = spacing * cos(angle)
            let offsetY = spacing * sin(angle)
            let interiorPoint = CLLocationCoordinate2D(latitude: centroid.latitude + offsetY, longitude: centroid.longitude + offsetX)
            
            // Check if the interior point is inside the polygon and not too close to existing GCPs
            if isPointInsidePolygon(interiorPoint, polygonCoordinates) && !isPointNearExistingGCPs(interiorPoint, existingGCPs, spacing: spacing) {
                interiorGCPs.append(interiorPoint)
            }
            
            // Break the loop if we cannot add more interior GCPs
            if interiorGCPs.count >= maxInteriorGCPs {
                break
            }
        }
        
        return interiorGCPs
    }

    func calculatePolygonPerimeter(_ polygonCoordinates: [CLLocationCoordinate2D]) -> Double {
        var perimeter = 0.0
        for i in 0..<polygonCoordinates.count {
            let point1 = polygonCoordinates[i]
            let point2 = polygonCoordinates[(i + 1) % polygonCoordinates.count]
            perimeter += calculateDistanceBetween(point1, point2)
        }
        return perimeter
    }

    func distributeGCPsAcrossPolygon(_ polygonCoordinates: [CLLocationCoordinate2D], mode: GCPMode) -> [CLLocationCoordinate2D] {
        let spacing = (mode == .RTK) ? 1400.0 : 700.0 // Spacing based on mode
        var gcpCoordinates = identifyCorners(polygonCoordinates)

        // Add interior GCPs
        gcpCoordinates += distributeInteriorGCPs(polygonCoordinates, existingGCPs: gcpCoordinates, spacing: spacing)

        return gcpCoordinates
    }

    func distributeInteriorGCPs(_ polygonCoordinates: [CLLocationCoordinate2D], existingGCPs: [CLLocationCoordinate2D], spacing: Double) -> [CLLocationCoordinate2D] {
        var interiorGCPs = [CLLocationCoordinate2D]()
        let gridPoints = generateGridPoints(for: polygonCoordinates, spacing: spacing)

        for point in gridPoints {
            if isPointInsidePolygon(point, polygonCoordinates) {
                if !isPointNearExistingGCPs(point, existingGCPs, spacing: spacing) {
                    interiorGCPs.append(point)
                } else {
                    print("Point near existing GCP: \(point)")
                }
            } else {
                print("Point outside polygon: \(point)")
            }
        }

        print("Total interior GCPs: \(interiorGCPs.count)")
        return interiorGCPs
    }


    func generateGridPoints(for polygonCoordinates: [CLLocationCoordinate2D], spacing: Double) -> [CLLocationCoordinate2D] {
        let boundingBox = calculateBoundingBox(polygonCoordinates)
        var gridPoints = [CLLocationCoordinate2D]()

        var x = boundingBox.minX + (spacing / 10)
        while x < boundingBox.maxX {
            var y = boundingBox.minY + (spacing / 10)
            while y < boundingBox.maxY {
                let gridPoint = CLLocationCoordinate2D(latitude: y, longitude: x)
                gridPoints.append(gridPoint)
                y += spacing / 10 // Dense grid for testing
            }
            x += spacing / 10 // Dense grid for testing
        }

        return gridPoints
    }

    func testPointInsidePolygon() {
        let testPoint = CLLocationCoordinate2D(latitude: 37.946483, longitude: -104.861785)
        let polygonCoordinates = [
            CLLocationCoordinate2D(latitude: 37.94847866121113, longitude: -104.85866697175992),
            CLLocationCoordinate2D(latitude: 37.94443328310764, longitude: -104.85866711297783),
            CLLocationCoordinate2D(latitude: 37.94443328310764, longitude: -104.86379688702218),
            CLLocationCoordinate2D(latitude: 37.94847866121113, longitude: -104.86379702824009)
        ]

        let isTestPointInside = isPointInsidePolygon(testPoint, polygonCoordinates)
        print("Is the test point inside the polygon? \(isTestPointInside)")
    }

        

    // Other existing utility functions...
