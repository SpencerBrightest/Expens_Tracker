# AGENTS.md — Ndoh Expense Tracker

## What this is
Ndoh is a personal expense-tracking Flutter app: spending tracking, categories,
charts, Firebase backend, notifications, plus lightweight AI touches on top of a
solid manual tracker.

## Build order (do not skip ahead)
1. Static UI — all screens, dummy data, full navigation wired
2. Models — Expense, Category
3. State — Provider/ChangeNotifier in-memory expense list
4. Charts — fl_chart wired to state
5. Firebase Auth — auth_service.dart, Login/Signup, auth-state gate
6. Firestore — real reads/writes scoped per user
7. Notifications — flutter_local_notifications
8. AI touches last — category-suggestion chip, summary builder, insight card

## Navigation flow
Splash -> Homepage (public marketing, NOT dashboard) -> Auth (Login/Signup toggle)
-> Dashboard shell (authenticated, bottom-nav: Home, Transactions, Categories,
Analytics, Settings) -> Add/Edit Expense modal via FAB.

## Critical rules
- App name: Ndoh everywhere.
- Flat colors only — no `LinearGradient` / `RadialGradient` anywhere.
- Palette exclusively from Stitch exports (`lib/theme/app_colors.dart`), never
  Flutter defaults. Core: primary `#2D68FE`, bg `#F8F9FD`, surface `#FFFFFF`,
  success `#2EC771`, expense `#FA5A36`, categorical `#FF6584/#FFB800/#6C5CE7/#5D9CEC`,
  text `#1A1D26/#8A92A6`, border `#EEF2F6`. Font: Plus Jakarta Sans.
- Currency: XAF everywhere via `intl`
  (`NumberFormat.currency(locale: 'fr_CM', name: 'XAF', symbol: 'XAF ')`).
- Screens/widgets NEVER import `firebase_auth` / `cloud_firestore` directly —
  always through `lib/services/auth_service.dart` / `firestore_service.dart`.
- Auth-gated navigation listens to `authStateChanges()`, never a one-time check.
- Firestore scoping: `users/{uid}/expenses/{id}`, `users/{uid}/categories/{id}`.
- Splash: Stitch reference layout + 3 large solid dots centered near bottom,
  animation in Flutter (Timer 450ms, scale 1.2/0.8, opacity 1/0.4).
- AI (Phase 8 only): keyword-match category chip (debounced), template summary
  by default (`"<amount> XAF — <Category>, <note>"`), real LLM only when note is
  long/messy, async never blocks Save; insight card one-liner above charts.
  Gemini key via `--dart-define` / `.env` (gitignored), never committed.
- Perf: cache category list in Provider, paginate with `limit()/startAfter()`,
  optimistic UI on save with rollback, debounce typing-triggered work.

## File structure
lib/main.dart, lib/theme/, lib/data/dummy_data.dart, lib/models/expense.dart,
category.dart, lib/screens/ (splash, homepage, auth, dashboard_shell, home_tab,
transactions, categories, analytics, settings, add_edit_expense), lib/services/
(auth, firestore, notification), lib/widgets/ (expense_tile, spending_pie_chart,
spending_trend_chart), firebase_options.dart (generated via flutterfire, Phase 5).

## Verification per task
`flutter analyze`, `flutter test`, `flutter run` manual walk
Splash->Homepage->Auth->5 tabs->FAB modal. Commit locally per checkpoint.
Never push without explicit user approval. Never force-push.
