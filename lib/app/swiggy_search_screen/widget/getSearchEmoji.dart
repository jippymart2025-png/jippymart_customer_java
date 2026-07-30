final Map<String, String> _emojiCache = {};

String getSearchEmoji(String search) {
  // Check cache first
  if (_emojiCache.containsKey(search)) {
    return _emojiCache[search]!;
  }

  final lowerSearch = search.toLowerCase();
  String emoji = '🍽️'; // Default

  // Food categories
  if (lowerSearch.contains('pizza'))
    emoji = '🍕';
  else if (lowerSearch.contains('biryani'))
    emoji = '🍛';
  else if (lowerSearch.contains('burger'))
    emoji = '🍔';
  else if (lowerSearch.contains('coffee'))
    emoji = '☕';
  else if (lowerSearch.contains('ice cream'))
    emoji = '🍦';
  else if (lowerSearch.contains('chicken'))
    emoji = '🍗';
  else if (lowerSearch.contains('pasta'))
    emoji = '🍝';
  else if (lowerSearch.contains('sushi'))
    emoji = '🍣';
  else if (lowerSearch.contains('taco'))
    emoji = '🌮';
  else if (lowerSearch.contains('sandwich'))
    emoji = '🥪';
  else if (lowerSearch.contains('salad'))
    emoji = '🥗';
  else if (lowerSearch.contains('soup'))
    emoji = '🍲';
  else if (lowerSearch.contains('noodles'))
    emoji = '🍜';
  else if (lowerSearch.contains('rice'))
    emoji = '🍚';
  else if (lowerSearch.contains('bread'))
    emoji = '🍞';
  else if (lowerSearch.contains('cake'))
    emoji = '🍰';
  else if (lowerSearch.contains('dessert'))
    emoji = '🍮';
  else if (lowerSearch.contains('sweet'))
    emoji = '🍭';
  else if (lowerSearch.contains('spicy'))
    emoji = '🌶️';
  else if (lowerSearch.contains('healthy'))
    emoji = '🥑';
  else if (lowerSearch.contains('vegetarian') || lowerSearch.contains('veg'))
    emoji = '🥬';
  // Cuisines
  else if (lowerSearch.contains('chinese'))
    emoji = '🥢';
  else if (lowerSearch.contains('italian'))
    emoji = '🍝';
  else if (lowerSearch.contains('indian'))
    emoji = '🍛';
  else if (lowerSearch.contains('mexican'))
    emoji = '🌮';
  else if (lowerSearch.contains('japanese'))
    emoji = '🍣';
  else if (lowerSearch.contains('thai'))
    emoji = '🍜';
  else if (lowerSearch.contains('korean'))
    emoji = '🥘';
  else if (lowerSearch.contains('american'))
    emoji = '🍔';
  else if (lowerSearch.contains('fast food'))
    emoji = '🍟';
  // General food terms
  else if (lowerSearch.contains('food'))
    emoji = '🍽️';
  else if (lowerSearch.contains('restaurant'))
    emoji = '🍴';
  else if (lowerSearch.contains('meal'))
    emoji = '🍽️';
  else if (lowerSearch.contains('lunch'))
    emoji = '🍱';
  else if (lowerSearch.contains('dinner'))
    emoji = '🍽️';
  else if (lowerSearch.contains('breakfast'))
    emoji = '🥞';
  else if (lowerSearch.contains('snack'))
    emoji = '🍿';

  // Cache the result
  _emojiCache[search] = emoji;
  return emoji;
}
