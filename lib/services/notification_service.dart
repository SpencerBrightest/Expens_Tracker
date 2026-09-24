import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Platform channel contract. Production uses [PluginNotificationBackend];
/// tests use a recording fake. This is the ONLY file that may import
/// flutter_local_notifications.
abstract class NotificationBackend {
  Future<void> init();
  Future<void> show({
    required int id,
    required String title,
    required String body,
  });
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  });
  Future<void> cancel(int id);
  Future<void> cancelAll();
}

class PluginNotificationBackend implements NotificationBackend {
  PluginNotificationBackend([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'ndoh_reminders';

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> init() async {
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {
      // Non-Android or older API: permission not required.
    }
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(_channelId, 'Reminders'),
  );

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) {
    return _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: at,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}

/// App-facing notifications: 8pm daily reminder + budget threshold alerts.
/// Screens use this — never the plugin directly.
class NotificationService extends ChangeNotifier {
  NotificationService({NotificationBackend? backend})
      : _backend = backend ?? PluginNotificationBackend();

  static const dailyReminderId = 1;
  static const budgetExceededId = 2;
  static const budgetWarningId = 3;

  final NotificationBackend _backend;
  bool _initialized = false;

  bool dailyReminder = false;
  bool budgetAlerts = true;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _backend.init();
  }

  Future<void> setDailyReminder(bool on) async {
    dailyReminder = on;
    notifyListeners();
    if (on) {
      await _backend.scheduleDaily(
        id: dailyReminderId,
        title: "Log today's expenses",
        body: 'Quick check-in: record your spending in Ndoh.',
        hour: 20,
        minute: 0,
      );
    } else {
      await _backend.cancel(dailyReminderId);
    }
  }

  void setBudgetAlerts(bool on) {
    budgetAlerts = on;
    notifyListeners();
  }

  /// Shows a threshold alert when [spent]/[limit] crosses 80%/100%.
  /// Returns true when an alert was shown.
  Future<bool> budgetAlertIfNeeded({
    required String categoryName,
    required double spent,
    required double limit,
  }) async {
    if (!budgetAlerts || limit <= 0) return false;
    final pct = spent / limit;
    if (pct >= 1) {
      await _backend.show(
        id: budgetExceededId,
        title: '$categoryName budget exceeded',
        body:
            'You spent ${spent.toInt()} of ${limit.toInt()} XAF on $categoryName.',
      );
      return true;
    }
    if (pct >= 0.8) {
      await _backend.show(
        id: budgetWarningId,
        title: '$categoryName at ${(pct * 100).round()}% of budget',
        body:
            '${(limit - spent).toInt()} XAF left for $categoryName this month.',
      );
      return true;
    }
    return false;
  }
}
