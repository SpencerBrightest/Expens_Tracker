import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../models/category.dart';
import '../models/expense.dart';

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

  Category categoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } on StateError {
      throw ArgumentError('Unknown category: $id');
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
}
