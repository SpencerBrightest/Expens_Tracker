import 'package:expense_tracker/ai/summary.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/expense_store.dart';
import 'package:expense_tracker/screens/add_edit_expense_screen.dart';
import 'package:expense_tracker/services/firestore_service.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

class FakeLlm implements LlmBackend {
  FakeLlm({this.cleaned = 'cleaned note', this.shouldThrow = false});
  final String cleaned;
  final bool shouldThrow;
  var calls = 0;

  @override
  Future<String> cleanup(String note) async {
    calls++;
    if (shouldThrow) throw StateError('llm down');
    return cleaned;
  }
}

Expense _exp(String note) => Expense(
      id: 'e1',
      amount: 5000,
      categoryId: 'c1',
      note: note,
      date: DateTime(2024, 11, 20),
    );

void main() {
  group('SummaryService', () {
    test('short note uses template without calling the LLM', () async {
      final llm = FakeLlm();
      final service = SummaryService(llm: llm);
      final summary = await service.summarize(
        expense: _exp('moto to school'),
        categoryName: 'Transport',
      );
      expect(summary, '5000 XAF — Transport, moto to school');
      expect(llm.calls, 0);
    });

    test('long note routes to the LLM', () async {
      final llm = FakeLlm(cleaned: 'bulk grocery restock');
      final service = SummaryService(llm: llm);
      final summary = await service.summarize(
        expense: _exp('a' * 150),
        categoryName: 'Food',
      );
      expect(llm.calls, 1);
      expect(summary, '5000 XAF — Food, bulk grocery restock');
    });

    test('LLM failure falls back to template', () async {
      final llm = FakeLlm(shouldThrow: true);
      final service = SummaryService(llm: llm);
      final note = 'b' * 150;
      final summary = await service.summarize(
        expense: _exp(note),
        categoryName: 'Food',
      );
      expect(summary, '5000 XAF — Food, $note');
    });

    test('Gemini backend without key returns input (no network)',
        () async {
      const backend = GeminiLlmBackend(apiKey: '');
      expect(await backend.cleanup('some note'), 'some note');
    });
  });

  group('AddEdit async summary patch', () {
    testWidgets('long note gets patched after save', (tester) async {
      final llm = FakeLlm(cleaned: 'cleaned note');
      final store = ExpenseStore(
        categories: [
          Category(
            id: 'c1',
            name: 'Food',
            monthlyLimit: 1000,
            colorValue: 0xFFFA5A36,
            iconCodePoint: 0xe318,
          ),
        ],
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ExpenseStore>.value(value: store),
            Provider<FirestoreService?>.value(value: null),
            ChangeNotifierProvider<NotificationService>(
              create: (_) =>
                  NotificationService(backend: FakeNotificationBackend()),
            ),
            Provider<SummaryService>.value(
              value: SummaryService(llm: llm),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: AddEditExpenseScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'x' * 150);
      await tester.pump();
      final saveBtn = find.text('Save Expense');
      await tester.scrollUntilVisible(
        saveBtn,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(llm.calls, 1);
      expect(store.expenses, hasLength(1));
      expect(
        store.expenses.first.summary,
        '5000 XAF — Food, cleaned note',
      );
    });
  });
}
