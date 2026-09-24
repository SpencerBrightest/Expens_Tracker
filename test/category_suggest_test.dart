import 'package:expense_tracker/ai/category_suggest.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/providers/expense_store.dart';
import 'package:expense_tracker/screens/add_edit_expense_screen.dart';
import 'package:expense_tracker/services/firestore_service.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

Category _cat(String id, String name) => Category(
      id: id,
      name: name,
      monthlyLimit: 1000,
      colorValue: 0xFF2D68FE,
      iconCodePoint: 0xe318,
    );

List<Category> _cats() => [
      _cat('c1', 'Housing'),
      _cat('c2', 'Food & Dining'),
      _cat('c3', 'Transport'),
      _cat('c4', 'Entertainment'),
    ];

void main() {
  group('suggestCategoryId', () {
    test('matches transport keywords', () {
      expect(suggestCategoryId('moto to school', _cats()), 'c3');
      expect(suggestCategoryId('Uber ride downtown', _cats()), 'c3');
      expect(suggestCategoryId('gas station fill up', _cats()), 'c3');
    });

    test('matches food keywords', () {
      expect(suggestCategoryId('grocery run', _cats()), 'c2');
      expect(suggestCategoryId('lunch with Ama', _cats()), 'c2');
    });

    test('category name in note wins', () {
      expect(suggestCategoryId('housing deposit', _cats()), 'c1');
    });

    test('returns null when nothing matches', () {
      expect(suggestCategoryId('xyz random thing', _cats()), isNull);
      expect(suggestCategoryId('  ', _cats()), isNull);
      expect(suggestCategoryId('note', []), isNull);
    });

    test('is case-insensitive', () {
      expect(suggestCategoryId('MOTO TAXI', _cats()), 'c3');
    });
  });

  group('Suggestion chip', () {
    testWidgets('appears after typing and applies on tap', (tester) async {
      final store = ExpenseStore(categories: [
        _cat('c1', 'Food'),
        _cat('c2', 'Transport'),
      ]);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ExpenseStore>.value(value: store),
            Provider<FirestoreService?>.value(value: null),
            ChangeNotifierProvider<NotificationService>(
              create: (_) =>
                  NotificationService(backend: FakeNotificationBackend()),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: AddEditExpenseScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Try Transport'), findsNothing);

      await tester.enterText(find.byType(TextField).last, 'moto to school');
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Try Transport'), findsOneWidget);

      await tester.tap(find.text('Try Transport'));
      await tester.pump();
      expect(find.text('Try Transport'), findsNothing);
      expect(find.text('Transport'), findsOneWidget);
    });
  });
}
