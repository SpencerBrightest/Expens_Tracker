import 'dart:typed_data';

import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/services/expense_report_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseReportService', () {
    test('builds a hierarchical 300-word narrative from the expense data', () {
      final expense = Expense(
        id: 'exp-1',
        amount: 5000,
        categoryId: 'food',
        note: 'Lunch with the team and business discussion around growth planning.',
        subcategory: 'Team meals',
        date: DateTime(2026, 10, 3),
      );

      final report = ExpenseReportService().generateNarrative(
        expense: expense,
        categoryName: 'Food & Dining',
      );

      expect(report, contains('Expense Report'));
      expect(report, contains('Food & Dining'));
      expect(report, contains('Team meals'));
      expect(report.split(RegExp(r'\s+')).length, inInclusiveRange(260, 360));
    });

    test('creates PDF bytes for download', () async {
      final expense = Expense(
        id: 'exp-2',
        amount: 12500,
        categoryId: 'transport',
        note: 'Taxi to a client meeting and an airport transfer after the session.',
        subcategory: 'Airport transfer',
        date: DateTime(2026, 10, 4),
      );

      final bytes = await ExpenseReportService().buildPdfBytes(
        expense: expense,
        categoryName: 'Transport',
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(1000));
    });
  });
}
