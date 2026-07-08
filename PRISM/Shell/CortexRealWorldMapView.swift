import MapKit
import SwiftUI

/// Live MapKit globe for WORLD tab — CORTEX Public parity.
struct CortexRealWorldMapView: View {
    var accent: Color = Color(red: 0.0, green: 0.83, blue: 1.0)
    var positive: Color = Color(red: 0.24, green: 0.88, blue: 0.54)

    @State private var position: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 20, longitude: -20),
            distance: 28_000_000,
            heading: 0,
            pitch: 0
        )
    )

    private var hubs: [(String, CLLocationCoordinate2D, Color)] {
        [
            ("TUCSON", CLLocationCoordinate2D(latitude: 32.22, longitude: -110.97), accent),
            ("LONDON", CLLocationCoordinate2D(latitude: 51.51, longitude: -0.13), positive),
            ("TOKYO", CLLocationCoordinate2D(latitude: 35.68, longitude: 139.69), Color(red: 0.35, green: 0.78, blue: 0.98)),
            ("SYDNEY", CLLocationCoordinate2D(latitude: -33.87, longitude: 151.21), Color.orange),
        ]
    }

    var body: some View {
        Map(position: $position, interactionModes: [.pan, .zoom, .rotate]) {
            ForEach(Array(hubs.enumerated()), id: \.offset) { _, hub in
                Annotation(hub.0, coordinate: hub.1) {
                    ZStack {
                        Circle()
                            .fill(hub.2.opacity(0.25))
                            .frame(width: 22, height: 22)
                        Circle()
                            .fill(hub.2)
                            .frame(width: 7, height: 7)
                            .shadow(color: hub.2.opacity(0.8), radius: 4)
                    }
                }
            }
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .mapControlVisibility(.hidden)
    }
}
