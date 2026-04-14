# HF Health Tracking App - Implementation Plan

## Background & Motivation
Build a comprehensive Flutter mobile app for personal health tracking with a focus on ease of use, AI-driven insights (Gemini), and a visually appealing interface tailored for Vietnamese users.

## Scope & Impact
- **Auth**: Firebase Authentication (Email/Password).
- **Health Tracking**: Manual input for Blood test, Vitals, and Body metrics.
- **AI OCR**: Extract health data from printed lab reports using Google ML Kit.
- **AI Analysis**: Context-aware health reports and chat using Gemini AI.
- **Dashboard**: Data visualization with charts and summary cards.
- **History**: Chronological health records management.
- **Language**: Full Vietnamese support.

## Technical Architecture
- **Framework**: Flutter (Dart 3).
- **Design System**: Material Design 3.
- **State Management**: Provider (as suggested in walkthrough).
- **Backend**: Firebase (Auth, Firestore).
- **AI**: Google Generative AI (Gemini), Google ML Kit (OCR).
- **Charts**: `fl_chart`.

## Implementation Plan

### Phase 1: Project Setup & Core Infrastructure
- [ ] Initialize Flutter project.
- [ ] Configure `pubspec.yaml` with all dependencies.
- [ ] Setup folder structure: `lib/config`, `lib/models`, `lib/services`, `lib/screens`, `lib/widgets`.
- [ ] Define Theme (Material 3) and Health Constants in `lib/config`.

### Phase 2: Models & Services
- [ ] Implement Data Models: `HealthRecord`, `UserModel`, `ChatMessage`.
- [ ] Implement `AuthService` (Firebase Auth).
- [ ] Implement `FirestoreService` (CRUD for records).
- [ ] Implement `GeminiService` (AI Chat & Report).
- [ ] Implement `OCRService` (ML Kit integration).

### Phase 3: Auth & Onboarding
- [ ] Login Screen.
- [ ] Registration Screen.
- [ ] Forgot Password / Password Reset.

### Phase 4: Core Layout & Dashboard
- [ ] Main Navigation (BottomNavigationBar).
- [ ] Home Screen (Dashboard with summary cards).
- [ ] Data visualization using `fl_chart`.

### Phase 5: Health Data Input
- [ ] Generic `IndicatorField` widget.
- [ ] Manual Input Screens: Blood Test, Vitals, Body Metrics.
- [ ] Real-time abnormal detection logic (color coding).

### Phase 6: OCR Scan Feature
- [ ] Camera Integration.
- [ ] Image picking and cropping.
- [ ] ML Kit text recognition and parsing logic for Vietnamese reports.

### Phase 7: AI Analysis & History
- [ ] AI Analysis Chat Screen.
- [ ] Health History List Screen.
- [ ] Record Detail View.

### Phase 8: Profile & Settings
- [ ] Profile Screen.
- [ ] User info editing.
- [ ] App settings (Logout, Dark mode).

## Verification & Testing
- [ ] Unit tests for health parsing logic.
- [ ] Widget tests for core components.
- [ ] Manual testing of Gemini AI responses.
- [ ] Verification of Firebase connectivity.

## Design System (Vietnamese)
- **Primary Color**: #2196F3 (Health Blue)
- **Warning Color**: #FF9800 (Amber)
- **Critical Color**: #F44336 (Red)
- **Normal Color**: #4CAF50 (Green)
- **Typography**: Roboto (Default for MD3, supports Vietnamese well).
