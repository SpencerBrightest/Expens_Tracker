import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/expense_store.dart';
import 'package:flutter_test/flutter_test.dart';

Category _cat(String id, String name) => Category(
      id: id,
      name: name,
      monthlyLimit: 1000,
      colorValue: 0xFF2D68FE,
      iconCodePoint: 0xe318,
    );

Expense _exp(String id, String catId, double amount) => Expense(
      id: id,
      amount: amount,
      categoryId: catId,
      note: 'note $id',
      date: DateTime(2024, 11, 20),
    );

void main() {
  group('ExpenseStore', () {
    test('seeds categories and starts with empty expenses', () {
      final store = ExpenseStore(categories: [_cat('c1', 'Food')]);
      expect(store.categories.map((c) => c.id), ['c1']);
      expect(store.expenses, isEmpty);
      expect(store.totalSpent, 0);
    });

    test('addExpense inserts newest-first and notifies', () {
      final store = ExpenseStore(categories: [_cat('c1', 'Food')]);
      var notified = 0;
      store.addListener(() => notified++);

      store.addExpense(_exp('e1', 'c1', 5000));
      store.addExpense(_exp('e2', 'c1', 2500));

      expect(store.expenses.map((e) => e.id), ['e2', 'e1']);
      expect(store.totalSpent, 7500);
      expect(notified, 2);
    });

    test('addExpense rejects duplicate id and unknown category', () {
      final store = ExpenseStore(categories: [_cat('c1', 'Food')]);
      store.addExpense(_exp('e1', 'c1', 100));
      expect(() => store.addExpense(_exp('e1', 'c1', 200)),
          throwsArgumentError);
      expect(() => store.addExpense(_exp('e9', 'nope', 200)),
          throwsArgumentError);
    });

    test('updateExpense replaces and notifies', () {
      final store = ExpenseStore(categories: [_cat('c1', 'Food')]);
      store.addExpense(_exp('e1', 'c1', 100));
      var notified = 0;
      store.addListener(() => notified++);

      store.updateExpense(_exp('e1', 'c1', 400));
      expect(store.totalSpent, 400);
      expect(notified, 1);
      expect(() => store.updateExpense(_exp('zz', 'c1', 5)),
          throwsArgumentError);
    });

    test('removeExpense deletes and notifies', () {
      final store = ExpenseStore(categories: [_cat('c1', 'Food')]);
      store.addExpense(_exp('e1', 'c1', 100));
      var notified = 0;
      store.addListener(() => notified++);

      store.removeExpense('e1');
      expect(store.expenses, isEmpty);
      expect(notified, 1);
      expect(() => store.removeExpense('e1'), throwsArgumentError);
    });

    test('totalByCategory sums only that category', () {
      final store = ExpenseStore(
        categories: [_cat('c1', 'Food'), _cat('c2', 'Transport')],
      );
      store.addExpense(_exp('e1', 'c1', 100));
      store.addExpense(_exp('e2', 'c2', 300));
      store.addExpense(_exp('e3', 'c1', 50));
      expect(store.totalByCategory('c1'), 150);
      expect(store.totalByCategory('c2'), 300);
    });

    test('categoryById returns category or throws', () {
      final store = ExpenseStore(categories: [_cat('c1', 'Food')]);
      expect(store.categoryById('c1').name, 'Food');
      expect(() => store.categoryById('zz'), throwsArgumentError);
    });
  });
}
