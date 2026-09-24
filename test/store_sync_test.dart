import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/expense_store.dart';
import 'package:expense_tracker/services/firestore_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Category _cat(String id) => Category(
      id: id,
      name: 'Name $id',
      monthlyLimit: 1000,
      colorValue: 0xFF2D68FE,
      iconCodePoint: 0xe318,
    );

Expense _exp(String id, double amount) => Expense(
      id: id,
      amount: amount,
      categoryId: 'c1',
      note: 'n',
      date: DateTime(2024, 11, 20),
    );

/// Test-only failing service: proves rollback without a backend.
class _FailingService extends FirestoreService {
  _FailingService()
      : super(db: FakeFirebaseFirestore(), uid: 'u-fail');

  @override
  Future<void> saveExpense(Expense expense) {
    throw StateError('offline');
  }
}

void main() {
  group('ExpenseStore remote sync', () {
    test('loadFromRemote pulls expenses and categories', () async {
      final svc = FirestoreService(
        db: FakeFirebaseFirestore(),
        uid: 'u1',
      );
      await svc.saveCategory(_cat('c1'));
      await svc.saveExpense(_exp('e1', 100));

      final store = ExpenseStore();
      await store.loadFromRemote(svc);

      expect(store.expenses.map((e) => e.id), ['e1']);
      expect(store.categories.map((c) => c.id), ['c1']);
    });

    test('persistExpense syncs local and remote', () async {
      final svc = FirestoreService(
        db: FakeFirebaseFirestore(),
        uid: 'u1',
      );
      final store = ExpenseStore(categories: [_cat('c1')]);
      await store.persistExpense(svc, _exp('e1', 250));

      expect(store.expenses.map((e) => e.id), ['e1']);
      expect(
        (await svc.watchExpenses().first).map((e) => e.id),
        ['e1'],
      );
    });

    test('persistExpense rolls back locally when remote fails',
        () async {
      final store = ExpenseStore(categories: [_cat('c1')]);
      await expectLater(
        store.persistExpense(_FailingService(), _exp('e1', 250)),
        throwsStateError,
      );
      expect(store.expenses, isEmpty);
    });

    test('deleteExpenseRemote removes local and remote', () async {
      final svc = FirestoreService(
        db: FakeFirebaseFirestore(),
        uid: 'u1',
      );
      final store = ExpenseStore(categories: [_cat('c1')]);
      await store.persistExpense(svc, _exp('e1', 250));
      await store.deleteExpenseRemote(svc, 'e1');

      expect(store.expenses, isEmpty);
      expect(await svc.watchExpenses().first, isEmpty);
    });
  });
}
