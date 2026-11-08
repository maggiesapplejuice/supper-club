#!/usr/bin/env python3
"""Builds SupperClub/Recipes.json from TheMealDB's free catalog.

Run from the repo root:  python3 tools/build_recipes.py
It downloads every meal, works out each one's cuisine and home city, tags what it
contains for the dietary filters, and estimates cook time, skill and rarity.
"""

import collections
import hashlib
import json
import re
import string
import urllib.request
from pathlib import Path

API = "https://www.themealdb.com/api/json/v1/1"
OUT = Path(__file__).resolve().parent.parent / "SupperClub" / "Recipes.json"


def fetch(path):
    with urllib.request.urlopen(f"{API}/{path}", timeout=20) as response:
        return json.load(response)


def download_meals():
    meals = {}
    for letter in string.ascii_lowercase + string.digits:
        for meal in fetch(f"search.php?f={letter}").get("meals") or []:
            meals[meal["idMeal"]] = meal
    return list(meals.values())


# MARK: Cuisine and city

# TheMealDB's own area names, normalized to the adjective the app shows.
AREA_NAMES = {
    "United States": "American", "France": "French", "Norway": "Norwegian", "India": "Indian",
    "Netherlands": "Dutch", "Argentina": "Argentine", "Venezuela": "Venezuelan", "Slovakia": "Slovak",
    "Motswana": "Botswanan", "Bosnian, Herzegovinian": "Bosnian", "Antiguan, Barbudan": "Antiguan",
}

# Meals TheMealDB lists without an area. Its IDs arrive in per-country batches, which settles most of these.
MISSING_AREAS = {
    "53483": "Brazilian", "53527": "Colombian", "53575": "American", "53568": "American", "53439": "Aruban",
    "53392": "Dutch", "53406": "Albanian", "53522": "Colombian", "53396": "Afghan", "53496": "Cambodian",
    "53559": "Dominican", "53548": "Cuban", "53440": "Aruban", "53441": "Aruban", "53469": "Botswanan",
    "53453": "Bangladeshi", "53580": "Indian", "53482": "Brazilian", "53546": "Cuban", "53536": "Costa Rican",
    "53401": "Afghan", "53438": "Aruban", "53533": "Colombian", "53458": "Barbadian", "53562": "Dominican",
    "53544": "Cuban", "53428": "Angolan", "53576": "American", "53564": "Dominican", "53508": "Bahamian",
    "53442": "Aruban", "53459": "Barbadian", "53531": "Colombian", "53455": "French", "53565": "Indian",
    "53549": "American", "53542": "Costa Rican", "53462": "American", "53555": "Danish", "53446": "Austrian",
    "53524": "Colombian", "53477": "Brazilian", "53561": "Dominican", "53505": "Bahamian", "53512": "Bahamian",
    "53431": "Angolan", "53490": "Bulgarian", "53480": "Bolivian", "53532": "Colombian", "53569": "Dominican",
    "53530": "French", "53419": "Cambodian", "53411": "Albanian", "53563": "Dominican", "53571": "Dominican",
    "53543": "Cuban", "53486": "Bulgarian", "53518": "Chilean", "53557": "American", "53399": "Afghan",
    "53464": "Belgian", "53413": "Albanian", "53572": "Dominican", "53509": "Bahamian", "53465": "Belgian",
    "53541": "Costa Rican", "53578": "Estonian", "53478": "Brazilian", "53450": "American", "53397": "Afghan",
    "53579": "Estonian", "53436": "Armenian", "53398": "Afghan", "53445": "Austrian", "53494": "Bulgarian",
    "53434": "Antiguan", "53408": "Albanian", "53414": "Albanian", "53412": "Albanian", "53407": "Albanian",
    "53570": "Dominican", "53519": "Chilean", "53467": "Belgian", "53461": "Barbadian", "53504": "Bahamian",
    "53433": "Antiguan", "53538": "Costa Rican", "53515": "Chilean", "53400": "Afghan", "53423": "Cambodian",
    "53560": "Dominican", "53403": "Afghan", "53500": "Cambodian", "53422": "Cambodian", "53554": "Danish",
    "53487": "Bulgarian", "53417": "Andorran", "53537": "Costa Rican", "53534": "Colombian", "53573": "Thai",
    "53429": "Angolan", "53520": "Chilean", "53471": "Botswanan", "53539": "Costa Rican", "53566": "Dominican",
    "53540": "Costa Rican", "53410": "Albanian", "53574": "German", "53506": "Bahamian", "53545": "Cuban",
    "53511": "Bahamian", "53443": "Aruban", "53577": "Estonian", "53470": "Botswanan", "53409": "Albanian",
    "53491": "Bulgarian", "53484": "Brazilian", "53395": "Dutch", "53479": "Brazilian", "53550": "French",
    "53435": "Armenian", "53558": "Dominican", "53535": "Costa Rican", "53404": "Albanian", "53405": "Albanian",
    "53444": "Austrian", "53415": "Andorran", "53416": "Andorran", "53394": "Dutch",
    "53507": "Caymanian", "53510": "Caymanian", "53528": "Colombian",
}

# Words in a meal's name, tags or method that name its country, for meals with no area at all.
COUNTRY_WORDS = {
    "colombia": "Colombian", "cambodia": "Cambodian", "khmer": "Cambodian", "laos": "Laotian", "lao ": "Laotian",
    "bajan": "Barbadian", "barbad": "Barbadian", "antigua": "Antiguan", "afghan": "Afghan", "albania": "Albanian",
    "brazil": "Brazilian", "bahia": "Brazilian", "peru": "Peruvian", "venezuel": "Venezuelan", "mexic": "Mexican",
    "cuba": "Cuban", "haiti": "Haitian", "dominica": "Dominican", "puerto ric": "Puerto Rican",
    "jamaica": "Jamaican", "trinidad": "Trinidadian", "guyan": "Guyanese", "chile": "Chilean",
    "argentin": "Argentine", "bolivia": "Bolivian", "ecuador": "Ecuadorean", "salvador": "Salvadoran",
    "guatemal": "Guatemalan", "hondur": "Honduran", "nicaragu": "Nicaraguan", "costa ric": "Costa Rican",
    "panam": "Panamanian", "ethiopia": "Ethiopian", "eritrea": "Eritrean", "nigeria": "Nigerian",
    "ghana": "Ghanaian", "senegal": "Senegalese", "kenya": "Kenyan", "tanzania": "Tanzanian",
    "uganda": "Ugandan", "somali": "Somali", "south africa": "South African", "zimbabw": "Zimbabwean",
    "zambia": "Zambian", "botswana": "Botswanan", "mozambi": "Mozambican", "malawi": "Malawian",
    "cameroon": "Cameroonian", "congo": "Congolese", "angola": "Angolan", "sudan": "Sudanese",
    "libya": "Libyan", "morocc": "Moroccan", "tunisia": "Tunisian", "algeria": "Algerian", "egypt": "Egyptian",
    "leban": "Lebanese", "syria": "Syrian", "jordan": "Jordanian", "palestin": "Palestinian",
    "israel": "Israeli", "iran": "Iranian", "persian": "Iranian", "iraq": "Iraqi", "yemen": "Yemeni",
    "saudi": "Saudi Arabian", "emirat": "Emirati", "turk": "Turkish", "armenia": "Armenian",
    "georgia": "Georgian", "azerbaij": "Azerbaijani", "kazakh": "Kazakhstani", "uzbek": "Uzbekistani",
    "mongol": "Mongolian", "pakistan": "Pakistani", "bangladesh": "Bangladeshi", "bengal": "Bangladeshi",
    "nepal": "Nepalese", "sri lank": "Sri Lankan", "india": "Indian", "burm": "Burmese", "myanmar": "Burmese",
    "thai": "Thai", "vietnam": "Vietnamese", "malaysia": "Malaysian", "singapor": "Singaporean",
    "indonesia": "Indonesian", "filipin": "Filipino", "philippin": "Filipino", "taiwan": "Taiwanese",
    "chinese": "Chinese", "china": "Chinese", "japan": "Japanese", "korea": "Korean", "fiji": "Fijian",
    "samoa": "Samoan", "tonga": "Tongan", "new zealand": "New Zealander", "australia": "Australian",
    "irish": "Irish", "ireland": "Irish", "scotti": "British", "welsh": "British", "english": "British",
    "british": "British", "french": "French", "france": "French", "spanish": "Spanish", "spain": "Spanish",
    "portug": "Portuguese", "italian": "Italian", "italy": "Italian", "greek": "Greek", "greece": "Greek",
    "cypr": "Cypriot", "german": "German", "austria": "Austrian", "swiss": "Swiss", "dutch": "Dutch",
    "belgi": "Belgian", "danish": "Danish", "denmark": "Danish", "swed": "Swedish", "norw": "Norwegian",
    "finn": "Finnish", "iceland": "Icelandic", "polish": "Polish", "poland": "Polish", "czech": "Czech",
    "slovak": "Slovak", "hungar": "Hungarian", "romania": "Romanian", "bulgaria": "Bulgarian",
    "serbia": "Serbian", "croatia": "Croatian", "bosnia": "Bosnian", "sloven": "Slovene",
    "macedon": "Macedonian", "montenegr": "Montenegrin", "kosov": "Kosovar", "ukrain": "Ukrainian",
    "russia": "Russian", "belarus": "Belarusian", "lithuan": "Lithuanian", "latvia": "Latvian",
    "estonia": "Estonian", "moldov": "Moldovan", "malta": "Maltese", "maltese": "Maltese", "canad": "Canadian",
    "american": "American", "cajun": "American", "uruguay": "Uruguayan", "paragu": "Paraguayan",
    "bahama": "Bahamian", "aruba": "Aruban", "mauriti": "Mauritian",
}

# Where each cuisine's pin sits: its capital or best-known food city.
CITIES = {
    "Afghan": ("Kabul", 34.53, 69.17), "Albanian": ("Tirana", 41.33, 19.82), "Algerian": ("Algiers", 36.75, 3.06),
    "American": ("New Orleans", 29.95, -90.07), "Andorran": ("Andorra la Vella", 42.51, 1.52),
    "Angolan": ("Luanda", -8.84, 13.23), "Antiguan": ("St. John's", 17.12, -61.85),
    "Argentine": ("Buenos Aires", -34.60, -58.38), "Armenian": ("Yerevan", 40.18, 44.51),
    "Aruban": ("Oranjestad", 12.52, -70.03), "Australian": ("Sydney", -33.87, 151.21),
    "Austrian": ("Vienna", 48.21, 16.37), "Azerbaijani": ("Baku", 40.41, 49.87), "Bahamian": ("Nassau", 25.04, -77.35),
    "Bangladeshi": ("Dhaka", 23.81, 90.41), "Barbadian": ("Bridgetown", 13.10, -59.61),
    "Belgian": ("Brussels", 50.85, 4.35), "Bolivian": ("La Paz", -16.49, -68.12),
    "Bosnian": ("Sarajevo", 43.86, 18.41), "Botswanan": ("Gaborone", -24.63, 25.92),
    "Brazilian": ("Salvador", -12.97, -38.50), "British": ("London", 51.51, -0.13),
    "Bulgarian": ("Sofia", 42.70, 23.32), "Cambodian": ("Phnom Penh", 11.56, 104.93),
    "Canadian": ("Montreal", 45.50, -73.57), "Chilean": ("Santiago", -33.45, -70.67),
    "Chinese": ("Chengdu", 30.57, 104.07), "Colombian": ("Bogotá", 4.71, -74.07),
    "Costa Rican": ("San José", 9.93, -84.08), "Croatian": ("Zagreb", 45.81, 15.98),
    "Caymanian": ("George Town", 19.29, -81.37), "Cuban": ("Havana", 23.11, -82.37), "Czech": ("Prague", 50.08, 14.44), "Danish": ("Copenhagen", 55.68, 12.57),
    "Dominican": ("Roseau", 15.30, -61.39), "Dutch": ("Amsterdam", 52.37, 4.90),
    "Egyptian": ("Cairo", 30.04, 31.24), "Estonian": ("Tallinn", 59.44, 24.75),
    "Filipino": ("Manila", 14.60, 120.98), "French": ("Lyon", 45.76, 4.84), "German": ("Berlin", 52.52, 13.40),
    "Greek": ("Athens", 37.98, 23.73), "Indian": ("Delhi", 28.61, 77.21), "Irish": ("Dublin", 53.35, -6.26),
    "Italian": ("Bologna", 44.49, 11.34), "Jamaican": ("Kingston", 18.02, -76.80),
    "Japanese": ("Osaka", 34.69, 135.50), "Kenyan": ("Nairobi", -1.29, 36.82),
    "Laotian": ("Vientiane", 17.97, 102.63), "Malaysian": ("Penang", 5.41, 100.33),
    "Mexican": ("Oaxaca", 17.07, -96.73), "Moroccan": ("Marrakesh", 31.63, -7.99),
    "Norwegian": ("Bergen", 60.39, 5.32), "Peruvian": ("Lima", -12.05, -77.04), "Polish": ("Kraków", 50.06, 19.94),
    "Portuguese": ("Lisbon", 38.72, -9.14), "Russian": ("Moscow", 55.76, 37.62),
    "Saudi Arabian": ("Jeddah", 21.49, 39.19), "Slovak": ("Bratislava", 48.15, 17.11),
    "Spanish": ("Valencia", 39.47, -0.38), "Syrian": ("Aleppo", 36.20, 37.13), "Thai": ("Bangkok", 13.76, 100.50),
    "Tunisian": ("Tunis", 36.81, 10.18), "Turkish": ("Istanbul", 41.01, 28.98),
    "Ukrainian": ("Kyiv", 50.45, 30.52), "Uruguayan": ("Montevideo", -34.90, -56.16),
    "Venezuelan": ("Caracas", 10.48, -66.90), "Vietnamese": ("Hanoi", 21.03, 105.85),
}


def cuisine_for(meal):
    area = meal.get("strArea")
    if area:
        return AREA_NAMES.get(area, area)
    if meal["idMeal"] in MISSING_AREAS:
        return MISSING_AREAS[meal["idMeal"]]
    text = " ".join([meal["strMeal"], meal.get("strTags") or "", meal.get("strInstructions") or ""]).lower()
    for word in sorted(COUNTRY_WORDS, key=len, reverse=True):
        if re.search(r"\b" + re.escape(word), text):
            return COUNTRY_WORDS[word]
    raise ValueError(f"No cuisine for {meal['idMeal']} {meal['strMeal']}")


# MARK: What a dish contains

def has(text, *words):
    return any(re.search(r"\b" + w + r"\b", text) for w in words)


def contents(meal, ingredients):
    """Diet tags from the ingredient list, matching Ingredient's raw values in DietaryRules.swift."""
    items = [i.lower() for i in ingredients]
    joined = " | ".join(items)
    name = meal["strMeal"].lower()
    category = meal["strCategory"]
    method = (meal.get("strInstructions") or "").lower()
    tags = set()

    def any_item(pattern, unless=None):
        for item in items:
            if re.search(pattern, item) and not (unless and re.search(unless, item)):
                return True
        return False

    if category == "Beef" or any_item(r"\b(beef|steak|veal|oxtail|brisket|bresaola|sirloin|mince|minced meat|ground meat)\b",
                                      r"(lamb|pork|chicken|turkey|beef stock|beef bouillon)"):
        tags.add("beef")
    if any_item(r"beef (stock|bouillon)"):
        tags.add("beef")
    if category == "Pork" or any_item(r"\b(pork|bacon|ham|gammon|chorizo|prosciutto|pancetta|salami|lard|lardons|pepperoni|black pudding|spare ribs|sausages?|morcilla|jamon|speck|guanciale)\b",
                                      r"(chicken sausage|beef sausage|turkey|vegetarian|vegan)"):
        tags.add("pork")
    if category in ("Lamb", "Goat") or any_item(r"\b(lamb|mutton|goat)\b"):
        tags.add("lamb")
    if category == "Chicken" or any_item(r"\b(chicken|turkey|duck|goose|quail|poussin|partridge)\b", r"chicken stock cube"):
        tags.add("poultry")
    if any_item(r"chicken stock"):
        tags.add("poultry")
    if any_item(r"\b(gelatine|gelatin)\b"):
        tags.add("gelatin")
    if any_item(r"\b(fish|salmon|tuna|cod|haddock|anchov\w*|sardines?|mackerel|trout|herring|tilapia|sea bass|monkfish|saltfish|kipper|halibut|swordfish|pollock|hake|bonito|dashi|snapper|bream|catfish|plaice|sole|worcestershire)\b",
                    r"fish sauce"):
        tags.add("fish")
    if any_item(r"fish sauce"):
        tags.update(["fish", "fermented", "salty"])
    if category == "Seafood" and not tags & {"fish"}:
        tags.add("fish")
    if any_item(r"\b(prawns?|shrimps?|crab|lobster|mussels?|clams?|oysters?|scallops?|squid|calamari|octopus|conch|crayfish|langoustines?|shrimp paste|oyster sauce)\b",
                r"oyster mushroom"):
        tags.add("shellfish")
    if any_item(r"\b(eggs?|egg yolks?|egg whites?|mayonnaise|meringue|egg noodles)\b", r"(flax|chia|vegan|egg replacer)"):
        tags.add("egg")
    if any_item(r"\b(milk|butter|cream|cheese|cheddar|parmesan|parmigiano|mozzarella|feta|ricotta|mascarpone|brie|camembert|gruy[eè]re|gorgonzola|stilton|halloumi|paneer|quark|yogh?urt|ghee|buttermilk|cr[eè]me fra[iî]che|custard|dulce de leche|whey|kefir|manjar|condensed|evaporated)\b",
                r"(coconut|almond milk|oat milk|soy milk|soya milk|peanut butter|butter beans?|cocoa butter|nut butter|cream of tartar|vegan)"):
        tags.add("dairy")
    if any_item(r"\b(flour|plain flour|self[- ]raising|bread|breadcrumbs|panko|pasta|spaghetti|macaroni|penne|fusilli|linguine|tagliatelle|fettuc+ine|pappardelle|rigatoni|farfalle|orzo|ravioli|tortellini|gnocchi|orecchiette|bucatini|ziti|vermicelli|conchiglie|lasagne|lasagna|noodles|ramen|udon|soba|lo mein|wonton|dumpling wrappers|pizza|couscous|bulgur|semolina|barley|rye|wheat|pastry|shortcrust|puff|filo|phyllo|tortillas?|pitta?|naan|biscuits?|digestives?|crackers|beer|seitan|oats|porridge|brioche|croissants?|baguette|ciabatta|soy sauce|cake|bagels?|buns?|rolls|muffins?)\b",
                r"(rice flour|corn ?flour|cornflour|almond flour|gram flour|chickpea flour|cassava|tapioca|coconut flour|buckwheat|rice noodles|glass noodles|corn tortillas?|gluten[- ]free|potato flour)"):
        tags.add("gluten")
    if any_item(r"\b(peanuts?|peanut butter|groundnuts?|satay)\b"):
        tags.add("peanut")
    if any_item(r"\b(almonds?|walnuts?|cashews?|pistachios?|hazelnuts?|pecans?|macadamias?|pine nuts?|brazil nuts?|chestnuts?|marzipan|praline|nutella|mixed nuts|nuts)\b",
                r"(chestnut mushroom|water chestnut|coconut|peanut|nutmeg)"):
        tags.add("treeNut")
    if any_item(r"\b(soy|soya|tofu|miso|edamame|tamari|tempeh|soybeans?|fermented soybeans)\b"):
        tags.add("soy")
    if any_item(r"\b(soy sauce|tamari|miso|tempeh|fermented)\b"):
        tags.update(["fermented", "salty"])
    if any_item(r"\b(sesame|tahini|halva)\b"):
        tags.add("sesame")
    if any_item(r"\bmustard\b"):
        tags.add("mustard")
    if any_item(r"\b(celery|celeriac)\b"):
        tags.add("celery")
    if any_item(r"\b(wine|sherry|port|madeira|vermouth|marsala|dried apricots?)\b", r"(wine vinegar)"):
        tags.add("sulfites")
    if any_item(r"wine vinegar"):
        tags.update(["sulfites", "acidic"])
    if any_item(r"\b(corn|sweetcorn|maize|cornmeal|polenta|corn ?flour|cornstarch|tortilla chips|grits|masa|popcorn|corn syrup|corn tortillas?|choclo|arepa|hominy)\b",
                r"(peppercorns?|corned beef)"):
        tags.add("corn")
    if any_item(r"\b(tomato\w*|passata|ketchup|potato\w*|aubergines?|eggplants?|bell peppers?|red peppers?|green peppers?|yellow peppers?|orange peppers?|peppers|chill?i\w*|chile\w*|jalape\w*|cayenne|paprika|chipotle|harissa|sriracha|tabasco|pimento|scotch bonnet|habanero|aji|piquillo|peri ?peri)\b",
                r"(sweet potato|black pepper|white pepper|peppercorn|pepper$|ground pepper|salt and pepper|szechuan pepper|sichuan pepper)"):
        tags.add("nightshade")
    if any_item(r"\b(onions?|garlic|shallots?|leeks?|chives?|scallions?|spring onions?|garlic powder|onion powder)\b"):
        tags.add("alliums")
    if any_item(r"\b(mushrooms?|shiitake|porcini|enoki|morels?|truffles?|huitlacoche|chanterelles?)\b",
                r"chocolate truffle"):
        tags.add("mushroom")
    if any_item(r"\b(beans|lentils?|chickpeas?|garbanzo|peas|split peas|black[- ]eyed peas|kidney beans|haricot|cannellini|butter beans|broad beans|fava|hummus|houmous|dal|dhal|daal|gram flour|chickpea flour|pigeon peas|gungo)\b",
                r"(green beans|french beans|runner beans|coffee beans|vanilla beans?|jelly beans|cocoa beans|snow peas|sugar snap)"):
        tags.add("legumes")
    if any_item(r"\b(potato\w*|sweet potato\w*|carrots?|beetroot|beets?|parsnips?|turnips?|swede|radish\w*|yams?|cassava|yuca|taro|celeriac|daikon|jicama)\b"):
        tags.add("rootVeg")
    if any_item(r"\b(rice|pasta|spaghetti|macaroni|penne|lasagne|fettuc+ine|tagliatelle|linguine|rigatoni|gnocchi|ravioli|tortellini|orzo|pizza|noodles|bread|breadcrumbs|flour|potato\w*|couscous|tortillas?|oats|quinoa|cornmeal|polenta|semolina|cassava|yuca|yams?|plantains?|pastry|filo|naan|pitta?|bulgur|barley|breadfruit|sweet potato\w*|arepa|masa)\b",
                r"(rice vinegar|rice wine|cauliflower rice)"):
        tags.add("starch")
    if category == "Dessert" or any_item(r"\b(sugar|caster|icing|brown sugar|honey|maple syrup|golden syrup|treacle|molasses|condensed milk|jam|chocolate|dulce de leche|agave|corn syrup|jaggery|marshmallows?|syrup|caramel|demerara|muscovado|panela|piloncillo)\b",
                                         r"(sugar snap|sugar-free)"):
        tags.add("sugar")
    if any_item(r"\b(wine|beer|rum|brandy|cognac|vodka|whisk(e)?y|sherry|port|vermouth|liqueur|mirin|sake|kirsch|amaretto|grand marnier|cider|stout|ale|tequila|gin|shaoxing|marsala|madeira|cointreau|baileys|calvados|kahlua|bourbon|prosecco|champagne|cachaça|lager)\b",
                r"(vinegar|non[- ]alcoholic)"):
        tags.add("alcohol")
    if any_item(r"\b(coffee|espresso|cocoa|cacao|chocolate|tea|matcha|cola)\b", r"(teaspoon|tsp)"):
        tags.add("caffeine")
    if any_item(r"\b(kimchi|sauerkraut|vinegar|parmesan|parmigiano|cheddar|blue cheese|gruy[eè]re|gorgonzola|stilton|salami|pepperoni|chorizo|yogh?urt|kefir|buttermilk|worcestershire|shrimp paste|gochujang|doenjang|pickled|pickles?|capers|olives|anchov\w*|soy sauce|miso)\b"):
        tags.add("fermented")
    if any_item(r"\b(bacon|ham|salami|anchov\w*|salt beef|saltfish|salt cod|olives|capers|feta|parmesan|stock cubes?|bouillon|corned beef|chorizo|prosciutto|pickled|soy sauce|halloumi|gammon|pancetta)\b"):
        tags.add("salty")
    if any_item(r"\b(vegetable oil|sunflower oil|canola|rapeseed oil|corn oil|groundnut oil|peanut oil|soybean oil|oil)\b",
                r"(olive|coconut|sesame|avocado|truffle|chilli oil|chili oil)"):
        tags.add("seedOil")
    if any_item(r"\b(chill?i\w*|chile\w*|jalape\w*|cayenne|hot sauce|sriracha|harissa|curry paste|scotch bonnet|habanero|gochujang|red pepper flakes|peri ?peri|tabasco|chipotle|sambal|bird'?s eye|aji)\b"):
        tags.add("spicy")
    if (any_item(r"\b(butter|cream|double cream|heavy cream|bacon|lard|suet|ghee|mayonnaise|pork belly|duck|sausages?|pastry|coconut cream|cheese)\b", r"(peanut butter|cream of tartar|butter beans)")
            or has(method, r"deep[- ]?fr\w*") or has(name, "fried", "fritters?", "fries", "crispy")):
        tags.add("highFat")
    if any_item(r"\b(tomato\w*|passata|lemons?|limes?|oranges?|vinegar|grapefruit|tamarind|citrus|pineapple|ketchup|lemon juice|lime juice)\b"):
        tags.add("acidic")
    if has(name, "sushi", "sashimi", "ceviche", "tartare", "carpaccio", "poke", "tiramisu", "gravlax"):
        tags.add("rawProtein")
    if has(method, "bake", "baked", "baking", "boil", "boiling", "fry", "fried", "frying", "roast", "roasting",
           "grill", "grilled", "simmer", "simmering", "cook", "cooked", "cooking", "heat", "oven", "saut[eé]",
           "toast", "steam", "steamed", "microwave", "stew", "braise", "poach", "sear", "barbecue", "smoke"):
        tags.add("cooked")
    return sorted(tags)


# MARK: Card details

GLYPHS = [  # (pattern on name, emoji) checked in order; the emoji maps to an ink glyph in InkArt.swift
    (r"\b(soup|stew|broth|chowder|hotpot|pho|ramen|laksa|congee|bisque|goulash|borscht|chorba|jjigae)\b", "🍲"),
    (r"\b(curry|masala|korma|vindaloo|biryani|tikka|dal|dhal)\b", "🍛"),
    (r"\b(noodles?|pasta|spaghetti|lasagne|lasagna|linguine|penne|macaroni|fettuccine|carbonara|lo mein|pad thai|udon)\b", "🍝"),
    (r"\b(rice|risotto|paella|pilaf|pilau|plov|jollof|kedgeree|fried rice)\b", "🍚"),
    (r"\b(sushi|fish|salmon|cod|tuna|trout|haddock|mackerel|sardines?|herring|sea bass|saltfish|kipper)\b", "🐟"),
    (r"\b(prawns?|shrimps?|crab|lobster|mussels?|clams?|squid|calamari|conch|scallops?)\b", "🦐"),
    (r"\b(dumplings?|gyoza|wontons?|empanadas?|pierogi|samosas?|momo|pasties|pasty|mantu|bolani)\b", "🥟"),
    (r"\b(tacos?|burritos?|fajitas?|quesadillas?|enchiladas?|tamales?|tamal|nachos)\b", "🌮"),
    (r"\b(salad|slaw|salsa|shopska)\b", "🥗"),
    (r"\b(eggs?|omelette|frittata|shakshuka|quiche|custard|flan|souffl[eé]|pudding)\b", "🥚"),
    (r"\b(mushrooms?)\b", "🍄"),
    (r"\b(pancakes?|crepes?|waffles?|blini|flija)\b", "🥞"),
    (r"\b(cake|tart|pie|cookies?|biscuits?|brownies?|bread|buns?|rolls?|muffins?|scones?|cheesecake|croissants?|loaf|focaccia|flatbreads?|pastry|strudel|baklava|toast|sandwich)\b", "🥐"),
    (r"\b(chicken|turkey|duck|wings)\b", "🍗"),
    (r"\b(beef|steak|lamb|pork|ribs|sausages?|burgers?|meatballs?|kebab|brisket|mutton|goat|bacon|ham)\b", "🥩"),
    (r"\b(beans|lentils?|chickpeas?|falafel|hummus)\b", "🫘"),
    (r"\b(chocolate|truffles?|fudge)\b", "🍫"),
]
CATEGORY_GLYPHS = {
    "Dessert": "🍰", "Seafood": "🐟", "Beef": "🥩", "Chicken": "🍗", "Pork": "🥩", "Lamb": "🍖", "Goat": "🍖",
    "Pasta": "🍝", "Vegetarian": "🥦", "Vegan": "🌱", "Breakfast": "🍳", "Side": "🥗", "Starter": "🥟",
    "Miscellaneous": "🍲",
}


def glyph_for(meal):
    name = meal["strMeal"].lower()
    for pattern, emoji in GLYPHS:
        if re.search(pattern, name):
            return emoji
    return CATEGORY_GLYPHS.get(meal["strCategory"], "🍲")


def clean_name(name):
    name = re.sub(r"\s+(recipe|Recipe)$", "", name.strip())
    name = re.sub(r"\s*Recipe\s*\(", " (", name)
    name = name.rstrip(".")
    return name[0].upper() + name[1:]


def minutes_for(meal):
    text = (meal.get("strInstructions") or "").lower()
    total = 0
    for amount, unit in re.findall(r"(\d+(?:\.\d+)?)(?:\s*[-–to]+\s*\d+)?\s*(hours?|hrs?|minutes?|mins?)", text):
        value = float(amount)
        total += value * 60 if unit.startswith("h") else value
    if "overnight" in text:
        total += 480
    total = max(10, min(1440, total or 30))
    step = 5 if total < 60 else 15 if total < 240 else 60
    return int(round(total / step) * step)


def seeded(key, low, high):
    digest = int(hashlib.sha256(key.encode()).hexdigest(), 16)
    return low + digest % (high - low + 1)


def percentile_ranks(values):
    order = sorted(range(len(values)), key=lambda i: values[i])
    ranks = [0.0] * len(values)
    for position, index in enumerate(order):
        ranks[index] = position / max(1, len(values) - 1)
    return ranks


# Share of the catalog in each tier, rarest last, with each tier's score band (matches RarityTier in Swift).
TIER_SHARES = [(0.34, 12, 39), (0.28, 40, 59), (0.20, 60, 74), (0.12, 75, 89), (0.06, 90, 100)]


def spread_into_tiers(factors):
    """Rescales each dish's four factors so the catalog lands in TIER_SHARES, keeping each dish's ranking."""
    totals = [sum(f) for f in factors]
    order = sorted(range(len(factors)), key=lambda i: totals[i])
    result = [list(f) for f in factors]
    start = 0
    for tier, (share, low, high) in enumerate(TIER_SHARES):
        end = len(order) if tier == len(TIER_SHARES) - 1 else start + round(share * len(order))
        band = order[start:end]
        for position, index in enumerate(band):
            target = low + round((high - low) * position / max(1, len(band) - 1))
            scaled = [max(1, min(25, round(f * target / totals[index]))) for f in factors[index]]
            # Rounding and the 25-point cap can leave the total off target, so nudge factors one point at a time.
            while sum(scaled) != target:
                step = 1 if sum(scaled) < target else -1
                candidates = [k for k in range(4) if 1 <= scaled[k] + step <= 25]
                k = max(candidates, key=lambda k: scaled[k] * -step)
                scaled[k] += step
            result[index] = scaled
        start = end
    return result


def build():
    meals = download_meals()
    # TheMealDB lists a few dishes twice under slightly different spellings, like Fettuccine and Fettucine Alfredo.
    seen = set()
    unique = []
    for meal in sorted(meals, key=lambda m: m["idMeal"]):
        key = re.sub(r"(.)\1+", r"\1", re.sub(r"[^a-z]", "", clean_name(meal["strMeal"]).lower()))
        if key not in seen:
            seen.add(key)
            unique.append(meal)
    meals = unique
    ingredient_lists = []
    for meal in meals:
        ingredients = [(meal.get(f"strIngredient{i}") or "").strip() for i in range(1, 21)]
        ingredient_lists.append([i for i in ingredients if i])
    ingredient_counts = collections.Counter(i.lower() for items in ingredient_lists for i in items)
    cuisines = [cuisine_for(m) for m in meals]
    cuisine_sizes = collections.Counter(cuisines)

    hard_words = ("knead", "prove", "proof", "laminate", "temper", "caramel", "deep fry", "deep-fry", "marinate",
                  "fold", "rest the dough", "roll out", "pipe", "blind bake", "emulsif", "reduce", "strain", "smoke")
    effort = []
    rare_ingredients = []
    for meal, items in zip(meals, ingredient_lists):
        method = (meal.get("strInstructions") or "").lower()
        steps = len(re.findall(r"[.!?]\s", method)) + 1
        effort.append(len(items) * 1.5 + steps + sum(5 for w in hard_words if w in method) + minutes_for(meal) / 30)
        rare_ingredients.append(sum(1 for i in items if ingredient_counts[i.lower()] <= 3) * 3 + len(items) * 0.4)
    effort_rank = percentile_ranks(effort)
    rarity_rank = percentile_ranks(rare_ingredients)
    heritage_rank = percentile_ranks([1 / cuisine_sizes[c] + seeded(m["idMeal"] + "h", 0, 100) / 2000
                                      for m, c in zip(meals, cuisines)])

    # Each factor is 3...25 points, from where the dish ranks among all of them.
    def points(rank):
        return 3 + round(rank * 22)

    factors = [[points(effort_rank[i]), points(rarity_rank[i]), points(heritage_rank[i]), seeded(m["idMeal"], 3, 25)]
               for i, m in enumerate(meals)]
    factors = spread_into_tiers(factors)

    recipes = []
    for index, (meal, items, cuisine) in enumerate(zip(meals, ingredient_lists, cuisines)):
        level = effort_rank[index]
        skill = "Beginner" if level < 0.3 else "Intermediate" if level < 0.65 else "Advanced" if level < 0.9 else "Professional"
        city, lat, lon = CITIES.get(cuisine, (cuisine, 0.0, 0.0))
        recipes.append({
            "id": meal["idMeal"],
            "name": clean_name(meal["strMeal"]),
            "emoji": glyph_for(meal),
            "cuisine": cuisine,
            "city": city,
            "latitude": lat,
            "longitude": lon,
            "skill": skill,
            "minutes": minutes_for(meal),
            "technique": factors[index][0],
            "ingredients": factors[index][1],
            "heritage": factors[index][2],
            "tradeScarcity": factors[index][3],
            "photo": meal["strMealThumb"],
            "contents": contents(meal, items),
            "ingredientList": items,
        })

    missing_cities = sorted({r["cuisine"] for r in recipes if r["latitude"] == 0 and r["longitude"] == 0})
    if missing_cities:
        raise SystemExit(f"Add these cuisines to CITIES: {missing_cities}")

    recipes.sort(key=lambda r: (r["cuisine"], r["name"]))
    OUT.write_text(json.dumps(recipes, ensure_ascii=False, indent=1))
    print(f"Wrote {len(recipes)} recipes to {OUT}")
    print(collections.Counter(r["cuisine"] for r in recipes).most_common())


if __name__ == "__main__":
    build()
