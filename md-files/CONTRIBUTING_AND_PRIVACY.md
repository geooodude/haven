# HavenNYC — Privacy Policy & Data Practices

*Last updated: see git history*

HavenNYC is built by and for the New York City community. We collect as little data as possible, and we never sell or share your data with third parties for commercial purposes.

---

## What We Collect

### If you use HavenNYC anonymously (the default)

- A randomly generated anonymous ID (Firebase Anonymous Auth UID) is created automatically. This is a string like `abc123xyz` — it contains no name, email, phone, or location.
- Your selected user type (Person in Need / Community Partner) is stored against this anonymous ID.
- Your saved resources and notification preferences are stored against this anonymous ID.
- **Your location is never stored or transmitted to our servers.** It is used only on your device to center the map and is discarded immediately after.

### If you upgrade to a persistent account

- If you choose to link your account with a phone number or Google account (optional), your phone number or Google email is stored by Firebase Authentication — a service by Google. HavenNYC's own database stores only your Firebase UID and the preferences listed above.
- You may delete your account at any time from Settings → Account → Delete Account.

### BLE Mesh Messaging

- Messages sent via Bluetooth mesh are transmitted device-to-device and are never routed through HavenNYC servers.
- When internet is available, undelivered messages may be temporarily queued in our Firebase database and are automatically deleted after 7 days.
[- Messages are identified by anonymous UIDs only. No names are attached.
]
---

## What We Do NOT Collect

- Your name
- Your address or location history
- Demographic information
- Browsing behavior or analytics (no analytics SDK is included by default)
- Any information about your housing status, health, or circumstances

---

## Third-Party Services

| Service | Purpose | Privacy Policy |
|---|---|---|
| Firebase (Google) | Authentication, database, notifications | https://firebase.google.com/support/privacy |
| OpenStreetMap | Map tiles | https://www.openstreetmap.org/privacy |
| Google AI (Gemini) | Optional chatbot — only if you use it | https://ai.google/static/documents/notebooklm-privacy-notice.pdf |

---

## Your Rights

- **Access:** You can request a copy of all data we hold for your UID.
- **Deletion:** You can delete your account and all associated data from Settings → Account → Delete Account.
- **Portability:** Your saved resources can be exported as a plain text list from Settings.

---

## Contact

If you have questions about this privacy policy, please open an issue on our GitHub repository.

---

# CONTRIBUTING.md

Thank you for considering a contribution to HavenNYC. This project exists to help some of New York City's most vulnerable residents. Every contribution — whether code, translation, resource data, or documentation — matters.

---

## Code of Conduct

Be kind. This project is built for people who are going through difficult circumstances. Contributors are expected to bring that same humanity to their interactions in issues, pull requests, and discussions.

Specifically:
- No dismissive language about people in poverty, homelessness, mental illness, or immigration status
- No debate about whether certain resource categories (LGBTQ+ support, immigration legal aid, etc.) should be included — they should, and they are
- Respect the technical decisions of the solo maintainer; suggest, don't demand

---

## How to Contribute

### Resource Data
The most valuable contribution is keeping the resource database accurate. If you know of a shelter, pantry, clinic, or service that should be listed (or updated), please:
1. Open an issue with the label `resource-data`
2. Include: organization name, address, phone, website, hours, and category
3. All submitted resources are verified before being added

### Translations
We need professional or fluent translations for Spanish, Mandarin Chinese, Russian, and Bengali. See `assets/l10n/app_en.arb` for all strings to translate.
1. Open an issue with label `translation`
2. Submit a PR with your completed ARB file (e.g., `app_es.arb`)

### Code
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Follow the existing code structure (Riverpod providers, feature-folder layout)
4. Write widget tests for any new screens
5. Run `flutter analyze` and `flutter test` before submitting
6. Submit a pull request with a clear description of what your PR does and why

### Bug Reports
Open an issue with the `bug` label. Include: Flutter version, device/OS, steps to reproduce, and expected vs actual behavior.

---

## Development Setup

See `README.md` for full setup instructions. The short version:

```bash
git clone https://github.com/your-org/havennyc.git
cd havennyc
flutter pub get
# Set up your own Firebase project (see README_FIREBASE_SETUP.md)
flutter run --flavor development -t lib/main_dev.dart
```

---

## Priority Areas for Contribution

1. **Resource data accuracy** — the most direct impact
2. **Spanish translation** — largest non-English speaking population in NYC
3. **Accessibility testing** — with screen readers on both Android and iOS
4. **BLE mesh testing** — requires two physical devices; hard to test alone
5. **UI polish** — the app should feel warm and trustworthy, not clinical
