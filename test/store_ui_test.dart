import 'package:expense_tracker/data/dummy_data.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/expense_store.dart';
import 'package:expense_tracker/screens/add_edit_expense_screen.dart';
import 'package:expense_tracker/screens/analytics_screen.dart';
import 'package:expense_tracker/screens/categories_screen.dart';
import 'package:expense_tracker/screens/home_tab.dart';
import 'package:expense_tracker/screens/transactions_screen.dart';
import 'package:expense_tracker/ai/summary.dart';
import 'package:expense_tracker/services/firestore_service.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/theme/app_theme.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

Category _cat() => Category(
      id: 'c1',
      name: 'Food',
      monthlyLimit: 1000,
      colorValue: 0xFFFA5A36,
      iconCodePoint: 0xe318,
    );

Expense _exp() => Expense(
      id: 'e1',
      amount: 2500,
      categoryId: 'c1',
      note: 'moto to school',
      date: DateTime(2024, 11, 20),
    );

ExpenseStore _seededStore() {
  final store = ExpenseStore(categories: [_cat()]);
  store.addExpense(_exp());
  return store;
}

Widget _withStore(ExpenseStore store, Widget child,
    {FirestoreService? service}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ExpenseStore>.value(value: store),
      Provider<FirestoreService?>.value(value: service),
      ChangeNotifierProvider<NotificationService>(
        create: (_) =>
            NotificationService(backend: FakeNotificationBackend()),
      ),
      Provider<SummaryService>.value(value: SummaryService()),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: Scaffold(body: child)),
  );
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    500,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Screens read ExpenseStore', () {
    testWidgets('HomeTab shows store total and recent note',
        (tester) async {
      await tester.pumpWidget(_withStore(_seededStore(), const HomeTab()));
      await tester.pumpAndSettle();
      expect(find.text(xafFormat.format(2500)), findsWidgets);
      await _reveal(tester, find.text('moto to school'));
      expect(find.text('moto to school'), findsOneWidget);
    });

    testWidgets('TransactionsScreen lists store expenses', (tester) async {
      await tester.pumpWidget(
        _withStore(_seededStore(), const TransactionsScreen()),
      );
      await tester.pumpAndSettle();
      await _reveal(tester, find.text('moto to school'));
      expect(find.text('moto to school'), findsOneWidget);
    });

    testWidgets('CategoriesScreen shows computed spent', (tester) async {
      await tester.pumpWidget(
        _withStore(_seededStore(), const CategoriesScreen()),
      );
      await tester.pumpAndSettle();
      await _reveal(tester, find.text('Food'));
      expect(find.text(xafFormat.format(250)), findsNothing);
      expect(find.text(xafFormat.format(2500)), findsWidgets);
    });

    testWidgets('AnalyticsScreen total comes from store', (tester) async {
      await tester.pumpWidget(
        _withStore(_seededStore(), const AnalyticsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text(xafFormat.format(2500)), findsWidgets);
      // Seeded Food (limit 1000) holds 2500 → over-budget insight.
      expect(find.textContaining('over budget'), findsOneWidget);
    });
  });

  group('AddEditExpenseScreen', () {
    testWidgets('Save persists to store and remote', (tester) async {
      final service = FirestoreService(
        db: FakeFirebaseFirestore(),
        uid: 'u1',
      );
      final store = ExpenseStore(categories: [_cat()]);
      await tester.pumpWidget(
        _withStore(store, const AddEditExpenseScreen(),
            service: service),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).last,
        'moto to school',
      );
      await tester.pump();
      await _reveal(tester, find.text('Save Expense'));
      await tester.tap(find.text('Save Expense'));
      await tester.pumpAndSettle();

      expect(store.expenses, hasLength(1));
      expect(store.expenses.first.note, 'moto to school');
      expect(
        (await service.watchExpenses().first).map((e) => e.note),
        ['moto to school'],
      );
    });
  });
}
