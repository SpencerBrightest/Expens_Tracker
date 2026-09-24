import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase-light user. Screens depend on this, never on firebase_auth.
@immutable
class NdohUser {
  const NdohUser({required this.uid, required this.email});

  final String uid;
  final String email;

  @override
  bool operator ==(Object other) =>
      other is NdohUser && other.uid == uid && other.email == email;

  @override
  int get hashCode => Object.hash(uid, email);
}

/// Backend contract. Production uses [FirebaseAuthBackend]; tests use a
/// fake. This is the ONLY file that may import firebase_auth.
abstract class AuthBackend {
  Stream<NdohUser?> authStateChanges();
  NdohUser? get currentUser;
  Future<NdohUser> signIn(String email, String password);
  Future<NdohUser> signUp(String email, String password);
  Future<void> signOut();
}

NdohUser _toUser(User u) =>
    NdohUser(uid: u.uid, email: u.email ?? '');

class FirebaseAuthBackend implements AuthBackend {
  FirebaseAuthBackend([FirebaseAuth? auth])
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<NdohUser?> authStateChanges() =>
      _auth.authStateChanges().map((u) => u == null ? null : _toUser(u));

  @override
  NdohUser? get currentUser {
    final u = _auth.currentUser;
    return u == null ? null : _toUser(u);
  }

  @override
  Future<NdohUser> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _toUser(cred.user!);
  }

  @override
  Future<NdohUser> signUp(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _toUser(cred.user!);
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

/// Entry point for screens. Validates input, delegates to the backend.
class AuthService extends ChangeNotifier {
  AuthService({AuthBackend? backend})
      : _backend = backend ?? FirebaseAuthBackend();

  final AuthBackend _backend;

  Stream<NdohUser?> get authStateChanges => _backend.authStateChanges();
  NdohUser? get currentUser => _backend.currentUser;

  static void _check(String email, String password) {
    if (email.trim().isEmpty) {
      throw ArgumentError('Email must not be blank');
    }
    if (password.trim().isEmpty) {
      throw ArgumentError('Password must not be blank');
    }
  }

  Future<NdohUser> signIn(String email, String password) async {
    _check(email, password);
    final user = await _backend.signIn(email.trim(), password);
    notifyListeners();
    return user;
  }

  Future<NdohUser> signUp(String email, String password) async {
    _check(email, password);
    final user = await _backend.signUp(email.trim(), password);
    notifyListeners();
    return user;
  }

  Future<void> signOut() async {
    await _backend.signOut();
    notifyListeners();
  }
}
