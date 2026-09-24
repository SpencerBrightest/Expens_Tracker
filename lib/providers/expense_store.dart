import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../models/category.dart';
import '../models/expense.dart';
import '../services/firestore_service.dart';

/// Phase-3 in-memory state. Categories cached here (never refetched per
/// screen). Firestore sync + pagination land in Phase 6; charts read from
/// here in Phase 4.
class ExpenseStore extends ChangeNotifier {
  ExpenseStore({List<Category>? categories, List<Expense>? expenses})
      : _categories = List.of(categories ?? const []),
        _expenses = List.of(expenses ?? const []) {
    _sortExpenses();
  }

  final List<Category> _categories;
  final List<Expense> _expenses;

  List<Category> get categories => List.unmodifiable(_categories);
  List<Expense> get expenses => List.unmodifiable(_expenses);

  double get totalSpent =>
      _expenses.fold(0, (sum, e) => sum + e.amount);

  double totalByCategory(String categoryId) => _expenses
      .where((e) => e.categoryId == categoryId)
      .fold(0, (sum, e) => sum + e.amount);

  /// Per-category totals for the donut chart. Skips zero-total categories
  /// so pie sections match visible spending.
  Map<String, double> totalsByCategory() {
    final totals = <String, double>{};
    for (final e in _expenses) {
      totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.amount;
    }
    totals.removeWhere((_, v) => v <= 0);
    return totals;
  }

  /// Monthly buckets oldest-first for the trend chart. Buckets by
  /// [Expense.date] year/month over the [months] ending at [reference].
  List<double> monthlyTotals({int months = 6, DateTime? reference}) {
    assert(months > 0, 'months must be > 0');
    final ref = reference ?? DateTime.now();
    final totals = List<double>.filled(months, 0);
    for (final e in _expenses) {
      final monthDiff =
          (ref.year - e.date.year) * 12 + (ref.month - e.date.month);
      if (monthDiff >= 0 && monthDiff < months) {
        totals[months - 1 - monthDiff] += e.amount;
      }
    }
    return totals;
  }

  Category categoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } on StateError {
      throw ArgumentError('Unknown category: $id');
    }
  }

  /// Category for display; falls back to an inline "Other" instead of
  /// throwing when an expense references a missing category.
  Category categoryFor(Expense expense) {
    try {
      return categoryById(expense.categoryId);
    } on ArgumentError {
      return Category(
        id: 'unknown',
        name: 'Other',
        monthlyLimit: 0,
        colorValue: 0xFF8A92A6,
        iconCodePoint: 0xe318,
      );
    }
  }

  void _sortExpenses() {
    _expenses.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  void addExpense(Expense expense) {
    if (_expenses.any((e) => e.id == expense.id)) {
      throw ArgumentError('Duplicate expense id: ${expense.id}');
    }
    categoryById(expense.categoryId); // validates category exists
    _expenses.add(expense);
    _sortExpenses();
    notifyListeners();
  }

  void updateExpense(Expense expense) {
    final i = _expenses.indexWhere((e) => e.id == expense.id);
    if (i == -1) throw ArgumentError('Unknown expense: ${expense.id}');
    categoryById(expense.categoryId);
    _expenses[i] = expense;
    _sortExpenses();
    notifyListeners();
  }

  void removeExpense(String id) {
    final i = _expenses.indexWhere((e) => e.id == id);
    if (i == -1) throw ArgumentError('Unknown expense: $id');
    _expenses.removeAt(i);
    notifyListeners();
  }

  /// Empties local expenses (used on sign-out so the next account never
  /// sees the previous user's data). Categories are left intact.
  void clear() {
    _expenses.clear();
    notifyListeners();
  }

  /// Adds a category (inline creation from Add/Edit Expense).
  void addCategory(Category category) {
    if (_categories.any((c) => c.id == category.id)) {
      throw ArgumentError('Duplicate category id: ${category.id}');
    }
    _categories.add(category);
    notifyListeners();
  }

  /// Replaces local state with the user's remote data (Phase 6).
  Future<void> loadFromRemote(FirestoreService svc) async {
    final expenses = await svc.watchExpenses(limit: 500).first;
    final categories = await svc.watchCategories().first;
    _expenses
      ..clear()
      ..addAll(expenses);
    _categories
      ..clear()
      ..addAll(categories);
    _sortExpenses();
    notifyListeners();
  }

  /// Optimistic save: inserts locally first, syncs in the background,
  /// rolls back only on failure (then rethrows).
  Future<void> persistExpense(
    FirestoreService svc,
    Expense expense,
  ) async {
    categoryById(expense.categoryId);
    final i = _expenses.indexWhere((e) => e.id == expense.id);
    final previous = i == -1 ? null : _expenses[i];
    if (i == -1) {
      _expenses.add(expense);
    } else {
      _expenses[i] = expense;
    }
    _sortExpenses();
    notifyListeners();
    try {
      await svc.saveExpense(expense);
    } catch (_) {
      if (previous == null) {
        _expenses.removeWhere((e) => e.id == expense.id);
      } else {
        final j = _expenses.indexWhere((e) => e.id == expense.id);
        if (j != -1) _expenses[j] = previous;
      }
      _sortExpenses();
      notifyListeners();
      rethrow;
    }
  }

  /// Optimistic delete with rollback on failure.
  Future<void> deleteExpenseRemote(
    FirestoreService svc,
    String id,
  ) async {
    final i = _expenses.indexWhere((e) => e.id == id);
    if (i == -1) throw ArgumentError('Unknown expense: $id');
    final removed = _expenses.removeAt(i);
    notifyListeners();
    try {
      await svc.deleteExpense(id);
    } catch (_) {
      _expenses.add(removed);
      _sortExpenses();
      notifyListeners();
      rethrow;
    }
  }
}
