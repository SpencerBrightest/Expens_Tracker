# CLAUDE.md — Ndoh Expense Tracker

> Mirrors AGENTS.md. Claude Code: auto-load the specs below.

@AGENTS.md
@context/project-overview.md
@context/architecture.md
@context/build-plan.md
@context/progress-tracker.md
@context/ui-tokens.md
@context/ui-rules.md

## Quick orient
Ndoh is a Flutter expense tracker (Provider, fl_chart, Firebase Auth +
Firestore, flutter_local_notifications, intl). Build in order: Static UI ->
Models -> Provider state -> Charts -> Firebase Auth (`authStateChanges()` gate)
-> Firestore (`users/{uid}/expenses/{id}`) -> Notifications -> AI touches last.

Critical: flat colors only (no gradients), palette only from
`lib/theme/app_colors.dart` (primary `#2D68FE`, bg `#F8F9FD`), XAF everywhere
via `intl`, screens never import firebase packages directly, splash has 3-dot
450ms animation, Gemini key via `--dart-define`/`.env` never committed.
