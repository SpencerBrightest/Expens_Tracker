import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Category', () {
    test('round-trips through toMap/fromMap (Firestore shape)', () {
      final cat = Category(
        id: 'c1',
        name: 'Transport',
        monthlyLimit: 500,
        colorValue: 0xFF5D9CEC,
        iconCodePoint: Icons.directions_car_outlined.codePoint,
      );
      final map = cat.toMap();
      expect(map['name'], 'Transport');
      expect(map['monthlyLimit'], 500);

      final back = Category.fromMap('c1', map);
      expect(back, cat);
    });

    test('copyWith replaces only given fields', () {
      final cat = Category(
        id: 'c1',
        name: 'Food',
        monthlyLimit: 1000,
        colorValue: 0xFFFA5A36,
        iconCodePoint: 0xe318,
      );
      final changed = cat.copyWith(monthlyLimit: 1200);
      expect(changed.monthlyLimit, 1200);
      expect(changed.name, 'Food');
    });

    test('rejects blank name and negative limit', () {
      expect(
        () => Category(
          id: 'c1',
          name: '  ',
          monthlyLimit: 100,
          colorValue: 0xFF2D68FE,
          iconCodePoint: 0xe318,
        ),
        throwsArgumentError,
      );
      expect(
        () => Category(
          id: 'c1',
          name: 'Food',
          monthlyLimit: -1,
          colorValue: 0xFF2D68FE,
          iconCodePoint: 0xe318,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Expense', () {
    test('round-trips through toMap/fromMap (Firestore shape)', () {
      final date = DateTime(2024, 11, 20, 14, 15);
      final exp = Expense(
        id: 'e1',
        amount: 5000,
        categoryId: 'c1',
        note: 'moto to school',
        date: date,
        paymentMethod: 'Cash',
        summary: '5,000 XAF — Transport, moto to school',
      );
      final map = exp.toMap();
      expect(map['amount'], 5000);
      expect(map['categoryId'], 'c1');

      final back = Expense.fromMap('e1', map);
      expect(back, exp);
    });

    test('defaults summary to template when absent', () {
      final exp = Expense(
        id: 'e2',
        amount: 2500,
        categoryId: 'c2',
        note: 'bread',
        date: DateTime(2024, 11, 19),
      );
      expect(exp.effectiveSummary('Food'), '2500 XAF — Food, bread');
    });

    test('rejects non-positive amount', () {
      expect(
        () => Expense(
          id: 'e1',
          amount: 0,
          categoryId: 'c1',
          note: 'x',
          date: DateTime.now(),
        ),
        throwsArgumentError,
      );
    });
  });
}
