import 'package:flutter/foundation.dart';

/// Category model. Firestore doc: `users/{uid}/categories/{id}`.
/// Icon/color stored as primitives so custom Stitch categories persist.
@immutable
class Category {
  Category({
    required this.id,
    required this.name,
    required this.monthlyLimit,
    required this.colorValue,
    required this.iconCodePoint,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Category name must not be blank');
    }
    if (monthlyLimit < 0) {
      throw ArgumentError('monthlyLimit must be >= 0');
    }
  }

  final String id;
  final String name;
  final double monthlyLimit;
  final int colorValue;
  final int iconCodePoint;

  Category copyWith({
    String? id,
    String? name,
    double? monthlyLimit,
    int? colorValue,
    int? iconCodePoint,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'monthlyLimit': monthlyLimit,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
    };
  }

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      id: id,
      name: map['name'] as String,
      monthlyLimit: (map['monthlyLimit'] as num).toDouble(),
      colorValue: map['colorValue'] as int,
      iconCodePoint: map['iconCodePoint'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.monthlyLimit == monthlyLimit &&
        other.colorValue == colorValue &&
        other.iconCodePoint == iconCodePoint;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, monthlyLimit, colorValue, iconCodePoint);
}
