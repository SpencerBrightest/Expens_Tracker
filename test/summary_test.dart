import 'dart:convert';

import 'package:expense_tracker/ai/summary.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/expense_store.dart';
import 'package:expense_tracker/screens/add_edit_expense_screen.dart';
import 'package:expense_tracker/services/firestore_service.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/theme/app_theme.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
  date: DateTime(2026, 11, 20),
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

    group('Proxy HTTP transport (mocked)', () {
      test('sends bearer token and returns proxied summary', () async {
        String? seenAuth;
        Object? sentBody;
        final client = MockClient((req) async {
          seenAuth = req.headers['Authorization'];
          expect(req.headers['Content-Type'], contains('application/json'));
          sentBody = jsonDecode(req.body);
          return http.Response(
            jsonEncode({'summary': 'bulk grocery restock'}),
            200,
          );
        });
        final backend = ProxyLlmBackend(
          client: client,
          endpoint: Uri.parse('https://example.test/getGeminiSummary'),
          idTokenProvider: () async => 'tok123',
        );
        expect(
          await backend.cleanup('a very long messy note'),
          'bulk grocery restock',
        );
        expect(seenAuth, 'Bearer tok123');
        expect((sentBody as Map).toString(), contains('a very long messy'));
      });

      test('missing token returns input without network', () async {
        var called = false;
        final client = MockClient((_) async {
          called = true;
          return http.Response('{}', 200);
        });
        final backend = ProxyLlmBackend(
          client: client,
          endpoint: Uri.parse('https://example.test/getGeminiSummary'),
          idTokenProvider: () async => null,
        );
        expect(await backend.cleanup('keep me'), 'keep me');
        expect(called, isFalse);
      });

      test('non-200 response returns input', () async {
        final client = MockClient((_) async => http.Response('denied', 403));
        final backend = ProxyLlmBackend(
          client: client,
          endpoint: Uri.parse('https://example.test/getGeminiSummary'),
          idTokenProvider: () async => 'tok123',
        );
        expect(await backend.cleanup('keep me'), 'keep me');
      });

      test('malformed body returns input', () async {
        final client = MockClient(
          (_) async => http.Response(jsonEncode({'nope': []}), 200),
        );
        final backend = ProxyLlmBackend(
          client: client,
          endpoint: Uri.parse('https://example.test/getGeminiSummary'),
          idTokenProvider: () async => 'tok123',
        );
        expect(await backend.cleanup('keep me'), 'keep me');
      });
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
      final service = FirestoreService(db: FakeFirebaseFirestore(), uid: 'u1');
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ExpenseStore>.value(value: store),
            Provider<FirestoreService?>.value(value: service),
            ChangeNotifierProvider<NotificationService>(
              create: (_) =>
                  NotificationService(backend: FakeNotificationBackend()),
            ),
            Provider<SummaryService>.value(value: SummaryService(llm: llm)),
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
      expect(store.expenses.first.summary, '5000 XAF — Food, cleaned note');
    });
  });
}
