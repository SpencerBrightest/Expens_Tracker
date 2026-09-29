# Ndoh Expense Tracker

## Run

Firebase is initialized from the generated `lib/firebase_options.dart`.
Signed-out users are sent to Login; expenses are saved under the signed-in
user's Firestore account.

To run with Gemini note cleanup enabled, put `GEMINI_API_KEY` in the ignored
root `.env` file and run:

```powershell
.\tool\run_flutter_with_env.ps1 run
```

Pass additional Flutter arguments after `run`, for example:

```powershell
.\tool\run_flutter_with_env.ps1 run -d chrome
```

Gemini cleanup is used only for expense notes longer than 120 characters; short
notes use the instant template summary. A Gemini key compiled into a client app
can be extracted, so production deployments should call Gemini through a
server-side endpoint instead.

# Ndoh Expense Tracker

## Run

Firebase is initialized from the generated `lib/firebase_options.dart`.
Signed-out users are sent to Login; expenses are saved under the signed-in
user's Firestore account.

To run with Gemini note cleanup enabled, put `GEMINI_API_KEY` in the ignored
root `.env` file and run:

```powershell
.\tool\run_flutter_with_env.ps1 run
```

Pass additional Flutter arguments after `run`, for example:

```powershell
.\tool\run_flutter_with_env.ps1 run -d chrome
```

Gemini cleanup is used only for expense notes longer than 120 characters; short
notes use the instant template summary. A Gemini key compiled into a client app
can be extracted, so production deployments should call Gemini through a
server-side endpoint instead.
