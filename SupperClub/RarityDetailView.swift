import SwiftUI

/// Opened by tapping a card: shows the points behind its rarity and where that falls on the scale.
struct RarityDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                LiveCardView(recipe: recipe, width: 230, isDraggable: true)
                    .padding(.top, 8)
                summary
                factors
                scale
            }
            .padding(20)
        }
        .overlay(alignment: .topTrailing) {
            Button("Close", systemImage: "xmark") { dismiss() }
                .labelStyle(.iconOnly)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.brandText)
                .frame(width: 36, height: 36)
                .background(Color.gray1, in: .circle)
                .padding(16)
        }
    }

    private var summary: some View {
        VStack(spacing: 6) {
            Text(recipe.tier.name.uppercased())
                .font(.system(size: 13, weight: .bold))
                .tracking(2)
                .foregroundStyle(recipe.tier.color)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(recipe.score)")
                    .font(.system(size: 44, weight: .bold))
                Text("/ 100 rarity points")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.gray4)
            }
            .foregroundStyle(Color.brandText)
            .accessibilityElement(children: .combine)
        }
    }

    private var factors: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What makes up this rarity")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.brandText)
            ForEach(recipe.factors) { factor in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(factor.name)
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text("\(factor.points)/\(RarityFactor.maxPoints)")
                            .font(.system(size: 14, weight: .medium))
                            .monospacedDigit()
                    }
                    .foregroundStyle(Color.brandText)
                    ProgressView(value: Double(factor.points), total: Double(RarityFactor.maxPoints))
                        .tint(recipe.tier.color)
                    Text(factor.detail)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.gray4)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scale: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rarity scale")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.brandText)
            ForEach(RarityTier.allCases.reversed()) { tier in
                HStack(spacing: 10) {
                    Circle()
                        .fill(tier.color)
                        .frame(width: 10, height: 10)
                    Text(tier.name)
                        .font(.system(size: 14, weight: tier == recipe.tier ? .bold : .regular))
                    if tier.isHolographic {
                        Text("Holographic")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(tier.color)
                    }
                    Spacer()
                    Text(tier.scoreRange)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.gray4)
                }
                .foregroundStyle(Color.brandText)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(tier == recipe.tier ? tier.color.opacity(0.12) : .clear, in: .rect(cornerRadius: 8))
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
