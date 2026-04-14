# HF Health Tracking App — Walkthrough

## What Was Built

A complete Flutter mobile app for personal health tracking, with Vietnamese UI. **28 Dart files** across 8 phases — from login to AI health reports.

### Architecture

```
hf_health/lib/
├── main.dart / app.dart          # Entry point + MaterialApp
├── config/                       # Theme, routes, health constants
├── models/                       # HealthRecord, UserModel, ChatMessage
├── services/                     # Auth, Firestore, Gemini AI, OCR, HealthAnalyzer
├── screens/                      # 12 screens (auth, home, input, scan, AI, history, profile)
└── widgets/                      # 3 shared widgets
```

### Key Features

| Feature | Files | Notes |
|---------|-------|-------|
| **Auth** | Login, Register screens + [AuthService](file:///home/doanchim/moi/hf_health/lib/services/auth_service.dart#4-75) | Firebase Auth with email/password |
| **Manual Input** | Blood test, Vitals, Body metrics forms | Real-time abnormal detection with color coding |
| **OCR Scan** | Camera → ML Kit → Auto-parse | Recognizes Vietnamese test results |
| **AI Analysis** | [GeminiService](file:///home/doanchim/moi/hf_health/lib/services/gemini_service.dart#6-177) chat + report | Context-aware with user's health history |
| **Dashboard** | Home with summary cards + charts | `fl_chart` for trend visualization |
| **History** | Chronological list with filtering | Expandable cards showing all indicators |

### Dependencies (pubspec.yaml)

`firebase_core`, `firebase_auth`, `cloud_firestore`, `google_mlkit_text_recognition`, `google_generative_ai`, `image_picker`, `camera`, `fl_chart`, `intl`, `provider`, `uuid`

---

## Fixes Applied During Verification

1. **[indicator_field.dart](file:///home/doanchim/moi/hf_health/lib/widgets/indicator_field.dart)** — moved from `screens/input/` to `widgets/` (shared by 3 input screens)
2. **[profile_screen.dart](file:///home/doanchim/moi/hf_health/lib/screens/profile/profile_screen.dart)** — fixed import path `../widgets/` → `../../widgets/`
3. **[pubspec.yaml](file:///home/doanchim/moi/hf_health/pubspec.yaml)** — removed invalid `Roboto-Regular.ttf` / `Roboto-Bold.ttf` font declarations (Material Design includes Roboto by default)
4. **[pubspec.yaml](file:///home/doanchim/moi/hf_health/pubspec.yaml)** — added missing `camera: ^0.11.0+2` dependency
5. **[assets/images/.gitkeep](file:///home/doanchim/moi/hf_health/assets/images/.gitkeep)** — created so the declared asset directory exists
6. **[analysis_options.yaml](file:///home/doanchim/moi/hf_health/analysis_options.yaml)** — created with `flutter_lints` include

---

## Remaining Setup (User Action Required)

### 1. Generate platform directories
```bash
cd ~/moi/hf_health
flutter create .
```
This generates `android/`, `ios/`, `web/`, etc.

### 2. Firebase configuration
- Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
- Enable **Authentication** (Email/Password)
- Enable **Cloud Firestore**
- Download `google-services.json` → `android/app/`
- Download `GoogleService-Info.plist` → `ios/Runner/`
- Uncomment `Firebase.initializeApp()` in [main.dart](file:///home/doanchim/moi/hf_health/lib/main.dart) (line 9)

### 3. Gemini API Key
- Get key from [aistudio.google.com](https://aistudio.google.com)
- Set in [lib/services/gemini_service.dart](file:///home/doanchim/moi/hf_health/lib/services/gemini_service.dart) line 7

### 4. Run
```bash
flutter pub get
flutter run
```
