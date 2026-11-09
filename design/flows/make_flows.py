"""Lays out the onboarding and trading screenshots as one SVG flow board.

Drag the SVG into Figma: every screen comes in as its own named group
(frame, screenshot, title, note) and the arrows and labels stay editable.

    python3 design/flows/make_flows.py
"""
import base64
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).parent
SCREENS = HERE / "screens"
OUT = HERE / "supper-club-flows.svg"

PAPER, INK, MUTED, LINE = "#FBF7EA", "#6D3A52", "#8C7280", "#EADFD8"
ROSE, SAGE, BUTTER, BLUSH, MINT = "#DA74A3", "#B4B534", "#F2D88F", "#E9ACC8", "#C8D378"
SERIF = "'New York', Georgia, serif"
SANS = "'Avenir Next', Avenir, 'Helvetica Neue', sans-serif"

SW, SH = 414, 900          # screenshot size
GAP = 150                  # space between screens (room for arrow labels)
PAD = 120
LABEL_H = 110              # title + note above each screen

# (file, title, note, action that leads to the next screen)
ONBOARDING = [
    ("01-welcome", "Welcome / log in", "Logo, chef mascot and food bubbles", "Tap Sign Up"),
    ("02-sign-up", "Create account", "Name, username, email, password", "Sign up"),
    ("03-experience", "1 · Experience", "Pick one skill level", "Continue"),
    ("04-cuisines", "2 · Cuisines", "Alphabetical swatch tiles, pick any", "Continue"),
    ("05-diet", "3 · Diet (optional)", "Diets, allergies, religious, health", "Continue or skip"),
    ("06-location", "4 · Location", "Share location or skip", "Skip for now"),
    ("07-pack-sealed", "Starter pack", "8 cards, all fit your diet", "Swipe to tear"),
    ("08-pack-reveal", "Card reveal", "One card at a time, rarity below", "Swipe"),
    ("09-pack-epic", "Epic reveal", "Rays and glow scale with rarity", "Swipe"),
    ("10-pack-legendary", "Legendary build-up", "Heartbeat haptics before the flip", "Tap to flip"),
    ("11-pack-legendary-flip", "Legendary", "Holographic card", "Swipe to finish"),
    ("12-pack-summary", "Pack summary", "Tap any card to see its rarity", "Add to collection"),
]

TRADING = [
    ("13-discover-globe", "Discover globe", "One food pin per city", "Tap a pin"),
    ("14-city-tray", "City tray", "That city's dishes in a row", "Swipe through"),
    ("15-swipe-deck", "Swipe deck", "Left pass · right save · eye inspect", "Tap the eye"),
    ("16-inspect", "Inspect", "Card plus a real dish photo", "Scroll"),
    ("17-inspect-details", "Inspect details", "Diet fit, chefs, ingredients, trades", "Initiate trade"),
    ("18-offer-cards", "Offer cards", "Pick up to 5 of your cards", "Send trade"),
    ("19-confirm-trade", "Confirm trade", "You give / you get, side by side", "Confirm"),
    ("20-trade-sent", "Request sent", "Pending in Trading, can cancel", None),
]

BRANCH = [  # hangs under the swipe deck
    ("21-after-swipe-right", "Swipe right", "Saved to Trading toast", "View"),
    ("22-trading-interested", "Trading · Interested", "Make an offer from saved dishes", None),
]


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;")


def image_data(name):
    """Embeds each screenshot as a JPEG so the SVG stays small enough for Figma."""
    with tempfile.TemporaryDirectory() as tmp:
        jpg = Path(tmp) / "s.jpg"
        subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "82",
                        str(SCREENS / f"{name}.png"), "--out", str(jpg)],
                       check=True, capture_output=True)
        return "data:image/jpeg;base64," + base64.b64encode(jpg.read_bytes()).decode()


parts = []
add = parts.append


def text(x, y, s, size, family=SANS, weight=400, fill=INK, anchor="start", spacing=0):
    add(f'<text x="{x}" y="{y}" font-family="{family}" font-size="{size}" font-weight="{weight}" '
        f'fill="{fill}" text-anchor="{anchor}" letter-spacing="{spacing}">{esc(s)}</text>')


def screen(x, y, name, title, note, index):
    add(f'<g id="{name}">')
    text(x, y + 34, f"{index:02d}", 18, SANS, 600, ROSE, spacing=1)
    text(x + 36, y + 34, title, 26, SERIF, 600)
    text(x, y + 68, note, 17, SANS, 400, MUTED)
    top = y + LABEL_H
    add(f'<clipPath id="clip-{name}"><rect x="{x}" y="{top}" width="{SW}" height="{SH}" rx="52"/></clipPath>')
    add(f'<rect x="{x + 4}" y="{top + 10}" width="{SW}" height="{SH}" rx="52" fill="{INK}" opacity="0.10"/>')
    add(f'<image x="{x}" y="{top}" width="{SW}" height="{SH}" clip-path="url(#clip-{name})" '
        f'preserveAspectRatio="xMidYMid slice" href="{image_data(name)}"/>')
    add(f'<rect x="{x}" y="{top}" width="{SW}" height="{SH}" rx="52" fill="none" stroke="{LINE}" stroke-width="2"/>')
    add("</g>")


def arrow_right(x1, x2, y, label, color):
    add(f'<g id="arrow-{esc(label)}">')
    add(f'<path d="M{x1} {y} H{x2 - 12}" stroke="{color}" stroke-width="4" stroke-linecap="round" fill="none"/>')
    add(f'<path d="M{x2 - 18} {y - 11} L{x2} {y} L{x2 - 18} {y + 11} Z" fill="{color}"/>')
    w = len(label) * 8.6 + 26
    cx = (x1 + x2) / 2
    add(f'<rect x="{cx - w / 2}" y="{y - 64}" width="{w}" height="34" rx="17" fill="{PAPER}" stroke="{color}" stroke-width="2"/>')
    text(cx, y - 41, label, 15, SANS, 600, INK, "middle")
    add("</g>")


def section(y, title, subtitle, color, width):
    add(f'<g id="section-{esc(title)}">')
    add(f'<rect x="{PAD - 40}" y="{y}" width="{width - 2 * PAD + 80}" height="8" rx="4" fill="{color}"/>')
    text(PAD - 40, y + 70, title, 52, SERIF, 600)
    text(PAD - 40, y + 108, subtitle, 20, SANS, 400, MUTED)
    add("</g>")


def row(items, x0, y, color, start_index, last_arrow=True):
    xs = []
    for i, (name, title, note, action) in enumerate(items):
        x = x0 + i * (SW + GAP)
        xs.append(x)
        screen(x, y, name, title, note, start_index + i)
        if action and i < len(items) - 1:
            arrow_right(x + SW + 14, x + SW + GAP - 14, y + LABEL_H + SH / 2, action, color)
    return xs


cols = max(len(ONBOARDING), len(TRADING))
W = PAD * 2 + cols * SW + (cols - 1) * GAP
ROW_H = LABEL_H + SH

y = PAD
section(y, "Onboarding", "Sign up, four quick questions, then a free starter pack that fits your diet.", ROSE, W)
y += 170
row(ONBOARDING, PAD, y, ROSE, 1)

y += ROW_H + 160
section(y, "Discover & trading", "Find a dish on the globe, inspect it, offer your cards. Swiping right saves it to Trading.", SAGE, W)
y += 170
trade_xs = row(TRADING, PAD, y, SAGE, len(ONBOARDING) + 1)

# Branch: swipe right from the deck drops down to its own row.
deck_x = trade_xs[2]
branch_y = y + ROW_H + 170
bx = deck_x
bend_y = branch_y - 60
add('<g id="arrow-swipe-right">')
add(f'<path d="M{deck_x + SW / 2} {y + ROW_H + 18} V{bend_y}" stroke="{ROSE}" stroke-width="4" stroke-linecap="round" fill="none" stroke-dasharray="2 12"/>')
add(f'<path d="M{deck_x + SW / 2 - 11} {bend_y - 18} L{deck_x + SW / 2} {bend_y} L{deck_x + SW / 2 + 11} {bend_y - 18} Z" fill="{ROSE}"/>')
add(f'<rect x="{deck_x + SW / 2 + 20}" y="{y + ROW_H + 50}" width="190" height="34" rx="17" fill="{PAPER}" stroke="{ROSE}" stroke-width="2"/>')
text(deck_x + SW / 2 + 115, y + ROW_H + 73, "Swipe right (♥)", 15, SANS, 600, INK, "middle")
add("</g>")
row(BRANCH, bx, branch_y, ROSE, len(ONBOARDING) + len(TRADING) + 1)

# Both paths end in Trading: link the interested list back to Offer cards.
offer_x = trade_xs[5]
end_x = bx + (SW + GAP) + SW
mid_y = branch_y + LABEL_H + SH / 2
add('<g id="arrow-make-an-offer">')
add(f'<path d="M{end_x + 14} {mid_y} H{offer_x + SW / 2} V{y + ROW_H + 26}" stroke="{SAGE}" stroke-width="4" '
    f'stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
add(f'<path d="M{offer_x + SW / 2 - 11} {y + ROW_H + 30} L{offer_x + SW / 2} {y + ROW_H + 12} L{offer_x + SW / 2 + 11} {y + ROW_H + 30} Z" fill="{SAGE}"/>')
lx = (end_x + offer_x + SW / 2) / 2
add(f'<rect x="{lx - 70}" y="{mid_y - 54}" width="140" height="34" rx="17" fill="{PAPER}" stroke="{SAGE}" stroke-width="2"/>')
text(lx, mid_y - 31, "Make an offer", 15, SANS, 600, INK, "middle")
add("</g>")

H = branch_y + ROW_H + PAD

svg = (f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
       f'width="{W}" height="{H}" viewBox="0 0 {W} {H}">'
       f'<rect id="background" width="{W}" height="{H}" fill="{PAPER}"/>'
       + "".join(parts) + "</svg>")
OUT.write_text(svg)
print(f"{OUT} · {W}×{H} · {OUT.stat().st_size / 1e6:.1f} MB")
