import 'package:expense_tracker/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('NotificationService', () {
    test('init delegates once', () async {
      final backend = FakeNotificationBackend();
      final service = NotificationService(backend: backend);
      await service.init();
      await service.init();
      expect(backend.initialized, isTrue);
    });

    test('daily reminder schedules and cancels', () async {
      final backend = FakeNotificationBackend();
      final service = NotificationService(backend: backend);
      await service.setDailyReminder(true);
      expect(service.dailyReminder, isTrue);
      expect(backend.scheduledDaily, hasLength(1));
      expect(backend.scheduledDaily.first.hour, 20);

      await service.setDailyReminder(false);
      expect(service.dailyReminder, isFalse);
      expect(backend.cancelled, contains(1));
    });

    test('no budget alert below 80%', () async {
      final backend = FakeNotificationBackend();
      final service = NotificationService(backend: backend);
      final shown = await service.budgetAlertIfNeeded(
        categoryName: 'Food',
        spent: 79,
        limit: 100,
      );
      expect(shown, isFalse);
      expect(backend.shown, isEmpty);
    });

    test('warning at 80% and exceeded at 100%', () async {
      final backend = FakeNotificationBackend();
      final service = NotificationService(backend: backend);

      expect(
        await service.budgetAlertIfNeeded(
          categoryName: 'Food',
          spent: 85,
          limit: 100,
        ),
        isTrue,
      );
      expect(backend.shown.single.title, contains('% of budget'));

      expect(
        await service.budgetAlertIfNeeded(
          categoryName: 'Food',
          spent: 120,
          limit: 100,
        ),
        isTrue,
      );
      expect(backend.shown.last.title, contains('exceeded'));
    });

    test('alerts suppressed when disabled', () async {
      final backend = FakeNotificationBackend();
      final service = NotificationService(backend: backend);
      service.budgetAlerts = false;
      expect(
        await service.budgetAlertIfNeeded(
          categoryName: 'Food',
          spent: 200,
          limit: 100,
        ),
        isFalse,
      );
      expect(backend.shown, isEmpty);
    });

    test('zero limit never alerts', () async {
      final backend = FakeNotificationBackend();
      final service = NotificationService(backend: backend);
      expect(
        await service.budgetAlertIfNeeded(
          categoryName: 'Food',
          spent: 50,
          limit: 0,
        ),
        isFalse,
      );
      expect(backend.shown, isEmpty);
    });
  });
}
