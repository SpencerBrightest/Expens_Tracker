import 'package:expense_tracker/ai/insights.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/expense_store.dart';
import 'package:flutter_test/flutter_test.dart';

ExpenseStore _store({
  List<Category> categories = const [],
  List<Expense> expenses = const [],
}) =>
    ExpenseStore(categories: categories, expenses: expenses);

Category _cat(String id, String name, double limit) => Category(
      id: id,
      name: name,
      monthlyLimit: limit,
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
  group('buildInsight', () {
    test('empty store prompts first expense', () {
      expect(
        buildInsight(_store()),
        contains('first expense'),
      );
    });

    test('over-budget category takes priority', () {
      final store = _store(
        categories: [_cat('c1', 'Food', 100)],
        expenses: [_exp('e1', 'c1', 150, DateTime(2024, 11, 1))],
      );
      final insight = buildInsight(store);
      expect(insight, contains('Food'));
      expect(insight, contains('over budget'));
    });

    test('dominant category share is reported', () {
      final store = _store(
        categories: [_cat('c1', 'Food', 1000), _cat('c2', 'Other', 1000)],
        expenses: [
          _exp('e1', 'c1', 800, DateTime(2024, 11, 1)),
          _exp('e2', 'c2', 200, DateTime(2024, 11, 2)),
        ],
      );
      expect(buildInsight(store), contains('Food'));
      expect(buildInsight(store), contains('80%'));
    });

    test('spread spending reports category count', () {
      final store = _store(
        categories: [
          _cat('c1', 'Food', 1000),
          _cat('c2', 'Other', 1000),
          _cat('c3', 'More', 1000),
        ],
        expenses: [
          _exp('e1', 'c1', 100, DateTime(2024, 11, 1)),
          _exp('e2', 'c2', 100, DateTime(2024, 11, 2)),
          _exp('e3', 'c3', 100, DateTime(2024, 11, 3)),
        ],
      );
      expect(buildInsight(store), contains('3 categories'));
    });
  });
}
