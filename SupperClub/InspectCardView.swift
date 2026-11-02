import SwiftUI

struct InspectCardView: View {
    @Bindable var model: OnboardingModel
    let recipe: Recipe
    @Binding var path: [DiscoverRoute]

    @State private var showsRarity = false

    private var isSaved: Bool { model.savedCardIDs.contains(recipe.id) }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    LiveCardView(recipe: recipe, width: 240, isDraggable: true)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)
                    DishPhotoView(recipe: recipe)
                    titleBlock
                    if !model.restrictions.isEmpty {
                        dietFit
                    }
                    people
                    stats
                    recentTrades
                }
                .padding(20)
            }
            actions
        }
        .sheet(isPresented: $showsRarity) {
            RarityDetailView(recipe: recipe)
        }
    }

    private var topBar: some View {
        HStack {
            Button { path.removeLast() } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.ink)
                    .frame(width: 44, height: 44)
                    .overlay { RoundedRectangle(cornerRadius: 13).stroke(Color.ink, lineWidth: 2) }
            }
            .accessibilityLabel("Back")
            Spacer()
            Text("Inspect Card")
                .font(.display(17))
                .foregroundStyle(Color.ink)
            Spacer()
            ShareLink(item: "Check out \(recipe.name) on Supper Club") {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.ink)
                    .frame(width: 44, height: 44)
                    .overlay { Circle().stroke(Color.ink, lineWidth: 2) }
            }
            .accessibilityLabel("Share")
        }
        .padding(.horizontal, 20)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(recipe.cuisine.lowercased()) · \(recipe.cookTimeLabel)")
                .font(.text(13))
                .foregroundStyle(Color.gray4)
            Text(recipe.name)
                .font(.display(28))
                .foregroundStyle(Color.ink)
            HStack(spacing: 8) {
                Button { showsRarity = true } label: {
                    HStack(spacing: 5) {
                        Sparkle().fill(.white).frame(width: 11, height: 11)
                        Text(recipe.tier.name)
                            .font(.display(12))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(Color.ink, in: .capsule)
                }
                .accessibilityHint("Shows what makes up this rarity")
                Text("traded \(recipe.timesTraded) times")
                    .font(.text(12))
                    .foregroundStyle(Color.ink)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .overlay { Capsule().stroke(Color.ink, lineWidth: 1.5) }
            }
        }
    }

    private var dietFit: some View {
        let conflicts = recipe.conflicts(with: model.restrictions)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if conflicts.isEmpty {
                    Sparkle().fill(Color.ink).frame(width: 16, height: 16)
                } else {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.ink, in: .circle)
                }
                Text(conflicts.isEmpty ? "Fits your diet" : "Doesn't fit your diet")
                    .font(.display(15))
            }
            if conflicts.isEmpty {
                Text("Checked against \(model.restrictions.count) restrictions.")
                    .font(.text(13))
                    .foregroundStyle(Color.gray4)
            } else {
                ForEach(conflicts, id: \.self) { conflict in
                    Text("\(conflict.restriction): \(conflict.reason)")
                        .font(.text(13))
                }
            }
        }
        .foregroundStyle(Color.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(conflicts.isEmpty ? Color.gray1 : .white, in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.ink, style: StrokeStyle(lineWidth: 2, dash: conflicts.isEmpty ? [] : [6, 4]))
        }
        .accessibilityElement(children: .combine)
    }

    private var people: some View {
        HStack(alignment: .top, spacing: 12) {
            personView(label: "created by", person: recipe.creator)
            personView(label: "current owner", person: recipe.owner)
        }
    }

    private func personView(label: String, person: CookProfile) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.text(12))
                .foregroundStyle(Color.gray4)
            HStack(spacing: 8) {
                InkGlyphView(emoji: "👩‍🍳", size: 32)
                VStack(alignment: .leading, spacing: 0) {
                    Text(person.name)
                        .font(.display(13))
                        .foregroundStyle(Color.ink)
                    Text(person.detail)
                        .font(.text(11))
                        .foregroundStyle(Color.gray4)
                }
                .accessibilityElement(children: .combine)
                FavoriteChefButton(model: model, chef: person, size: 26)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stats: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
            GridRow {
                statView("cook time", recipe.cookTimeLabel)
                statView("date created", recipe.createdLabel)
            }
            GridRow {
                statView("card rarity", recipe.tier.name)
                statView("trading frequency", recipe.tradeFrequency)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.gray1, in: .rect(cornerRadius: 20))
    }

    private func statView(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.text(12))
                .foregroundStyle(Color.gray4)
            Text(value)
                .font(.display(16))
                .foregroundStyle(Color.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var recentTrades: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent trades")
                .font(.display(16))
                .foregroundStyle(Color.ink)
            ForEach(recipe.recentTrades) { trade in
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 11, weight: .bold))
                        .accessibilityHidden(true)
                    Text("\(trade.from.shortName) to \(trade.to.shortName)")
                    Spacer()
                    Text(trade.age)
                        .foregroundStyle(Color.gray4)
                }
                .font(.text(13))
                .foregroundStyle(Color.ink)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            PrimaryButton(title: "INITIATE TRADE") {
                path.append(.offer(recipe))
            }
            Button {
                model.savedCardIDs.formSymmetricDifference([recipe.id])
            } label: {
                Image(systemName: isSaved ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSaved ? .white : Color.ink)
                    .frame(width: 56, height: 56)
                    .background(isSaved ? Color.ink : .white, in: .circle)
                    .overlay { Circle().stroke(Color.ink, lineWidth: 2) }
            }
            .accessibilityLabel(isSaved ? "Remove from saved" : "Save card")
            .sensoryFeedback(.selection, trigger: isSaved)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}
