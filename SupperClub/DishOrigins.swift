import CoreLocation

struct DishCity: Identifiable, Hashable {
    let name: String
    let latitude: Double
    let longitude: Double

    var id: String { name }
    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}

private let cities: [String: DishCity] = Dictionary(uniqueKeysWithValues: [
    DishCity(name: "Beijing", latitude: 39.90, longitude: 116.40),
    DishCity(name: "Shanghai", latitude: 31.23, longitude: 121.47),
    DishCity(name: "Chengdu", latitude: 30.57, longitude: 104.07),
    DishCity(name: "Lanzhou", latitude: 36.06, longitude: 103.83),
    DishCity(name: "Kunming", latitude: 25.04, longitude: 102.71),
    DishCity(name: "Fuzhou", latitude: 26.07, longitude: 119.30),
    DishCity(name: "Paris", latitude: 48.86, longitude: 2.35),
    DishCity(name: "Marseille", latitude: 43.30, longitude: 5.37),
    DishCity(name: "Lyon", latitude: 45.76, longitude: 4.84),
    DishCity(name: "Athens", latitude: 37.98, longitude: 23.73),
    DishCity(name: "Chios", latitude: 38.37, longitude: 26.14),
    DishCity(name: "Delhi", latitude: 28.61, longitude: 77.21),
    DishCity(name: "Hyderabad", latitude: 17.39, longitude: 78.49),
    DishCity(name: "Lucknow", latitude: 26.85, longitude: 80.95),
    DishCity(name: "Srinagar", latitude: 34.08, longitude: 74.80),
    DishCity(name: "Rome", latitude: 41.90, longitude: 12.50),
    DishCity(name: "Milan", latitude: 45.46, longitude: 9.19),
    DishCity(name: "Naples", latitude: 40.85, longitude: 14.27),
    DishCity(name: "Bari", latitude: 41.12, longitude: 16.87),
    DishCity(name: "Parma", latitude: 44.80, longitude: 10.33),
    DishCity(name: "Tokyo", latitude: 35.68, longitude: 139.69),
    DishCity(name: "Kyoto", latitude: 35.01, longitude: 135.77),
    DishCity(name: "Fukuoka", latitude: 33.59, longitude: 130.40),
    DishCity(name: "Seoul", latitude: 37.57, longitude: 126.98),
    DishCity(name: "Mexico City", latitude: 19.43, longitude: -99.13),
    DishCity(name: "Oaxaca", latitude: 17.07, longitude: -96.73),
    DishCity(name: "Mérida", latitude: 20.97, longitude: -89.62),
    DishCity(name: "Puebla", latitude: 19.04, longitude: -98.21),
    DishCity(name: "Bangkok", latitude: 13.76, longitude: 100.50),
    DishCity(name: "Chiang Mai", latitude: 18.79, longitude: 98.98),
    DishCity(name: "Songkhla", latitude: 7.19, longitude: 100.60),
    DishCity(name: "Hanoi", latitude: 21.03, longitude: 105.85),
    DishCity(name: "Hội An", latitude: 15.88, longitude: 108.33),
    DishCity(name: "Huế", latitude: 16.46, longitude: 107.59),
    DishCity(name: "Ho Chi Minh City", latitude: 10.82, longitude: 106.63),
].map { ($0.name, $0) })

/// Where each dish comes from, or is best known for.
private let dishHomes: [String: String] = [
    "Egg Fried Rice": "Shanghai", "Scallion Pancakes": "Shanghai", "Mapo Tofu": "Chengdu",
    "Yunnan Wild Mushroom Hot Pot": "Kunming", "Xiao Long Bao": "Shanghai",
    "Buddha Jumps Over the Wall": "Fuzhou", "Peking Duck": "Beijing", "Hand-Pulled Lanzhou Noodles": "Lanzhou",

    "Croque Monsieur": "Paris", "Ratatouille": "Marseille", "Coq au Vin": "Lyon",
    "Black Truffle Scrambled Eggs": "Paris", "Butter Croissants": "Paris",
    "Bouillabaisse de Marseille": "Marseille", "Grand Marnier Soufflé": "Paris", "Canard à la Presse": "Paris",

    "Horiatiki Salad": "Athens", "Tzatziki with Pita": "Athens", "Spanakopita": "Athens",
    "Chios Mastic Rice Pudding": "Chios", "Moussaka": "Athens", "Lamb Kleftiko": "Athens",
    "Galaktoboureko": "Athens", "Kokoretsi": "Athens",

    "Dal Tadka": "Delhi", "Jeera Aloo": "Delhi", "Chana Masala": "Delhi", "Kashmiri Morel Pulao": "Srinagar",
    "Butter Chicken": "Delhi", "Hyderabadi Dum Biryani": "Hyderabad", "Malai Kofta": "Lucknow",
    "Galouti Kebab": "Lucknow",

    "Spaghetti Aglio e Olio": "Naples", "Tomato Bruschetta": "Rome", "Risotto alla Milanese": "Milan",
    "Wild Mushroom & Truffle Risotto": "Milan", "Hand-Rolled Orecchiette": "Bari",
    "Culatello Tortellini in Brodo": "Parma", "Osso Buco": "Milan", "Sfogliatella": "Naples",

    "Tamago Kake Gohan": "Tokyo", "Miso Soup": "Tokyo", "Chicken Katsu Curry": "Tokyo",
    "Matsutake Gohan": "Kyoto", "Tonkotsu Ramen": "Fukuoka", "Wagyu Sukiyaki": "Tokyo",
    "Edomae Nigiri": "Tokyo", "Hand-Cut Juwari Soba": "Tokyo",

    "Kimchi Fried Rice": "Seoul", "Gyeran-jjim": "Seoul", "Bibimbap": "Seoul",
    "Temple Doenjang Jjigae": "Seoul", "Yangnyeom Fried Chicken": "Seoul", "Royal Court Sinseollo": "Seoul",
    "Homemade Baechu Kimchi": "Seoul", "Gujeolpan": "Seoul",

    "Guacamole": "Mexico City", "Cheese Quesadillas": "Mexico City", "Chicken Fajitas": "Mexico City",
    "Huitlacoche Quesadillas": "Mexico City", "Pork Tamales": "Mexico City", "Mole Negro Oaxaqueño": "Oaxaca",
    "Cochinita Pibil": "Mérida", "Chiles en Nogada": "Puebla",

    "Pad Krapow": "Bangkok", "Kai Jeow Omelette": "Bangkok", "Pad Thai": "Bangkok",
    "Khao Yam Rice Salad": "Songkhla", "Massaman Curry": "Songkhla", "Gaeng Tai Pla": "Songkhla",
    "Khao Soi": "Chiang Mai", "Chor Muang Dumplings": "Bangkok",

    "Gỏi Cuốn": "Ho Chi Minh City", "Bánh Mì": "Ho Chi Minh City", "Bún Chả": "Hanoi",
    "Cao Lầu of Hội An": "Hội An", "Phở Bò": "Hanoi", "Chả Cá Lã Vọng": "Hanoi",
    "Bánh Xèo": "Ho Chi Minh City", "Bánh Bèo of Huế": "Huế",
]

/// Dishes in the same city sit in a small spiral around it, so they spread out once you zoom in.
private let dishCoordinates: [String: CLLocationCoordinate2D] = {
    var result: [String: CLLocationCoordinate2D] = [:]
    let byCity = Dictionary(grouping: recipeCatalog, by: \.city.name)
    for (_, dishes) in byCity {
        for (index, dish) in dishes.sorted(by: { $0.score < $1.score }).enumerated() {
            let angle = Double(index) * 2.4
            let radius = 0.03 + 0.012 * Double(index)
            let center = dish.city.coordinate
            result[dish.name] = CLLocationCoordinate2D(
                latitude: center.latitude + radius * sin(angle),
                longitude: center.longitude + radius * cos(angle) / cos(center.latitude * .pi / 180)
            )
        }
    }
    return result
}()

extension Recipe {
    var city: DishCity {
        cities[dishHomes[name] ?? ""] ?? DishCity(name: cuisine, latitude: 0, longitude: 0)
    }

    var mapCoordinate: CLLocationCoordinate2D { dishCoordinates[name] ?? city.coordinate }
}
