import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/providers/expense_store.dart';
import 'package:expense_tracker/screens/auth_screen.dart';
import 'package:expense_tracker/screens/dashboard_shell.dart';
import 'package:expense_tracker/screens/homepage_screen.dart';
import 'package:expense_tracker/screens/splash_screen.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

/// Test wrapper: mirrors NdohApp providers with fakes (no Firebase).
Widget _wrap(Widget child, {FakeAuthBackend? backend}) {
  final b = backend ?? FakeAuthBackend();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ExpenseStore>(
        create: (_) => ExpenseStore(),
      ),
      ChangeNotifierProvider<AuthService>(
        create: (_) => AuthService(backend: b),
        // Owned fakes leak their broadcast controller; tests are
        // short-lived so this is acceptable (matches other suites).
      ),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: child),
  );
}

Future<void> _reveal(
  WidgetTester tester,
  Finder target, {
  Finder? scrollable,
}) async {
  await tester.scrollUntilVisible(
    target,
    500,
    scrollable: scrollable ?? find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Splash shows Ndoh + dots', (tester) async {
    await tester.pumpWidget(_wrap(const SplashScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Ndoh'), findsOneWidget);
    expect(find.text('SMART EXPENSE TRACKER'), findsOneWidget);
    // Advance past periodic ticks then dispose cleanly.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('NdohApp boots to Splash then Homepage (signed out)',
      (tester) async {
    final backend = FakeAuthBackend();
    await tester.pumpWidget(
      NdohApp(
        store: ExpenseStore(),
        authService: AuthService(backend: backend),
      ),
    );
    expect(find.text('Ndoh'), findsOneWidget);
    await tester.pumpAndSettle();
    await _reveal(tester, find.text('Get started'));
    expect(find.text('Get started'), findsOneWidget);
    backend.dispose();
  });

  testWidgets('Homepage shows Get started + XAF total', (tester) async {
    await tester.pumpWidget(_wrap(const HomepageScreen()));
    await tester.pumpAndSettle();
    // XAF total card is at top (built before scrolling down).
    expect(find.textContaining('XAF'), findsWidgets);
    await _reveal(tester, find.text('Get started'));
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('Homepage CTA navigates to Auth', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ExpenseStore>(
            create: (_) => ExpenseStore(),
          ),
          ChangeNotifierProvider<AuthService>(
            create: (_) => AuthService(backend: FakeAuthBackend()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const HomepageScreen(),
          routes: {'/auth': (_) => const AuthScreen()},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _reveal(tester, find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Login & Sign Up'), findsOneWidget);
  });

  testWidgets('Auth toggles Login/Signup', (tester) async {
    await tester.pumpWidget(_wrap(const AuthScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('Sign up').first);
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);
  });

  testWidgets('Auth submit signs in and opens Dashboard', (tester) async {
    final backend = FakeAuthBackend();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ExpenseStore>(
            create: (_) => ExpenseStore(),
          ),
          ChangeNotifierProvider<AuthService>(
            create: (_) => AuthService(backend: backend),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AuthScreen(),
          routes: {'/dashboard': (_) => const DashboardShell()},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final loginBtn = find.widgetWithText(FilledButton, 'Log in');
    await tester.scrollUntilVisible(
      loginBtn,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();
    expect(find.text('Top Categories'), findsOneWidget);
    expect(backend.currentUser?.email, 'alex.j@example.com');
    backend.dispose();
  });

  testWidgets('Dashboard shell has 5 tabs + FAB', (tester) async {
    await tester.pumpWidget(_wrap(const DashboardShell()));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
