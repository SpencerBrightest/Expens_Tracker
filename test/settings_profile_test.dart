import 'package:expense_tracker/providers/expense_store.dart';
import 'package:expense_tracker/screens/settings_screen.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

Widget _withAuth(AuthService auth) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthService>.value(value: auth),
      ChangeNotifierProvider<ExpenseStore>(create: (_) => ExpenseStore()),
      ChangeNotifierProvider<NotificationService>(
        create: (_) => NotificationService(backend: FakeNotificationBackend()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: SettingsScreen()),
    ),
  );
}

void main() {
  group('Settings edit profile', () {
    testWidgets('renames the signed-in user and updates the tile', (
      tester,
    ) async {
      final backend = FakeAuthBackend();
      final auth = AuthService(backend: backend);
      await auth.signIn('a@x.com', 'secret123');
      await tester.pumpWidget(_withAuth(auth));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      expect(find.text('Edit profile'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Jamila Bright');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Profile updated'), findsOneWidget);
      expect(find.text('Jamila Bright'), findsOneWidget);
      expect(auth.currentUser?.displayName, 'Jamila Bright');
      backend.dispose();
    });

    testWidgets('blank name surfaces the validation error', (tester) async {
      final backend = FakeAuthBackend();
      final auth = AuthService(backend: backend);
      await auth.signIn('a@x.com', 'secret123');
      await tester.pumpWidget(_withAuth(auth));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not update profile'), findsOneWidget);
      expect(auth.currentUser?.displayName, isNull);
      backend.dispose();
    });

    testWidgets('cancel keeps the existing name', (tester) async {
      final backend = FakeAuthBackend();
      final auth = AuthService(backend: backend);
      await auth.signIn('a@x.com', 'secret123');
      await tester.pumpWidget(_withAuth(auth));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Someone Else');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Edit profile'), findsNothing);
      expect(auth.currentUser?.displayName, isNull);
      backend.dispose();
    });
  });
}
