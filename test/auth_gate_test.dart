import 'package:expense_tracker/providers/expense_store.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/widgets/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

Widget _withAuth(AuthService service, Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthService>.value(value: service),
      ChangeNotifierProvider<ExpenseStore>(
        create: (_) => ExpenseStore(),
      ),
    ],
    child: MaterialApp(theme: ThemeData(useMaterial3: true), home: child),
  );
}

void main() {
  group('AuthGate', () {
    testWidgets('shows Splash while waiting', (tester) async {
      final backend = FakeAuthBackend();
      final service = AuthService(backend: backend);
      await tester.pumpWidget(_withAuth(service, const AuthGate()));
      expect(find.text('Ndoh'), findsOneWidget);
      backend.dispose();
    });

    testWidgets('signed-out user sees Homepage', (tester) async {
      final backend = FakeAuthBackend();
      final service = AuthService(backend: backend);
      await tester.pumpWidget(_withAuth(service, const AuthGate()));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Get started'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Get started'), findsOneWidget);
      backend.dispose();
    });

    testWidgets('signed-in user sees Dashboard', (tester) async {
      final backend = FakeAuthBackend();
      final service = AuthService(backend: backend);
      await service.signUp('a@x.com', 'secret123');
      await tester.pumpWidget(_withAuth(service, const AuthGate()));
      await tester.pumpAndSettle();
      expect(find.text('Top Categories'), findsOneWidget);
      backend.dispose();
    });
  });
}
