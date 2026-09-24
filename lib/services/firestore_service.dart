import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';
import '../models/expense.dart';

/// One page of expenses plus the cursor for the next page.
class ExpensePage {
  const ExpensePage({required this.expenses, required this.lastDoc});

  final List<Expense> expenses;

  /// Null when this page is empty (nothing more to fetch).
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
}

/// Firestore access, scoped per user:
/// `users/{uid}/expenses/{id}`, `users/{uid}/categories/{id}`.
/// Screens/widgets must use this — never import cloud_firestore directly.
class FirestoreService {
  FirestoreService({FirebaseFirestore? db, required this.uid})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final String uid;

  CollectionReference<Map<String, dynamic>> get _expenses => _db
      .collection('users')
      .doc(uid)
      .collection('expenses');

  CollectionReference<Map<String, dynamic>> get _categories => _db
      .collection('users')
      .doc(uid)
      .collection('categories');

  static List<Expense> _expenseList(QuerySnapshot<Map<String, dynamic>> snap) {
    return snap.docs
        .map((d) => Expense.fromMap(d.id, d.data()))
        .toList();
  }

  Query<Map<String, dynamic>> _orderedExpenses({int? limit}) {
    var q = _expenses.orderBy('date', descending: true);
    if (limit != null) q = q.limit(limit);
    return q;
  }

  /// Live expense list, newest-first.
  Stream<List<Expense>> watchExpenses({int limit = 50}) {
    return _orderedExpenses(limit: limit)
        .snapshots()
        .map(_expenseList);
  }

  /// One page of expenses for `limit()/startAfter()` pagination.
  /// The cursor is applied before the limit so chained evaluation
  /// (and the fake backend) pages correctly; real Firestore treats
  /// the built query declaratively with the same result.
  Future<ExpensePage> fetchExpensesPage({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    var q = _expenses.orderBy('date', descending: true);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    final snap = await q.limit(limit).get();
    final docs = snap.docs;
    return ExpensePage(
      expenses: _expenseList(snap),
      lastDoc: docs.isEmpty ? null : docs.last,
    );
  }

  Future<void> saveExpense(Expense expense) {
    return _expenses.doc(expense.id).set(expense.toMap());
  }

  Future<void> deleteExpense(String id) {
    return _expenses.doc(id).delete();
  }

  Stream<List<Category>> watchCategories() {
    return _categories.snapshots().map(
          (snap) => snap.docs
              .map((d) => Category.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> saveCategory(Category category) {
    return _categories.doc(category.id).set(category.toMap());
  }

  Future<void> deleteCategory(String id) {
    return _categories.doc(id).delete();
  }
}
