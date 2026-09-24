import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/expense_store.dart';
import 'package:expense_tracker/screens/transactions_screen.dart';
import 'package:expense_tracker/services/firestore_service.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/theme/app_theme.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

Future<FirestoreService> _seededService(int count) async {
  final svc = FirestoreService(db: FakeFirebaseFirestore(), uid: 'u1');
  await svc.saveCategory(
    Category(
      id: 'c1',
      name: 'Food',
      monthlyLimit: 10000,
      colorValue: 0xFFFA5A36,
      iconCodePoint: 0xe318,
    ),
  );
  for (var i = 1; i <= count; i++) {
    await svc.saveExpense(
      Expense(
        id: 'e$i',
        amount: i.toDouble(),
        categoryId: 'c1',
        // Zero-padded so each note is unique for finders.
        note: 'remote expense ${i.toString().padLeft(3, '0')}',
        date: DateTime(2024, 1, 1).add(Duration(days: i)),
      ),
    );
  }
  return svc;
}

Widget _withService(FirestoreService svc) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ExpenseStore>(
        create: (_) => ExpenseStore(
          categories: [
            Category(
              id: 'c1',
              name: 'Food',
              monthlyLimit: 10000,
              colorValue: 0xFFFA5A36,
              iconCodePoint: 0xe318,
            ),
          ],
        ),
      ),
      Provider<FirestoreService?>.value(value: svc),
      ChangeNotifierProvider<NotificationService>(
        create: (_) =>
            NotificationService(backend: FakeNotificationBackend()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: TransactionsScreen()),
    ),
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
  group('TransactionsScreen paging', () {
    testWidgets('loads first page and offers Load more', (tester) async {
      final svc = await _seededService(25);
      await tester.pumpWidget(_withService(svc));
      await tester.pumpAndSettle();

      // First page only: e25..e06 visible after scrolling, e01 not loaded.
      await _reveal(tester, find.text('remote expense 006'));
      expect(find.text('remote expense 006'), findsOneWidget);
      expect(find.text('remote expense 001'), findsNothing);
      expect(find.text('Load more'), findsOneWidget);
    });

    testWidgets('Load more appends next page then finishes', (tester) async {
      final svc = await _seededService(25);
      await tester.pumpWidget(_withService(svc));
      await tester.pumpAndSettle();

      await _reveal(tester, find.text('Load more'));
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();

      await _reveal(tester, find.text('remote expense 001'));
      expect(find.text('remote expense 001'), findsOneWidget);
      expect(find.text('Load more'), findsNothing);
      expect(find.text('End of recent history'), findsOneWidget);
    });
  });
}

