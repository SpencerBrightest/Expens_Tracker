# Ndoh Expense Tracker

## Run

Firebase is initialized from the generated `lib/firebase_options.dart`.
Signed-out users are sent to Login; expenses are saved under the signed-in
user's Firestore account.

```powershell
flutter run
```

## AI note cleanup (server-side proxy)

Long expense notes (>120 chars) are cleaned through the authenticated Cloud
Function `getGeminiSummary` (`functions/src/index.ts`, region
`us-central1`), which holds the Gemini key as a Functions secret. The Flutter
client never embeds an API key — `ProxyLlmBackend` sends only the note plus
the Firebase ID token. Short notes use the instant template summary
`"<amount> XAF — <Category>, <note>"`.

Deploy backend changes with:

```powershell
firebase deploy --only firestore:rules,functions
```

The Gemini secret itself is set out-of-band and never committed:

```powershell
firebase functions:secrets:set GEMINI_API_KEY
```
