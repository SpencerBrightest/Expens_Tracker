import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

/// Thrown when the user backs out of an interactive flow (e.g. dismisses
/// the Google account picker). Screens must stay silent on this.
class AuthCancelledException implements Exception {
  const AuthCancelledException();
}

/// Backend contract. Production uses [FirebaseAuthBackend]; tests use a
/// fake. This is the ONLY file that may import firebase_auth or
/// google_sign_in.
abstract class AuthBackend {
  Stream<NdohUser?> authStateChanges();
  NdohUser? get currentUser;
  Future<NdohUser> signIn(String email, String password);
  Future<NdohUser> signUp(String email, String password);
  Future<NdohUser> signInWithGoogle();
  Future<void> startPhoneSignIn({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
  });
  Future<NdohUser> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  });
  Future<void> signOut();
}

NdohUser _toUser(User u) =>
    NdohUser(uid: u.uid, email: u.email ?? '');

/// Thin wrapper over the GoogleSignIn singleton (initialize-once rule).
/// Injectable for tests via [FirebaseAuthBackend].
class GoogleSignInFlow {
  GoogleSignInFlow();

  bool _ready = false;

  Future<GoogleSignInAccount> call() async {
    if (!_ready) {
      await GoogleSignIn.instance.initialize();
      _ready = true;
    }
    return GoogleSignIn.instance.authenticate();
  }

  Future<void> signOut() async {
    if (!_ready) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Best effort: Firebase sign-out already happened.
    }
  }
}

class FirebaseAuthBackend implements AuthBackend {
  FirebaseAuthBackend([FirebaseAuth? auth, GoogleSignInFlow? googleFlow])
      : _auth = auth ?? FirebaseAuth.instance,
        _googleFlow = googleFlow ?? GoogleSignInFlow();

  final FirebaseAuth _auth;
  final GoogleSignInFlow _googleFlow;

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
  Future<NdohUser> signInWithGoogle() async {
    GoogleSignInAccount account;
    try {
      account = await _googleFlow();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelledException();
      }
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google sign-in returned no ID token');
    }
    final cred = await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
    return _toUser(cred.user!);
  }

  @override
  Future<void> startPhoneSignIn({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
  }) async {
    if (phone.trim().isEmpty) {
      throw ArgumentError('Phone number must not be blank');
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: phone.trim(),
      verificationCompleted: (PhoneAuthCredential cred) async {
        // Auto-verified (Android instant verification): the
        // authStateChanges stream notifies listeners downstream.
        try {
          await _auth.signInWithCredential(cred);
        } catch (_) {
          // Stream stays signed-out; user can enter the code manually.
        }
      },
      verificationFailed: (FirebaseAuthException e) =>
          onError(e.message ?? e.code),
      codeSent: (String verificationId, int? _) =>
          onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  @override
  Future<NdohUser> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    if (verificationId.trim().isEmpty || smsCode.trim().isEmpty) {
      throw ArgumentError(
        'Verification ID and SMS code must not be blank',
      );
    }
    final cred = await _auth.signInWithCredential(
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      ),
    );
    return _toUser(cred.user!);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleFlow.signOut();
  }
}

/// Entry point for screens. Validates input, delegates to the backend.
/// Forwards backend auth-state events to listeners so providers derived
/// from [currentUser] (e.g. per-user Firestore) stay fresh even when the
/// change originates outside this service (auto phone verification,
/// token refresh, other devices).
class AuthService extends ChangeNotifier {
  AuthService({AuthBackend? backend})
      : _backend = backend ?? FirebaseAuthBackend() {
    _sub = _backend.authStateChanges().listen((_) => notifyListeners());
  }

  final AuthBackend _backend;
  late final StreamSubscription<NdohUser?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Stream<NdohUser?> get authStateChanges => _backend.authStateChanges();
  NdohUser? get currentUser => _backend.currentUser;

  static void _check(String email, String password) {
    if (email.trim().isEmpty) {
      throw ArgumentError('Email must not be blank');
    }
    if (password.trim().isEmpty) {
      throw ArgumentError('Password must not be blank');
    }
    if (password.trim().length < 6) {
      throw ArgumentError('Password must be at least 6 characters');
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

  Future<NdohUser> signInWithGoogle() async {
    final user = await _backend.signInWithGoogle();
    notifyListeners();
    return user;
  }

  Future<void> startPhoneSignIn({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
  }) async {
    if (phone.trim().isEmpty) {
      throw ArgumentError('Phone number must not be blank');
    }
    await _backend.startPhoneSignIn(
      phone: phone.trim(),
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }

  Future<NdohUser> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    if (verificationId.trim().isEmpty || smsCode.trim().isEmpty) {
      throw ArgumentError(
        'Verification ID and SMS code must not be blank',
      );
    }
    final user = await _backend.confirmPhoneCode(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    notifyListeners();
    return user;
  }

  Future<void> signOut() async {
    await _backend.signOut();
    notifyListeners();
  }
}
