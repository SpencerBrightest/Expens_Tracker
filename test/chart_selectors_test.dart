import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/expense_store.dart';
import 'package:flutter_test/flutter_test.dart';

Category _cat(String id) => Category(
      id: id,
      name: 'Name $id',
      monthlyLimit: 1000,
      colorValue: 0xFF2D68FE,
      iconCodePoint: 0xe318,
    );

Expense _exp(String id, String catId, double amount, DateTime date) =>
    Expense(
      id: id,
      amount: amount,
      categoryId: catId,
      note: 'n',
      date: date,
    );

void main() {
  group('ExpenseStore chart selectors', () {
    test('totalsByCategory maps each category to its total', () {
      final store = ExpenseStore(categories: [_cat('c1'), _cat('c2')]);
      store.addExpense(_exp('e1', 'c1', 100, DateTime(2024, 11, 1)));
      store.addExpense(_exp('e2', 'c2', 300, DateTime(2024, 11, 2)));
      store.addExpense(_exp('e3', 'c1', 50, DateTime(2024, 11, 3)));
      expect(store.totalsByCategory(), {'c1': 150, 'c2': 300});
    });

    test('totalsByCategory is empty when no expenses', () {
      final store = ExpenseStore(categories: [_cat('c1')]);
      expect(store.totalsByCategory(), isEmpty);
    });

    test('monthlyTotals buckets last N months oldest-first', () {
      final store = ExpenseStore(categories: [_cat('c1')]);
      store.addExpense(_exp('e1', 'c1', 100, DateTime(2024, 10, 5)));
      store.addExpense(_exp('e2', 'c1', 200, DateTime(2024, 12, 1)));
      store.addExpense(_exp('e3', 'c1', 50, DateTime(2024, 12, 20)));

      final totals = store.monthlyTotals(
        months: 3,
        reference: DateTime(2024, 12, 15),
      );
      // Oct, Nov, Dec
      expect(totals, [100, 0, 250]);
    });

    test('monthlyTotals ignores expenses older than window', () {
      final store = ExpenseStore(categories: [_cat('c1')]);
      store.addExpense(_exp('e1', 'c1', 999, DateTime(2023, 1, 1)));
      store.addExpense(_exp('e2', 'c1', 10, DateTime(2024, 12, 1)));

      final totals = store.monthlyTotals(
        months: 2,
        reference: DateTime(2024, 12, 15),
      );
      expect(totals, [0, 10]);
    });
  });
}
