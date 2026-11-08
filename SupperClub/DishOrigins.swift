import CoreLocation

struct DishCity: Identifiable, Hashable {
    let name: String
    let latitude: Double
    let longitude: Double

    var id: String { name }
    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}
