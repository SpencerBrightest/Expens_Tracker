import 'package:flutter/material.dart';

/// All icons offered for categories.
const List<IconData> kCategoryIconChoices = [
  Icons.home_outlined,
  Icons.restaurant_outlined,
  Icons.directions_car_outlined,
  Icons.movie_outlined,
  Icons.favorite_outline,
  Icons.shopping_bag_outlined,
  Icons.shopping_cart_outlined,
  Icons.bolt_outlined,
  Icons.fitness_center_outlined,
  Icons.sports_esports_outlined,
  Icons.storefront_outlined,
  Icons.local_cafe_outlined,
  Icons.savings_outlined,
  Icons.flight_outlined,
];

/// Registry mapping persisted icon code points back to [IconData].
/// Flutter marks `IconData.codePoint` `@mustBeConst`, so icons stored in
/// Category docs must round-trip through this table (unknown codes fall
/// back to [Icons.category_outlined]).
final Map<int, IconData> kCategoryIcons = {
  for (final icon in kCategoryIconChoices) icon.codePoint: icon,
};

IconData categoryIcon(int codePoint) =>
    kCategoryIcons[codePoint] ?? Icons.category_outlined;
