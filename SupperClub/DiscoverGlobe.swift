import MapKit
import SwiftUI

/// The first thing on Discover: a globe with one pin on every city that has dishes.
/// Tapping a pin flies to the city and opens a tray with all of its recipes.
struct DiscoverGlobe: View {
    let recipes: [Recipe]
    let onInspect: (Recipe) -> Void
    let onSwipe: (DishCity?) -> Void

    private static let globeDistance: CLLocationDistance = 34_000_000
    /// Close enough to see the city's neighbors, so nearby pins stay tappable.
    private static let cityDistance: CLLocationDistance = 5_000_000
    /// Below this, every pin shows its city's name.
    private static let labelDistance: CLLocationDistance = 6_000_000

    @State private var position: MapCameraPosition = .camera(
        MapCamera(centerCoordinate: DiscoverGlobe.startCenter, distance: DiscoverGlobe.globeDistance)
    )
    @State private var distance = DiscoverGlobe.globeDistance
    @State private var center = DiscoverGlobe.startCenter
    @State private var selectedCity: DishCity?
    /// Annotations added before the map has settled are never drawn, so they wait for this.
    @State private var isMapReady = false

    /// Starts over the cook when they shared their location, otherwise over Asia where most dishes are.
    private static var startCenter: CLLocationCoordinate2D {
        CLLocationManager().location?.coordinate ?? CLLocationCoordinate2D(latitude: 25, longitude: 90)
    }

    private var groups: [(city: DishCity, recipes: [Recipe])] {
        Dictionary(grouping: recipes, by: \.city)
            .map { (city: $0.key, recipes: $0.value.sorted { $0.score > $1.score }) }
            .sorted { $0.city.name < $1.city.name }
    }

    private var selectedRecipes: [Recipe] {
        groups.first { $0.city == selectedCity }?.recipes ?? []
    }

    var body: some View {
        Map(position: $position) {
            UserAnnotation()
            if isMapReady {
                ForEach(groups, id: \.city) { group in
                    Annotation(group.city.name, coordinate: group.city.coordinate, anchor: .bottom) {
                        Button { select(group.city) } label: {
                            CityPin(
                                city: group.city,
                                emoji: group.recipes.first?.emoji ?? "🍲",
                                count: group.recipes.count,
                                isSelected: group.city == selectedCity,
                                showsName: distance < Self.labelDistance || group.city == selectedCity
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .mapStyle(.hybrid(elevation: .realistic, pointsOfInterest: .excludingAll))
        .onMapCameraChange(frequency: .continuous) { context in
            distance = context.camera.distance
            center = context.camera.centerCoordinate
        }
        .task {
            try? await Task.sleep(for: .seconds(0.6))
            isMapReady = true
            // A small spin once the pins exist makes MapKit draw them; a static camera leaves them hidden.
            try? await Task.sleep(for: .seconds(0.2))
            withAnimation(.easeInOut(duration: 1.4)) {
                position = .camera(MapCamera(
                    centerCoordinate: CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude + 12),
                    distance: Self.globeDistance * 0.96
                ))
            }
        }
        .onChange(of: recipes) {
            // A filter can empty the open city, so close its tray rather than show nothing.
            if selectedRecipes.isEmpty { selectedCity = nil }
        }
        .clipShape(.rect(cornerRadius: 28))
        .overlay { RoundedRectangle(cornerRadius: 28).stroke(Color.ink, lineWidth: 2.5) }
        // Leaves the Maps logo and legal link at the bottom corner visible.
        .overlay(alignment: .bottom) {
            Group {
                if let selectedCity {
                    cityTray(selectedCity)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    swipeAllButton
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 34)
        }
        .animation(.spring(duration: 0.4, bounce: 0.2), value: selectedCity)
        .sensoryFeedback(.selection, trigger: selectedCity)
    }

    // MARK: Bottom

    private var swipeAllButton: some View {
        Button { onSwipe(nil) } label: {
            HStack(spacing: 8) {
                Sparkle().fill(.white).frame(width: 13, height: 13)
                Text("Swipe through all \(recipes.count) dishes")
                    .font(.display(15))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color.ink, in: .capsule)
            .overlay { Capsule().stroke(.white, lineWidth: 2) }
        }
        .accessibilityHint("Or tap a pin to see one city's dishes")
    }

    /// Every recipe from one city, opened from its pin.
    private func cityTray(_ city: DishCity) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(city.name)
                        .font(.display(18))
                    Text(selectedRecipes.count == 1 ? "1 dish from here" : "\(selectedRecipes.count) dishes from here")
                        .font(.text(12))
                        .foregroundStyle(Color.gray4)
                }
                Spacer()
                Button { flyToGlobe() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 34, height: 34)
                        .overlay { Circle().stroke(Color.ink, lineWidth: 2) }
                }
                .accessibilityLabel("Close \(city.name)")
            }
            .foregroundStyle(Color.ink)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(selectedRecipes) { recipe in
                        Button { onInspect(recipe) } label: {
                            RecipeCardView(recipe: recipe, width: 92)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(recipe.name), \(recipe.tier.name)")
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)

            Button { onSwipe(city) } label: {
                HStack(spacing: 8) {
                    Sparkle().fill(.white).frame(width: 12, height: 12)
                    Text("Swipe through \(city.name)'s dishes")
                        .font(.display(14))
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.ink, in: .capsule)
            }
        }
        .padding(14)
        .background(Color.paper, in: .rect(cornerRadius: 22))
        .overlay { RoundedRectangle(cornerRadius: 22).stroke(Color.ink, lineWidth: 2.5) }
    }

    // MARK: Camera

    private func select(_ city: DishCity) {
        selectedCity = city
        withAnimation(.easeInOut(duration: 1.4)) {
            // Aim a little south of the city so its pin sits above the tray.
            position = .camera(MapCamera(
                centerCoordinate: CLLocationCoordinate2D(latitude: city.latitude - 4, longitude: city.longitude),
                distance: Self.cityDistance
            ))
        }
    }

    private func flyToGlobe() {
        selectedCity = nil
        withAnimation(.easeInOut(duration: 1.4)) {
            position = .camera(MapCamera(centerCoordinate: center, distance: Self.globeDistance))
        }
    }
}

/// The city's signature dish as a little ink icon, with a count badge and, up close, the city's name.
private struct CityPin: View {
    let city: DishCity
    let emoji: String
    let count: Int
    let isSelected: Bool
    let showsName: Bool

    var body: some View {
        VStack(spacing: 3) {
            // From far away the icons shrink so neighboring cities don't pile up.
            let size: CGFloat = isSelected ? 50 : (showsName ? 40 : 20)
            InkGlyphView(emoji: emoji, size: size * 0.78)
                .frame(width: size, height: size)
                .background(.white, in: .circle)
                .overlay { Circle().stroke(Color.ink, lineWidth: isSelected ? 3 : 2) }
                .overlay(alignment: .topTrailing) {
                    if showsName {
                        Text("\(count)")
                            .font(.display(10))
                            .foregroundStyle(.white)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Color.ink, in: .circle)
                            .overlay { Circle().stroke(.white, lineWidth: 1.5) }
                            .offset(x: 5, y: -5)
                    }
                }
                .frame(width: max(size, 30), height: max(size, 30))
                .contentShape(.rect)
            if showsName {
                Text(city.name)
                    .font(.display(10))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .frame(height: 18)
                    .background(Color.ink.opacity(0.85), in: .capsule)
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.4), value: isSelected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(city.name), \(count) dishes")
        .accessibilityHint("Shows this city's recipes")
    }
}
