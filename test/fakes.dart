import 'dart:async';

import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/notification_service.dart';

/// Shared test fake. Keeps test doubles out of production code.
class FakeAuthBackend implements AuthBackend {
  FakeAuthBackend();
  NdohUser? _user;
  final _ctrl = StreamController<NdohUser?>.broadcast();

  @override
  Stream<NdohUser?> authStateChanges() async* {
    yield _user;
    yield* _ctrl.stream;
  }

  @override
  NdohUser? get currentUser => _user;

  @override
  Future<NdohUser> signIn(String email, String password) async {
    _user = NdohUser(uid: 'uid-in', email: email);
    _ctrl.add(_user);
    return _user!;
  }

  @override
  Future<NdohUser> signUp(String email, String password) async {
    _user = NdohUser(uid: 'uid-up', email: email);
    _ctrl.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _ctrl.add(null);
  }

  void dispose() => _ctrl.close();
}

/// Test-only recording notification backend.
class FakeNotificationBackend implements NotificationBackend {
  FakeNotificationBackend();
  bool initialized = false;
  final shown = <({int id, String title, String body})>[];
  final scheduledDaily = <({int id, int hour, int minute})>[];
  final cancelled = <int>[];

  @override
  Future<void> init() async => initialized = true;

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    shown.add((id: id, title: title, body: body));
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    scheduledDaily.add((id: id, hour: hour, minute: minute));
  }

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  Future<void> cancelAll() async {}
}
