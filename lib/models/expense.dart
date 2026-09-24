import 'package:flutter/foundation.dart';

/// Expense model. Firestore doc: `users/{uid}/expenses/{id}`.
/// Amounts are XAF. `summary` is the Phase-8 AI one-liner; when absent,
/// [effectiveSummary] falls back to the plain template (instant, free).
@immutable
class Expense {
  Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.note,
    required this.date,
    this.paymentMethod,
    this.summary,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now() {
    if (amount <= 0) {
      throw ArgumentError('amount must be > 0');
    }
  }

  final String id;
  final double amount;
  final String categoryId;
  final String note;
  final DateTime date;
  final String? paymentMethod;
  final String? summary;
  final DateTime createdAt;

  /// Plain template from the brief: `"<amount> XAF — <Category>, <note>"`.
  String effectiveSummary(String categoryName) {
    final s = summary?.trim();
    if (s != null && s.isNotEmpty) return s;
    final amt = amount % 1 == 0
        ? amount.toInt().toString()
        : amount.toString();
    return '$amt XAF — $categoryName, $note';
  }

  Expense copyWith({
    String? id,
    double? amount,
    String? categoryId,
    String? note,
    DateTime? date,
    String? paymentMethod,
    String? summary,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'categoryId': categoryId,
      'note': note,
      'date': date.millisecondsSinceEpoch,
      'paymentMethod': paymentMethod,
      'summary': summary,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    return Expense(
      id: id,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] as String,
      note: map['note'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      paymentMethod: map['paymentMethod'] as String?,
      summary: map['summary'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Expense &&
        other.id == id &&
        other.amount == amount &&
        other.categoryId == categoryId &&
        other.note == note &&
        other.date == date &&
        other.paymentMethod == paymentMethod &&
        other.summary == summary;
  }

  @override
  int get hashCode => Object.hash(
        id,
        amount,
        categoryId,
        note,
        date,
        paymentMethod,
        summary,
      );
}
