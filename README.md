# Supper Club

An iOS app for collecting and trading recipes as cards. Recipes get passed between family, friends and partners. Supper Club treats them like trading cards: you open packs, collect dishes from around the world and trade for the ones you want.

Built in SwiftUI for iOS 26.

## How it works

**Onboarding.** You sign up, then pick your cooking experience (Beginner to Professional), the cuisines you like, any dietary restrictions, and optionally your location.

**Starter pack.** Onboarding ends with an 8-card pack built for you:

- It always includes one Legendary and one Epic card.
- The rest come from your cuisines, matched to your skill level.
- Every card fits your dietary restrictions. If too few dishes fit, the pack says so.
- Cards are revealed from lowest to highest rarity, so the rarest card comes last.

Opening the pack is the centerpiece. You tear the foil, the pack bursts open, and you flick through the cards. Rarer cards land bigger, and the holo card shakes before it flips. Haptics follow each step, from the foil tearing to a heartbeat that builds before the last reveal.

**Rarity.** Cards earn rarity from what goes into the dish, not from head-to-head rankings. Each card has four factors worth up to 25 points each:

| Factor | What it measures |
| --- | --- |
| Technique | How hard the dish is to master |
| Ingredients | How hard the ingredients are to find |
| Heritage | How closely it's tied to one place or tradition |
| Trading frequency | Fewer trades earn more points |

The total (0–100) sets the tier: Common, Uncommon, Rare, Epic or Legendary. Each tier has its own card design. Tap a card to see the points behind its score.

**Discover.** A globe with a pin on every city that has dishes. Tap a pin to fly there and see that city's recipes. You can also browse a swipe deck: swipe right to request a dish, left to pass, or tap to inspect it.

**Trading.** Dishes you swipe right on become trade requests. You offer cards from your inventory in return, shown fanned out like a hand.

**Profile.** Your inventory, dietary settings and favorite chefs.

## The catalog

788 recipes in `SupperClub/Recipes.json`, built from [TheMealDB](https://www.themealdb.com)'s free catalog by `tools/build_recipes.py`. The script:

- maps each dish to a cuisine and a home city on the globe
- tags what it contains so the dietary filters work
- estimates cook time, skill level and the rarity factors
- spreads scores so each tier has a set share of the catalog (34% Common down to 6% Legendary)

To rebuild it, from the repo root:

```bash
python3 tools/build_recipes.py
```

## Design

The `design/` folder has the design system sheet, the logo and app icon (with the explored options) and an onboarding and trading flow board. They're all SVG, so you can drop them into Figma.

## Not done yet

There's no backend yet, so:

- Sign up and sign in don't create real accounts, and "Forgot password" does nothing.
- Other cooks, card owners and trade history are sample data.
- Trade requests stay pending because nobody can answer them.
- Trading frequency is a placeholder value until real trades exist.
- Your collection isn't saved between launches.

## Running it

1. Open `SupperClub.xcodeproj` in Xcode 26 or later.
2. Pick an iPhone simulator.
3. Press Run.

There are no dependencies to install. Haptics only work on a real iPhone.
