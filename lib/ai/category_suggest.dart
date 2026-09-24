import '../models/category.dart';

/// Cheap keyword matching per category-name stem. Checked after an exact
/// category-name hit. Keep keywords tight to avoid false positives.
const Map<String, List<String>> _keywords = {
  'housing': ['rent', 'house', 'housing', 'landlord', 'apartment'],
  'food': [
    'food',
    'restaurant',
    'grocery',
    'groceries',
    'dining',
    'eat',
    'lunch',
    'dinner',
    'breakfast',
    'bread',
    'market',
    'cafe',
    'coffee',
  ],
  'transport': [
    'transport',
    'moto',
    'taxi',
    'bus',
    'car',
    'fuel',
    'gas',
    'uber',
    'ride',
    'fare',
    'parking',
  ],
  'entertainment': [
    'entertainment',
    'netflix',
    'movie',
    'cinema',
    'game',
    'fun',
    'music',
    'concert',
    'sport',
  ],
  'health': [
    'health',
    'gym',
    'hospital',
    'doctor',
    'pharmacy',
    'clinic',
    'medicine',
  ],
  'shopping': [
    'shopping',
    'clothes',
    'shoes',
    'store',
    'mall',
    'boutique',
  ],
  'bills': ['bill', 'electric', 'water', 'utility', 'internet', 'phone'],
};

/// Returns the id of the best-matching category for [note], or null.
/// An explicit category-name hit wins; otherwise first keyword hit in
/// category order. Case-insensitive, no network.
String? suggestCategoryId(String note, List<Category> categories) {
  final text = note.trim().toLowerCase();
  if (text.isEmpty || categories.isEmpty) return null;

  for (final c in categories) {
    if (text.contains(c.name.toLowerCase())) return c.id;
  }
  for (final c in categories) {
    final stem = c.name.split(' ').first.toLowerCase();
    final keys = _keywords[stem] ?? const <String>[];
    for (final k in keys) {
      if (text.contains(k)) return c.id;
    }
  }
  return null;
}
