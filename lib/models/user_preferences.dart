import 'package:flutter/foundation.dart';

@immutable
class UserPreferences {
  const UserPreferences({
    required this.dailyReminder,
    required this.budgetAlerts,
  });

  final bool dailyReminder;
  final bool budgetAlerts;

  Map<String, dynamic> toMap() => {
    'dailyReminder': dailyReminder,
    'budgetAlerts': budgetAlerts,
  };

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      dailyReminder: map['dailyReminder'] as bool? ?? false,
      budgetAlerts: map['budgetAlerts'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserPreferences &&
      other.dailyReminder == dailyReminder &&
      other.budgetAlerts == budgetAlerts;

  @override
  int get hashCode => Object.hash(dailyReminder, budgetAlerts);
}
