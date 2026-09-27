import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/expense_store.dart';
import 'package:expense_tracker/screens/analytics_screen.dart';
import 'package:expense_tracker/widgets/spending_pie_chart.dart';
import 'package:expense_tracker/widgets/spending_trend_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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

Widget _withStore(ExpenseStore store, Widget child) {
  return ChangeNotifierProvider<ExpenseStore>.value(
    value: store,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('SpendingPieChart', () {
    testWidgets('sections reflect store totals by category', (tester) async {
      final store = ExpenseStore(categories: [_cat('c1'), _cat('c2')]);
      store.addExpense(_exp('e1', 'c1', 150, DateTime(2024, 11, 1)));
      store.addExpense(_exp('e2', 'c2', 300, DateTime(2024, 11, 2)));

      await tester.pumpWidget(_withStore(store, const SpendingPieChart()));
      await tester.pumpAndSettle();

      final pie = tester.widget<PieChart>(find.byType(PieChart));
      final values =
          pie.data.sections.map((s) => s.value).toList()..sort();
      expect(values, [150, 300]);
    });

    testWidgets('empty store shows honest empty state', (tester) async {
      final store = ExpenseStore(categories: [_cat('c1')]);
      await tester.pumpWidget(_withStore(store, const SpendingPieChart()));
      await tester.pumpAndSettle();
      expect(find.byType(PieChart), findsNothing);
      expect(find.text('No spending yet'), findsOneWidget);
    });

    testWidgets('totals mode labels slices with compact amounts',
        (tester) async {
      final store = ExpenseStore(categories: [_cat('c1'), _cat('c2')]);
      store.addExpense(_exp('e1', 'c1', 1500, DateTime(2024, 11, 1)));
      store.addExpense(_exp('e2', 'c2', 300, DateTime(2024, 11, 2)));

      await tester.pumpWidget(
        _withStore(store, const SpendingPieChart(showPercentage: false)),
      );
      await tester.pumpAndSettle();

      final pie = tester.widget<PieChart>(find.byType(PieChart));
      final titles =
          pie.data.sections.map((s) => s.title).toList()..sort();
      expect(titles, ['1.5k', '300']);
      expect(find.textContaining('Name c1'), findsOneWidget);
    });

    testWidgets('percentage mode labels slices with shares of total',
        (tester) async {
      final store = ExpenseStore(categories: [_cat('c1'), _cat('c2')]);
      store.addExpense(_exp('e1', 'c1', 150, DateTime(2024, 11, 1)));
      store.addExpense(_exp('e2', 'c2', 300, DateTime(2024, 11, 2)));

      await tester.pumpWidget(
        _withStore(store, const SpendingPieChart(showPercentage: true)),
      );
      await tester.pumpAndSettle();

      final pie = tester.widget<PieChart>(find.byType(PieChart));
      final titles =
          pie.data.sections.map((s) => s.title).toList()..sort();
      expect(titles, ['33%', '67%']);
      // Legend shows "this percent on this".
      expect(find.text('33.3%'), findsOneWidget);
      expect(find.text('66.7%'), findsOneWidget);
    });
  });

  group('SpendingTrendChart', () {
    testWidgets('bars reflect monthly buckets oldest-first', (tester) async {
      final store = ExpenseStore(categories: [_cat('c1')]);
      store.addExpense(_exp('e1', 'c1', 100, DateTime(2024, 10, 5)));
      store.addExpense(_exp('e2', 'c1', 250, DateTime(2024, 12, 1)));

      await tester.pumpWidget(
        _withStore(
          store,
          SpendingTrendChart(
            months: 3,
            reference: DateTime(2024, 12, 15),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bar = tester.widget<BarChart>(find.byType(BarChart));
      final heights =
          bar.data.barGroups.map((g) => g.barRods.first.toY).toList();
      expect(heights, [100, 0, 250]);
    });
  });

  group('AnalyticsScreen filter', () {
    testWidgets('Totals/Percentages toggle reshapes the donut',
        (tester) async {
      final store = ExpenseStore(categories: [_cat('c1'), _cat('c2')]);
      store.addExpense(_exp('e1', 'c1', 150, DateTime(2024, 11, 1)));
      store.addExpense(_exp('e2', 'c2', 300, DateTime(2024, 11, 2)));

      await tester.pumpWidget(
        _withStore(store, const AnalyticsScreen()),
      );
      await tester.pumpAndSettle();

      // Summary row shows the computed total and top share.
      expect(find.text('Total spent'), findsOneWidget);
      expect(find.textContaining('of spending'), findsWidgets);

      // Totals mode first: compact amount labels.
      var pie = tester.widget<PieChart>(find.byType(PieChart));
      expect(
        pie.data.sections.map((s) => s.title).toList(),
        contains('150'),
      );

      // Switch to Percentages: slice + legend show shares.
      await tester.tap(find.text('Percentages'));
      await tester.pumpAndSettle();
      pie = tester.widget<PieChart>(find.byType(PieChart));
      final titles = pie.data.sections.map((s) => s.title).toList()
        ..sort();
      expect(titles, ['33%', '67%']);
      expect(find.text('66.7%'), findsOneWidget);
    });
  });
}
