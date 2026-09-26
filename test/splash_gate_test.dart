import 'package:expense_tracker/providers/expense_store.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/firestore_service.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/widgets/splash_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

Widget _withAuth(AuthService service) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthService>.value(value: service),
      ChangeNotifierProvider<ExpenseStore>(
        create: (_) => ExpenseStore(),
      ),
      ChangeNotifierProvider<NotificationService>(
        create: (_) =>
            NotificationService(backend: FakeNotificationBackend()),
      ),
      Provider<FirestoreService?>.value(value: null),
    ],
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const SplashGate(duration: Duration(milliseconds: 100)),
    ),
  );
}

void main() {
  group('SplashGate', () {
    testWidgets('shows custom splash first', (tester) async {
      final backend = FakeAuthBackend();
      final service = AuthService(backend: backend);
      await tester.pumpWidget(_withAuth(service));
      expect(find.text('Ndoh'), findsOneWidget);
      backend.dispose();
    });

    testWidgets('hands off to Homepage after duration (signed out)',
        (tester) async {
      final backend = FakeAuthBackend();
      final service = AuthService(backend: backend);
      await tester.pumpWidget(_withAuth(service));
      await tester.pump(const Duration(milliseconds: 100));
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
  });
}
