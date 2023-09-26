import SwiftUI

struct ContentView: View {
    @EnvironmentObject var coordinatesContainer: CoordinatesContainer

    var body: some View {
        VStack {
            FileSelectionView()
            if !coordinatesContainer.coordinates.isEmpty {
                MapView(coordinates: coordinatesContainer.coordinates)
            } else {
                Text("Map will be displayed here.")
            }
        }
    }
}


// Common styling function for SwiftUI buttons
struct styleSwiftUIButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
