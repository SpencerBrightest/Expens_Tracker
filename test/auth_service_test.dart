import 'package:expense_tracker/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('AuthService', () {
    test('starts signed out', () {
      final backend = FakeAuthBackend();
      final service = AuthService(backend: backend);
      expect(service.currentUser, isNull);
      backend.dispose();
    });

    test('signUp exposes the new user', () async {
      final backend = FakeAuthBackend();
      final service = AuthService(backend: backend);
      final user = await service.signUp('a@x.com', 'secret123');
      expect(user.uid, 'uid-up');
      expect(service.currentUser?.email, 'a@x.com');
      backend.dispose();
    });

    test('signIn exposes the signed-in user', () async {
      final backend = FakeAuthBackend();
      final service = AuthService(backend: backend);
      final user = await service.signIn('a@x.com', 'secret123');
      expect(user.uid, 'uid-in');
      backend.dispose();
    });

    test('signOut clears the user', () async {
      final backend = FakeAuthBackend();
      final service = AuthService(backend: backend);
      await service.signUp('a@x.com', 'secret123');
      await service.signOut();
      expect(service.currentUser, isNull);
      backend.dispose();
    });

    test('authStateChanges emits null -> user -> null', () async {
      final backend = FakeAuthBackend();
      final service = AuthService(backend: backend);
      final seen = <NdohUser?>[];
      final sub = service.authStateChanges.listen(seen.add);
      await Future<void>.delayed(Duration.zero);
      await service.signUp('a@x.com', 'secret123');
      await Future<void>.delayed(Duration.zero);
      await service.signOut();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(seen.map((u) => u?.uid).toList(), [null, 'uid-up', null]);
      backend.dispose();
    });

    test('blank email/password throws ArgumentError', () async {
      final backend = FakeAuthBackend();
      final service = AuthService(backend: backend);
      expect(() => service.signIn('  ', 'secret123'),
          throwsArgumentError);
      expect(
          () => service.signIn('a@x.com', '  '), throwsArgumentError);
      expect(() => service.signUp('', 'secret123'), throwsArgumentError);
      backend.dispose();
    });
  });
}
