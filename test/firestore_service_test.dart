import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/user_preferences.dart';
import 'package:expense_tracker/services/firestore_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Expense _exp(String id, double amount, DateTime date) => Expense(
  id: id,
  amount: amount,
  categoryId: 'c1',
  note: 'note $id',
  subcategory: 'subcategory $id',
  date: date,
  paymentMethod: 'Cash',
  summary: 'summary $id',
);

Category _cat(String id) => Category(
  id: id,
  name: 'Name $id',
  monthlyLimit: 1000,
  colorValue: 0xFF2D68FE,
  iconCodePoint: 0xe318,
);

void main() {
  group('FirestoreService expenses', () {
    test('save + watch round-trips newest-first', () async {
      final svc = FirestoreService(db: FakeFirebaseFirestore(), uid: 'u1');
      await svc.saveExpense(_exp('e1', 100, DateTime(2024, 11, 1)));
      await svc.saveExpense(_exp('e2', 200, DateTime(2024, 11, 2)));

      final list = await svc.watchExpenses().first;
      expect(list.map((e) => e.id).toList(), ['e2', 'e1']);
      expect(list.first.amount, 200);
      expect(list.first.subcategory, 'subcategory e2');
      expect(list.first.paymentMethod, 'Cash');
      expect(list.first.summary, 'summary e2');
    });

    test('data is scoped per user', () async {
      final db = FakeFirebaseFirestore();
      final a = FirestoreService(db: db, uid: 'uA');
      final b = FirestoreService(db: db, uid: 'uB');
      await a.saveExpense(_exp('e1', 100, DateTime(2024, 11, 1)));
      await b.saveExpense(_exp('e9', 999, DateTime(2024, 11, 1)));

      expect((await a.watchExpenses().first).map((e) => e.id), ['e1']);
      expect((await b.watchExpenses().first).map((e) => e.id), ['e9']);
    });

    test('saveExpense overwrites the same id', () async {
      final svc = FirestoreService(db: FakeFirebaseFirestore(), uid: 'u1');
      await svc.saveExpense(_exp('e1', 100, DateTime(2024, 11, 1)));
      await svc.saveExpense(_exp('e1', 400, DateTime(2024, 11, 1)));
      final list = await svc.watchExpenses().first;
      expect(list, hasLength(1));
      expect(list.first.amount, 400);
    });

    test('deleteExpense removes the doc', () async {
      final svc = FirestoreService(db: FakeFirebaseFirestore(), uid: 'u1');
      await svc.saveExpense(_exp('e1', 100, DateTime(2024, 11, 1)));
      await svc.deleteExpense('e1');
      expect(await svc.watchExpenses().first, isEmpty);
    });

    test('fetchExpensesPage paginates with limit/startAfter', () async {
      final svc = FirestoreService(db: FakeFirebaseFirestore(), uid: 'u1');
      for (var i = 1; i <= 5; i++) {
        await svc.saveExpense(_exp('e$i', i * 10.0, DateTime(2024, 11, i)));
      }
      final p1 = await svc.fetchExpensesPage(limit: 2);
      expect(p1.expenses.map((e) => e.id).toList(), ['e5', 'e4']);

      final p2 = await svc.fetchExpensesPage(limit: 2, startAfter: p1.lastDoc);
      expect(p2.expenses.map((e) => e.id).toList(), ['e3', 'e2']);

      final p3 = await svc.fetchExpensesPage(limit: 2, startAfter: p2.lastDoc);
      expect(p3.expenses.map((e) => e.id).toList(), ['e1']);

      final p4 = await svc.fetchExpensesPage(limit: 2, startAfter: p3.lastDoc);
      expect(p4.expenses, isEmpty);
      expect(p4.lastDoc, isNull);
    });
  });

  group('FirestoreService user profile', () {
    test(
      'saves profile and preferences while preserving creation time',
      () async {
        final db = FakeFirebaseFirestore();
        final svc = FirestoreService(db: db, uid: 'u1');
        await svc.saveUserProfile(
          email: 'user@example.com',
          displayName: 'User Name',
        );
        final first = await db.collection('users').doc('u1').get();
        final createdAt = first.data()!['createdAt'];
        expect(first.data()!['uid'], 'u1');
        expect(first.data()!['email'], 'user@example.com');
        expect(first.data()!['displayName'], 'User Name');

        await svc.saveUserProfile(
          email: 'updated@example.com',
          displayName: 'Updated Name',
        );
        const preferences = UserPreferences(
          dailyReminder: true,
          budgetAlerts: false,
        );
        await svc.saveUserPreferences(preferences);

        final updated = await db.collection('users').doc('u1').get();
        expect(updated.data()!['createdAt'], createdAt);
        expect(updated.data()!['email'], 'updated@example.com');
        expect(updated.data()!['displayName'], 'Updated Name');
        expect(await svc.loadUserPreferences(), preferences);
      },
    );

    test('profiles are isolated by user id', () async {
      final db = FakeFirebaseFirestore();
      final first = FirestoreService(db: db, uid: 'u1');
      final second = FirestoreService(db: db, uid: 'u2');
      await first.saveUserProfile(email: 'one@example.com', displayName: 'One');
      await second.saveUserProfile(
        email: 'two@example.com',
        displayName: 'Two',
      );

      expect(
        (await db.collection('users').doc('u1').get()).data()!['email'],
        'one@example.com',
      );
      expect(
        (await db.collection('users').doc('u2').get()).data()!['email'],
        'two@example.com',
      );
    });
  });

  group('FirestoreService categories', () {
    test('save + watch round-trips scoped per user', () async {
      final db = FakeFirebaseFirestore();
      final a = FirestoreService(db: db, uid: 'uA');
      final b = FirestoreService(db: db, uid: 'uB');
      await a.saveCategory(_cat('c1'));
      await b.saveCategory(_cat('c9'));

      final catsA = await a.watchCategories().first;
      expect(catsA.map((c) => c.id), ['c1']);
      final catsB = await b.watchCategories().first;
      expect(catsB.map((c) => c.id), ['c9']);
    });

    test('deleteCategory removes the doc', () async {
      final svc = FirestoreService(db: FakeFirebaseFirestore(), uid: 'u1');
      await svc.saveCategory(_cat('c1'));
      await svc.deleteCategory('c1');
      expect(await svc.watchCategories().first, isEmpty);
    });
  });
}
