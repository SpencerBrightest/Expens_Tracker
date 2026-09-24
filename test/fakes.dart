import 'dart:async';

import 'package:expense_tracker/services/auth_service.dart';

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
