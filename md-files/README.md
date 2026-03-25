# 🏙️ HavenNYC

> Connecting people in need with community resources across New York City — built openly, for everyone.

HavenNYC is an open-source Flutter application that bridges the gap between New Yorkers in need and the community resources, volunteers, and neighbors that can help. It is designed with **true anonymity as the default**, a lightweight footprint, and broad OS compatibility so it reaches the widest possible audience.

---

## Table of Contents

- [Vision](#vision)
- [User Types](#user-types)
- [Feature Overview](#feature-overview)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Firebase Setup](#firebase-setup)
- [Environment & Config](#environment--config)
- [Flavors / Build Variants](#flavors--build-variants)
- [Contributing](#contributing)
- [Anonymity & Privacy Philosophy](#anonymity--privacy-philosophy)
- [Roadmap Summary](#roadmap-summary)
- [License](#license)

---

## Vision

New York City has an enormous network of social services, but that network is fragmented, hard to navigate, and often inaccessible to the people who need it most — especially those without a stable internet connection, a permanent address, or an English-speaking background. HavenNYC is a single, open, always-free access point to:

- Find nearby shelters, food, hygiene, medical, legal, and job resources on a live map
- Connect with neighbors who want to help
- Communicate peer-to-peer even without internet via Bluetooth mesh
- Discover volunteer and donation opportunities hyperlocal to each neighborhood

The app never requires an account to access resources. Anonymous use is the first-class experience.

---

## User Types

### 1. Person in Need (default / anonymous user)
Accesses the resource map and all survival tools. No sign-up required. Firebase Anonymous Auth is assigned silently in the background to enable optional features like saved locations and offline message queuing.

### 2. Community Partner / Helper
A neighbor, volunteer, or local organization that wants to contribute. Can browse volunteer slots, neighborhood projects, pantry supply needs, and sponsorship opportunities.

Both user types share the same app binary. The experience is shaped by the mode the user selects (or defaults to) on first launch.

---

## Feature Overview

### Priority 0 — Core (Must ship in v1.0)

| Feature | Notes |
|---|---|
| Anonymous authentication | Firebase Anonymous Auth, no PII collected by default |
| Explorable resource map | Grouped by neighborhood/borough, filterable by category |
| Resource detail sheets | Links, hours, address, navigation, available beds where applicable |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Android & iOS support | Target Android 6+ and iOS 13+ |

### Priority 1 — Important (Target v1.1)

| Feature | Notes |
|---|---|
| Optional persistent account | Sign-in via phone/email OTP or Google — links anonymous UID to real account so data persists across device switches |
| Web support | Flutter Web build served via Firebase Hosting |
| Bluetooth mesh messaging | flutter_blue_plus + custom relay protocol for offline P2P |
| Job listings | Curated feed of free job training + employment resources |
| Settings screen | Display scale (reads OS accessibility setting), theme, mode switching |

### Priority 2 — Enhanced (Target v1.2+)

| Feature | Notes |
|---|---|
| AI chatbot | Navigation assistant using a lightweight model (e.g. Gemini free tier or OpenAI free tier) |
| Offline city map | Tile caching via flutter_map + mbtiles or cached_network_image tiles |
| Multilingual support | English, Spanish, Mandarin Chinese, Russian, Bengali (top 5 NYC languages) |
| Neighborhood community fund | Micro-fundraising per neighborhood for non-commercial mutual aid |
| Volunteer opportunity match | Partner posts + user location/interest matching |
| Local business sponsorship | Businesses can fund resource listings or donate supplies |

---

## Tech Stack

| Layer | Technology | Reason |
|---|---|---|
| UI Framework | Flutter (Dart) | Single codebase for Android, iOS, Web |
| Auth | Firebase Anonymous Auth + optional OTP/Google Sign-In | Zero-friction entry, optional identity persistence |
| Database | Cloud Firestore | Real-time, offline-first, free tier is generous |
| Storage | Firebase Storage | Images/docs for resource listings |
| Push Notifications | Firebase Cloud Messaging (FCM) | Free, works on Android + iOS + Web |
| Map | flutter_map + OpenStreetMap tiles | Free, no API billing surprise |
| Offline Messaging | flutter_blue_plus | BLE-based P2P relay, no internet required |
| Localization | Flutter's built-in `intl` + ARB files | No third-party cost |
| State Management | Riverpod | Lightweight, testable, no boilerplate |
| Navigation | go_router | Deep-link friendly, web compatible |

> **Cost philosophy:** Every technology choice targets the free tier. Firebase Spark plan supports this app's expected scale for community use. OpenStreetMap requires attribution, not payment. No paid APIs are used in the critical path.

---

## Project Structure

```
havennyc/
├── lib/
│   ├── main.dart
│   ├── app.dart                    # App root, theme, routing
│   ├── core/
│   │   ├── constants/              # App-wide constants, category enums
│   │   ├── theme/                  # Color, text, component themes
│   │   ├── utils/                  # Formatters, geo helpers
│   │   └── services/
│   │       ├── auth_service.dart
│   │       ├── firestore_service.dart
│   │       ├── notification_service.dart
│   │       └── ble_mesh_service.dart
│   ├── features/
│   │   ├── onboarding/             # Anonymous entry, mode selection
│   │   ├── map/                    # Resource map, filters, clusters
│   │   ├── resource_detail/        # Detail sheets per resource type
│   │   ├── messaging/              # BLE mesh chat
│   │   ├── jobs/                   # Job listings
│   │   ├── community/              # Neighborhood funds, volunteering
│   │   ├── account/                # Optional auth upgrade, profile
│   │   ├── notifications/          # FCM handling, notification list
│   │   ├── settings/               # Accessibility, language, theme
│   │   └── chatbot/                # AI assistant (P2)
│   └── shared/
│       ├── widgets/                # Reusable UI components
│       ├── models/                 # Data models
│       └── providers/              # Riverpod providers
├── assets/
│   ├── icons/
│   ├── images/
│   └── l10n/                       # ARB localization files
├── test/
├── android/
├── ios/
├── web/
├── firebase.json
├── firestore.rules
├── firestore.indexes.json
└── pubspec.yaml
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.16.0` (stable channel)
- Dart SDK `>=3.2.0`
- Android Studio or Xcode (for mobile builds)
- Firebase CLI: `npm install -g firebase-tools`
- A Firebase project (see [Firebase Setup](#firebase-setup))

### Installation

```bash
git clone https://github.com/your-org/havennyc.git
cd havennyc
flutter pub get
```

### Running

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web (dev)
flutter run -d chrome
```

---

## Firebase Setup

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and create a project named `havennyc`
2. Enable the following services:
   - **Authentication** → Enable Anonymous provider; optionally enable Phone and Google
   - **Firestore Database** → Start in production mode, apply rules from `firestore.rules`
   - **Storage** → Default bucket, apply rules from `storage.rules`
   - **Cloud Messaging** → No extra config needed; download config files
3. Download `google-services.json` → place in `android/app/`
4. Download `GoogleService-Info.plist` → place in `ios/Runner/`
5. For web, copy the Firebase config object into `web/index.html` or use `firebase_options.dart` generated by FlutterFire CLI

```bash
# Use FlutterFire CLI to auto-generate firebase_options.dart
dart pub global activate flutterfire_cli
flutterfire configure
```

---

## Environment & Config

Create a `.env` file at the project root (gitignored):

```
# Only needed if using the optional chatbot (P2)
GEMINI_API_KEY=your_key_here
```

All Firebase config is handled via `firebase_options.dart` (generated, gitignored).
Never commit API keys. Use `flutter_dotenv` to load `.env` at runtime.

---

## Flavors / Build Variants

Two flavors are planned:

| Flavor | Purpose |
|---|---|
| `development` | Debug, points to Firestore emulator |
| `production` | Release, points to live Firebase project |

```bash
flutter run --flavor development -t lib/main_dev.dart
flutter run --flavor production -t lib/main_prod.dart
```

---

## Anonymity & Privacy Philosophy

HavenNYC is built on the principle that **needing help should never require giving up your identity.**

- On first launch, Firebase Anonymous Authentication silently creates a temporary UID. No name, email, or phone is ever collected unless the user explicitly upgrades their account.
- Anonymous UIDs are used only to scope Firestore documents (saved resources, message queues) to that session.
- No analytics SDK is included by default. If analytics are ever added, they must be opt-in, aggregated, and clearly disclosed.
- Location data is used only on-device for map centering. It is never sent to Firestore or any third-party service.
- BLE mesh messages are end-to-end scoped to the local mesh and are never routed through any server.

See `PRIVACY.md` for the full data handling policy.

---

## Roadmap Summary

```
v1.0  ── P0 features: anonymous auth, resource map, notifications, Android/iOS
v1.1  ── P1 features: persistent accounts, web, BLE mesh, jobs, settings
v1.2  ── P2 features: chatbot, offline maps, multilingual, community fund, volunteering
```

---

## Contributing

HavenNYC is open source and welcomes contributions from developers, designers, social workers, and community organizations. See `CONTRIBUTING.md` for guidelines.

Please read the `CODE_OF_CONDUCT.md` before participating. This project is explicitly built for vulnerable populations — respectful, thoughtful contributions only.

---

## License

MIT License. See `LICENSE` for details.
