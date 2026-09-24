import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/screens/auth_screen.dart';
import 'package:expense_tracker/screens/dashboard_shell.dart';
import 'package:expense_tracker/screens/homepage_screen.dart';
import 'package:expense_tracker/screens/splash_screen.dart';
import 'package:expense_tracker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.light(), home: child);
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

  testWidgets('NdohApp transitions Splash -> Homepage', (tester) async {
    await tester.pumpWidget(const NdohApp());
    expect(find.text('Ndoh'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await _reveal(tester, find.text('Get started'));
    expect(find.text('Get started'), findsOneWidget);
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
      MaterialApp(
        theme: AppTheme.light(),
        home: const HomepageScreen(),
        routes: {'/auth': (_) => const AuthScreen()},
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
