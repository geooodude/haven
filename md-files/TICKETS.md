# HavenNYC — Development Tickets

Tickets are grouped by priority: **P0 (ship in v1.0) → P1 (v1.1) → P2 (v1.2+)**.

Each ticket includes a **Cursor Prompt** — paste it directly into Cursor's composer (CMD+I or CMD+K) with the relevant file(s) open or referenced.

---

## ─────────────────────────────────────────
## PRIORITY 0 — Core (v1.0)
## ─────────────────────────────────────────

---

### TICKET P0-001 — Project Scaffold & Pubspec Setup

**Feature:** Project foundation  
**Estimated effort:** S  

**Description:**  
Initialize the Flutter project with the correct package dependencies, folder structure, and build configuration. Set up flavors for `development` and `production`. Establish the folder structure defined in `ARCHITECTURE.md`.

**Acceptance Criteria:**
- [ ] `flutter pub get` runs without errors
- [ ] `development` flavor runs on Android emulator and iOS simulator
- [ ] `production` flavor is defined but not yet wired to live Firebase
- [ ] Folder structure matches `lib/core/`, `lib/features/`, `lib/shared/` layout
- [ ] Linting rules (`analysis_options.yaml`) enforced with strict mode

**Cursor Prompt:**
```
Create a Flutter pubspec.yaml for a project called havennyc. Include the following dependencies at their latest stable versions: flutter_riverpod, riverpod_annotation, go_router, firebase_core, firebase_auth, cloud_firestore, firebase_messaging, firebase_storage, flutter_map, flutter_map_marker_cluster, latlong2, flutter_blue_plus, flutter_secure_storage, flutter_dotenv, intl, cached_network_image, url_launcher, permission_handler, geolocator, flutter_localizations (sdk). Include dev dependencies: flutter_lints, riverpod_generator, build_runner, json_serializable, flutter_gen. Add an assets section for assets/l10n/, assets/icons/, assets/images/. Then create the full folder structure under lib/ as described: lib/core/constants/, lib/core/theme/, lib/core/utils/, lib/core/services/, lib/features/onboarding/, lib/features/map/, lib/features/resource_detail/, lib/features/messaging/, lib/features/jobs/, lib/features/community/, lib/features/account/, lib/features/notifications/, lib/features/settings/, lib/features/chatbot/, lib/shared/widgets/, lib/shared/models/, lib/shared/providers/. Create placeholder barrel export files (index.dart) in each folder. Also create an analysis_options.yaml that extends flutter_lints with strict mode (avoid_dynamic_calls, always_use_package_imports, prefer_final_locals).
```

---

### TICKET P0-002 — Firebase Initialization & FlutterFire Config

**Feature:** Firebase setup  
**Estimated effort:** S  

**Description:**  
Configure Firebase for Android, iOS, and Web using `FlutterFire CLI`. Set up `firebase_options.dart`, initialize Firebase in `main.dart`, and create a `FirebaseService` wrapper.

**Acceptance Criteria:**
- [ ] `firebase_options.dart` is generated and gitignored (developers generate their own)
- [ ] `firebase_options.dart.example` is committed to repo with placeholder values
- [ ] Firebase initializes without error on all three platforms
- [ ] A `README_FIREBASE_SETUP.md` is committed explaining the setup steps for contributors

**Cursor Prompt:**
```
In lib/main.dart, set up a Flutter app entry point that initializes Firebase using firebase_options.dart before runApp(). Use WidgetsFlutterBinding.ensureInitialized() before the async Firebase.initializeApp() call. Wrap the initialization in a try/catch that logs errors gracefully. The app should support two entry points: lib/main_dev.dart and lib/main_prod.dart, each passing a flavor constant (AppFlavor.development / AppFlavor.production) into the app root. Create lib/core/constants/app_flavor.dart with the AppFlavor enum. Create lib/core/services/firebase_service.dart as a singleton that exposes FirebaseFirestore.instance, FirebaseAuth.instance, and FirebaseMessaging.instance as named getters. Use flutter_riverpod and create a firebaseServiceProvider using Provider<FirebaseService>. Do not hardcode any API keys — reference firebase_options.dart which is gitignored.
```

---

### TICKET P0-003 — Anonymous Authentication Service

**Feature:** Anonymous auth (true anonymity as default)  
**Estimated effort:** M  

**Description:**  
Implement Firebase Anonymous Authentication as the silent, automatic default on first launch. The UID must be persisted to secure storage so the same anonymous identity survives app restarts. No UI prompt or consent screen for anonymous auth — it just works invisibly.

**Acceptance Criteria:**
- [ ] On first launch, Firebase Anonymous Auth is called automatically and silently
- [ ] The Firebase UID is stored in `flutter_secure_storage`
- [ ] On subsequent launches, the stored UID is verified against Firebase before creating a new one
- [ ] An `AuthState` sealed class covers: `unauthenticated`, `anonymous`, `authenticated` states
- [ ] A `AuthNotifier` (Riverpod AsyncNotifier) manages transitions between states
- [ ] No personal data is stored in Firestore during anonymous auth — only the UID

**Cursor Prompt:**
```
Create lib/core/services/auth_service.dart for HavenNYC. This service manages Firebase Anonymous Authentication. Requirements:
1. A method signInAnonymouslySilent() that calls FirebaseAuth.instance.signInAnonymously() only if there is no current user. If a user already exists (app restarted), it returns the existing user.
2. Store the UID in flutter_secure_storage under key 'haven_uid' after first sign-in.
3. On app start, read the stored UID and call FirebaseAuth.instance.currentUser to verify it's still valid. If the token is expired, re-authenticate anonymously and update storage.
4. Create a sealed class AuthState with subtypes: AuthStateLoading, AuthStateAnonymous(uid: String), AuthStateAuthenticated(user: User), AuthStateError(message: String).
5. Create a Riverpod AsyncNotifier<AuthState> called AuthNotifier in lib/shared/providers/auth_provider.dart. It should call signInAnonymouslySilent() in its build() method.
6. Never prompt the user during this silent flow. Never send any PII to Firestore. The only Firestore write during this flow is creating /users/{uid} with fields: uid, isAnonymous: true, userType: null, createdAt, lastSeen.
```

---

### TICKET P0-004 — Onboarding & User Type Selection

**Feature:** Onboarding flow  
**Estimated effort:** M  

**Description:**  
After silent anonymous auth completes, show a minimal onboarding screen asking the user to identify their context: "I need resources" or "I want to help." This selection is saved to Firestore and locally. The screen is shown only once (guarded by a flag in secure storage). There must be a way to skip and decide later.

**Acceptance Criteria:**
- [ ] Onboarding screen is shown only on first launch (flag: `onboarding_complete` in secure storage)
- [ ] Two clear CTAs: "I need resources" and "I want to help my community"
- [ ] A "Skip for now" option is present and visible
- [ ] User type is saved to `users/{uid}.userType` in Firestore
- [ ] After selection (or skip), user is routed to the Map screen
- [ ] Screen is accessible: large tap targets, readable font sizes

**Cursor Prompt:**
```
Create the onboarding feature for HavenNYC in lib/features/onboarding/. Requirements:
1. OnboardingScreen widget: a full-screen minimal layout with the HavenNYC name/logo at top, a short one-sentence tagline ("Find resources. Give help. No account needed."), two large card buttons — "I need resources" (UserType.personInNeed) and "I want to help my community" (UserType.communityPartner) — and a small "Skip for now" text button at the bottom.
2. An OnboardingNotifier (Riverpod Notifier) that: (a) checks flutter_secure_storage for key 'onboarding_complete', (b) on user type selection, writes userType to Firestore /users/{uid} and sets 'onboarding_complete' = 'true' in secure storage, (c) on skip, only sets 'onboarding_complete' = 'true' without writing userType.
3. Create the UserType enum in lib/core/constants/user_type.dart with values personInNeed and communityPartner.
4. In go_router (lib/app.dart), add a redirect guard: if onboarding is not complete, redirect to /onboarding. After onboarding, redirect to /map.
5. The design should be calm, warm, and simple — no images required at this stage, rely on typography and spacing. Use the app's primary color theme.
```

---

### TICKET P0-005 — Resource Data Model & Firestore Seed Script

**Feature:** Resource data  
**Estimated effort:** M  

**Description:**  
Define the `Resource` Dart model with JSON serialization. Create a Firestore seed script (Dart script or Node.js) that populates the `resources` collection with 20–30 real NYC resources across multiple categories and boroughs for development/testing purposes.

**Acceptance Criteria:**
- [ ] `Resource` model covers all fields defined in `ARCHITECTURE.md`
- [ ] `ResourceCategory` and `Borough` enums are defined
- [ ] `json_serializable` generates `fromJson`/`toJson`
- [ ] Firestore security rule: read = any authenticated user, write = admin only
- [ ] Seed data covers at least: 5 shelters, 5 food pantries, 3 libraries, 3 hygiene, 2 legal aid, 2 crisis hotlines — spread across at least 3 boroughs
- [ ] A `README_SEED.md` explains how to run the seed script

**Cursor Prompt:**
```
Create the Resource data model for HavenNYC. 
1. In lib/shared/models/resource.dart, create a Resource class using json_serializable and freezed (or just json_serializable without freezed to keep it simple). Fields: id (String), name (String), category (ResourceCategory), borough (Borough), neighborhood (String), address (String), lat (double), lng (double), phone (String?), website (String?), hours (Map<String, String?>?), availableBeds (int?), lowSupply (bool), languages (List<String>), tags (List<String>), lastVerified (DateTime), active (bool). 
2. Create lib/core/constants/resource_category.dart with the ResourceCategory enum: shelter, foodPantry, soupKitchen, affordableHousing, publicBathroom, freeWifi, library, hygieneShower, medical, dental, mentalHealth, legalAid, clothing, jobTraining, crisisHotline, youth, lgbtq. Add a displayName getter and an iconAssetPath getter to the enum.
3. Create lib/core/constants/borough.dart with Borough enum: manhattan, brooklyn, queens, bronx, statenIsland. Add a displayName getter.
4. Create a Dart script in scripts/seed_resources.dart that uses the firebase_admin equivalent (or outputs a JSON file) containing 25 realistic NYC resources — use real organization names (BRC, Holy Apostles Soup Kitchen, NYPL branches, etc.), real approximate coordinates, and accurate categories. The script should be runnable via `dart run scripts/seed_resources.dart` and upload to Firestore using the firebase_core + cloud_firestore packages initialized with a service account JSON (path taken from env var FIREBASE_SERVICE_ACCOUNT).
```

---

### TICKET P0-006 — Explorable Resource Map Screen

**Feature:** Map (core)  
**Estimated effort:** L  

**Description:**  
Build the main map screen using `flutter_map` + OpenStreetMap tiles. Display resource pins clustered by proximity. Show a bottom sheet on pin tap with basic resource info. Support NYC bounding box as the initial viewport.

**Acceptance Criteria:**
- [ ] Map centered on NYC on launch (lat 40.7128, lng -74.0060, zoom 11)
- [ ] All active resources from Firestore rendered as pins with category-specific icons
- [ ] Pins cluster at low zoom levels using `flutter_map_marker_cluster`
- [ ] Tapping a pin opens a `DraggableScrollableSheet` with resource name, category badge, address, and hours
- [ ] "Get Directions" button on the sheet launches native maps via `url_launcher`
- [ ] OSM attribution visible per terms
- [ ] Map loading state shown while Firestore data fetches

**Cursor Prompt:**
```
Build the main map screen for HavenNYC in lib/features/map/map_screen.dart using flutter_map and OpenStreetMap tiles. Requirements:
1. FlutterMap widget with TileLayer using OpenStreetMap URL template 'https://tile.openstreetmap.org/{z}/{x}/{y}.png' and proper attribution widget.
2. Initial camera position: center LatLng(40.7128, -74.0060), zoom 11.0. Min zoom 9.0 (don't go outside NYC region), max zoom 18.0.
3. A Riverpod provider ResourcesProvider that streams resources from Firestore collection 'resources' where active == true. Cache results locally using Firestore's built-in offline persistence.
4. Render resources as MarkerLayer inside a MarkerClusterLayerWidget from flutter_map_marker_cluster. Each marker uses a custom widget showing the category icon on a colored circle (color per category). 
5. On marker tap, show a DraggableScrollableSheet with minChildSize 0.25, initialChildSize 0.4, maxChildSize 0.85 containing: resource name (headline), category chip, neighborhood + borough, address, today's hours (derived from resource.hours using current weekday), phone number (tappable via url_launcher tel: scheme), website button, "Get Directions" button (opens maps.google.com/?daddr= URL via url_launcher), and a "Save" bookmark icon button.
6. A FloatingActionButton "My Location" that calls Geolocator.getCurrentPosition() (handle permission denial gracefully) and animates the map to the user's location.
7. Create a MapNotifier (Riverpod Notifier) holding: selectedResource (Resource?), mapController (MapController).
```

---

### TICKET P0-007 — Category Filter Bar

**Feature:** Map filters  
**Estimated effort:** M  

**Description:**  
Add a horizontally scrollable filter chip bar at the top of the map screen. Each chip represents a `ResourceCategory`. Selecting chips filters the markers shown on the map. A "All" chip deselects individual filters.

**Acceptance Criteria:**
- [ ] Horizontal scrollable row of chips, one per ResourceCategory + one "All" chip
- [ ] Each chip shows the category icon and display name
- [ ] Selecting "All" deselects all individual filters and shows all resources
- [ ] Multiple category chips can be selected simultaneously
- [ ] Filter state is managed in `MapNotifier`, not local widget state
- [ ] Chip row is positioned as a floating overlay at the top of the map (not displacing the map)
- [ ] Active filter count shown as a badge on a "Filter" icon button that collapses/expands the chip row

**Cursor Prompt:**
```
Add a category filter system to the HavenNYC map screen. 
1. Add a Set<ResourceCategory> activeFilters field to the existing MapNotifier. An empty set means "show all." Provide a toggleFilter(ResourceCategory) method and a clearFilters() method.
2. The ResourcesProvider should apply activeFilters to its output: if activeFilters is empty, return all resources; otherwise return only resources whose category is in activeFilters.
3. Create a FilterChipBar widget in lib/features/map/widgets/filter_chip_bar.dart: a horizontal SingleChildScrollView containing: an "All" FilterChip that calls clearFilters() and is selected when activeFilters is empty, then one FilterChip per ResourceCategory value showing the category icon (16px) and displayName label, colored when selected.
4. Position the FilterChipBar as a Positioned widget inside a Stack that wraps the FlutterMap. Place it at top: 16, left: 0, right: 0 with horizontal padding. Add a subtle white/surface-color background with blur using BackdropFilter so the map remains visible beneath.
5. Add a small active-filter count badge (shown only when activeFilters.isNotEmpty) on a "tune" IconButton that appears to the right of the chip row or on the map FAB area, toggling chip row visibility.
```

---

### TICKET P0-008 — Resource Detail Screen (Full)

**Feature:** Resource detail  
**Estimated effort:** M  

**Description:**  
Build a full-page resource detail screen reachable from the bottom sheet "View Full Details" button or from a saved resources list. Shows all available fields for the resource.

**Acceptance Criteria:**
- [ ] Full-screen route `/resource/:id` with deep-link support via go_router
- [ ] Shows: name, category, full address, all weekly hours, phone, website, languages spoken, tags (LGBTQ+, Youth, etc.), available beds count for shelters, low supply flag for pantries
- [ ] "Get Directions" and "Call" CTAs
- [ ] Share button generates a simple deep-link or plain text summary
- [ ] "Last verified" date shown with a note if > 90 days ago
- [ ] Save/unsave bookmark persists to Firestore `/users/{uid}/saved_resources/`

**Cursor Prompt:**
```
Create lib/features/resource_detail/resource_detail_screen.dart for HavenNYC. This is a full-page detail view for a single Resource.
1. Route: /resource/:resourceId — register in go_router. The screen fetches the resource by ID from Firestore if not passed as an extra object.
2. Layout: a CustomScrollView with a SliverAppBar (showing the category icon and a color derived from the category), then a SliverList with sections: Overview (name, category chip, borough + neighborhood), Contact (phone with tel: link, website with url_launcher), Hours (a 7-row table Mon–Sun with today's row highlighted), Details (languages spoken as chips, tags as chips, availableBeds for shelters, lowSupply banner for food pantries), Verification footer ("Last verified: [date]" — show a yellow warning banner if lastVerified is > 90 days ago).
3. A persistent bottom bar with two buttons: "Get Directions" (opens native maps) and "Save" (toggle bookmark). Save writes to or deletes from Firestore /users/{uid}/saved_resources/{resourceId}. Use a SavedResourcesProvider (Riverpod) that streams the user's saved resources.
4. A Share IconButton in the AppBar that calls Share.share() (add share_plus package) with the resource name, address, and website.
5. Handle loading and error states with shimmer placeholders (add shimmer package) and a retry button.
```

---

### TICKET P0-009 — Push Notifications Setup

**Feature:** Notifications  
**Estimated effort:** M  

**Description:**  
Integrate Firebase Cloud Messaging for push notifications on Android and iOS. Handle foreground, background, and terminated-state notification receipt. Subscribe users to borough-level topics on first launch. Show an in-app notification center.

**Acceptance Criteria:**
- [ ] FCM token is retrieved on launch and saved to `users/{uid}.fcmToken`
- [ ] iOS permission request for notifications is shown after onboarding completes (not on cold launch)
- [ ] Foreground notifications are shown as in-app banners using the notification overlay
- [ ] Background/terminated notifications deep-link to the relevant screen on tap
- [ ] User is auto-subscribed to their borough topic based on `userType` and location (if granted) or manually selected borough
- [ ] A "Notifications" screen at `/notifications` shows a list of recent in-app notifications stored in Firestore

**Cursor Prompt:**
```
Implement push notifications for HavenNYC using Firebase Cloud Messaging.
1. Create lib/core/services/notification_service.dart. It should: (a) call FirebaseMessaging.instance.requestPermission() on iOS — only call this after the user has completed onboarding, not on cold launch; (b) retrieve the FCM token with getToken() and save it to Firestore /users/{uid} field fcmToken; (c) call FirebaseMessaging.instance.subscribeToTopic() for the user's borough topic (e.g. 'borough_brooklyn') after their borough is determined; (d) set up onMessage (foreground), onMessageOpenedApp (background tap), and getInitialMessage (terminated tap) handlers.
2. For foreground notifications, use flutter_local_notifications to display a local notification. Add flutter_local_notifications to pubspec.
3. For notification taps (background and terminated), extract a 'route' field from the notification data payload and use go_router to navigate there. Example payload: { "route": "/resource/abc123" }.
4. Create a Riverpod NotificationNotifier that maintains a list of recent notifications in memory (also persisted to Firestore /notifications/{uid}/items/{id} as a subcollection). Track unread count as a badge on the notifications nav icon.
5. Create lib/features/notifications/notifications_screen.dart: a simple ListView of notification items showing title, body, timestamp, and a read/unread indicator. Tapping an item marks it read and navigates to its route.
```

---

### TICKET P0-010 — App Shell, Navigation & Theme

**Feature:** App shell  
**Estimated effort:** M  

**Description:**  
Build the main app shell with bottom navigation, global theme (colors, typography, component styles), and the go_router configuration. The shell adapts based on user type (person in need vs community partner — different nav items).

**Acceptance Criteria:**
- [ ] Bottom navigation bar with correct tabs per user type (see below)
- [ ] `go_router` with nested shell routes so bottom nav persists
- [ ] Light theme defined; dark theme stub present (not required for v1.0 but scaffold should support it)
- [ ] Color scheme reflects calm, accessible tones — no harsh contrasts
- [ ] Typography uses a legible system/Google font, scales with `textScaleFactor` from settings
- [ ] Bottom nav shows notification badge when unread count > 0

**Person in Need nav tabs:** Map, Saved, Messages (P1), Notifications, Settings  
**Community Partner nav tabs:** Map, Volunteer, Community, Notifications, Settings

**Cursor Prompt:**
```
Create the app shell and theme for HavenNYC.
1. lib/app.dart: a StatelessWidget that wraps MaterialApp.router with the GoRouter configuration and the app ThemeData.
2. GoRouter config in lib/core/router/app_router.dart: define a ShellRoute with a ScaffoldWithNavBar widget as the shell. Routes inside the shell: /map, /saved, /messaging, /notifications, /settings, /volunteer, /community, /jobs. Routes outside the shell (full-screen): /onboarding, /resource/:id, /account. Add a redirect that sends unauthenticated users to /onboarding.
3. Create lib/shared/widgets/scaffold_with_nav_bar.dart: a Scaffold with a NavigationBar (Material 3) at the bottom. Use a Riverpod provider to read the current UserType and show the correct tab set. Person in need: Map (map icon), Saved (bookmark icon), Notifications (bell icon with badge), Settings (settings icon). Community partner: Map, Volunteer (handshake icon), Community (people icon), Notifications, Settings.
4. lib/core/theme/app_theme.dart: define AppTheme.light() returning a ThemeData using ColorScheme.fromSeed with a seed color of a warm teal (#2A9D8F) — calm, trustworthy. Use Google Fonts package — select a highly legible font (e.g. Nunito or DM Sans). Set useMaterial3: true. Define consistent card, chip, button, and bottom sheet themes. 
5. Add a textScaleFactorProvider in Riverpod that reads from SettingsNotifier — if null, uses MediaQuery.textScalerOf(context). Wrap MaterialApp with a MediaQuery override that applies the scale.
```

---

## ─────────────────────────────────────────
## PRIORITY 1 — Important (v1.1)
## ─────────────────────────────────────────

---

### TICKET P1-001 — Optional Account Upgrade (Persistent Identity)

**Feature:** Account system  
**Estimated effort:** M  

**Description:**  
Allow users to optionally link their anonymous Firebase UID to a real identity (phone OTP or Google Sign-In) so their data persists when they switch devices. Uses Firebase's `linkWithCredential()` — the anonymous UID is promoted, not replaced.

**Acceptance Criteria:**
- [ ] Account upgrade option lives in Settings, not forced on the user
- [ ] Two upgrade paths: phone number OTP and Google Sign-In
- [ ] Uses `FirebaseAuth.linkWithCredential()` — anonymous data is preserved
- [ ] If phone/Google account already exists in Firebase, offer `signInWithCredential()` then migrate saved resources from old anonymous session to the new UID
- [ ] After upgrade, `isAnonymous: false` is written to Firestore
- [ ] Users can sign out (reverts to a new anonymous session) with clear warning about data loss

**Cursor Prompt:**
```
Implement the optional account upgrade flow for HavenNYC in lib/features/account/.
1. AccountUpgradeScreen: shown from Settings, not on launch. It has two options: "Continue with phone" and "Continue with Google." A header explains: "Save your data across devices. No personal info is shared with other users."
2. Phone OTP flow: use firebase_auth PhoneAuthProvider. Implement: (a) phone number input screen with country code selector (use the intl_phone_field package), (b) OTP verification screen with a 6-digit input (use pin_code_fields package), (c) on verification, call FirebaseAuth.instance.currentUser!.linkWithCredential(phoneCredential). Handle the firebase_auth/credential-already-in-use error by offering to sign into the existing account instead and migrating saved resources.
3. Google Sign-In flow: use google_sign_in package. Call currentUser.linkWithCredential(googleCredential). Handle the same existing-account error.
4. After successful upgrade: update Firestore /users/{uid} with isAnonymous: false. Show a success screen.
5. In AuthNotifier, add a signOut() method that calls FirebaseAuth.signOut() then immediately calls signInAnonymously() to restore an anonymous session. Before signing out, show an AlertDialog warning: "You will lose your saved resources unless you've linked an account."
```

---

### TICKET P1-002 — Web Support (Flutter Web Build)

**Feature:** Web platform  
**Estimated effort:** M  

**Description:**  
Ensure the app builds and runs on Flutter Web. BLE mesh is not available on web — gate all BLE-related UI behind a platform check. Configure Firebase Hosting to serve the web build. Handle web-specific PWA settings (manifest, icons, offline shell via service worker).

**Acceptance Criteria:**
- [ ] `flutter build web --release` completes without errors
- [ ] App runs correctly in Chrome and Firefox (latest)
- [ ] BLE mesh features are hidden on web with a platform-aware widget
- [ ] `firebase.json` configures Firebase Hosting to serve `build/web`
- [ ] Web manifest (`manifest.json`) has correct app name, icons, and `display: standalone`
- [ ] `flutter_map` tiles load on web without CORS errors (OSM tiles allow this)

**Cursor Prompt:**
```
Configure HavenNYC for Flutter Web support.
1. Create a PlatformGuard widget in lib/shared/widgets/platform_guard.dart that wraps any feature unavailable on web. It checks kIsWeb and kIsAndroid/kIsIOS using the foundation constants. If the platform doesn't support the feature, it shows a placeholder widget (a subtle banner: "This feature is available in the mobile app"). Use this for all BLE mesh UI.
2. Audit the following for web compatibility: (a) flutter_secure_storage — use flutter_secure_storage_web on web (add the web implementation to pubspec); (b) geolocator — works on web via browser geolocation, no changes needed; (c) flutter_local_notifications — not supported on web, gate all calls behind !kIsWeb; (d) url_launcher — works on web; (e) flutter_blue_plus — completely hidden on web using PlatformGuard.
3. Update web/manifest.json with: name "HavenNYC", short_name "Haven", theme_color matching app primary color, background_color white, display standalone, icons at 192x192 and 512x512.
4. Create firebase.json with a hosting config that sets public to "build/web", rewrites all routes to index.html (for SPA routing), and sets cache headers for static assets (Cache-Control: max-age=31536000 for hashed assets, no-cache for index.html).
5. In go_router, ensure that web URL navigation works correctly — verify that /resource/:id deep links work when entered directly in the browser address bar.
```

---

### TICKET P1-003 — BLE Mesh Messaging (Core Protocol)

**Feature:** Offline P2P messaging  
**Estimated effort:** XL  

**Description:**  
Implement the Bluetooth Low Energy mesh messaging system using `flutter_blue_plus`. Devices advertise their anonymous UID and scan for nearby devices. Messages are relayed hop-by-hop until they reach their destination or TTL expires. This ticket covers the core BLE service — UI is a separate ticket.

**Acceptance Criteria:**
- [ ] BLE scanning and advertising work on Android 6+ and iOS 13+
- [ ] Custom GATT service UUID registered for HavenNYC mesh
- [ ] Message struct: `{ id, to, from, body, ts, ttl: int }` — serialized as compact JSON
- [ ] TTL starts at 5, decrements each relay hop, dropped at 0
- [ ] Seen-message ID set prevents relay loops
- [ ] When recipient UID is in range, message is delivered directly via BLE characteristic write
- [ ] Queued messages are flushed to Firestore when internet connection is restored
- [ ] Permissions are requested gracefully with rationale dialogs before any BLE operation

**Cursor Prompt:**
```
Create lib/core/services/ble_mesh_service.dart for HavenNYC. This implements a Bluetooth Low Energy mesh messaging protocol using flutter_blue_plus.
Define constants: SERVICE_UUID = '4fafc201-1fb5-459e-8fcc-c5c9c331914b' (custom UUID), CHAR_UUID_MESSAGES = 'beb5483e-36e1-4688-b7f5-ea07361b26a8'. 

The service must:
1. ADVERTISING: Use FlutterBluePlus to advertise the custom service UUID and encode the local user's anonymous UID (first 8 chars) in the advertisement data's local name field.
2. SCANNING: Continuously scan for nearby devices advertising the HavenNYC service UUID. For each found device, attempt to connect and discover the message characteristic.
3. MESSAGE MODEL: Create a BleMessage class in lib/shared/models/ble_message.dart with fields: id (UUID string), toUid (String), fromUid (String), body (String), sentAt (DateTime), ttl (int, default 5). Add toJson/fromJson.
4. RELAY LOGIC: When a message is received from a peer: (a) check a local Set<String> seenMessageIds — if already seen, discard; (b) add to seenMessageIds; (c) if toUid matches localUid, deliver to message inbox; (d) otherwise, decrement ttl and if ttl > 0, add to outbound relay queue.
5. QUEUE & SYNC: Maintain an outbound queue (List<BleMessage>). When connectivity (ConnectivityResult.mobile or wifi) is available (use connectivity_plus package), flush undelivered messages to Firestore /messages/{roomId}/msgs/{messageId} for server-assisted delivery.
6. PERMISSIONS: Before starting, check and request BLUETOOTH_SCAN, BLUETOOTH_CONNECT (Android 12+), ACCESS_FINE_LOCATION (Android 6–11) using permission_handler. Show a rationale dialog explaining offline messaging before requesting.
7. Expose streams: Stream<BleMessage> incomingMessages and Stream<BleScanState> scanState.
```

---

### TICKET P1-004 — Messaging UI Screen

**Feature:** Offline P2P messaging UI  
**Estimated effort:** L  

**Description:**  
Build the chat UI for BLE mesh messaging. Shows a list of conversations (by UID), a chat thread view, and a composer. Clearly communicates to the user when they are in offline BLE mode vs online mode.

**Acceptance Criteria:**
- [ ] Conversations list at `/messaging` shows recent threads sorted by last message
- [ ] Thread view at `/messaging/:peerUid` shows message bubbles with timestamps
- [ ] Message composer with send button; max 280 characters
- [ ] A persistent banner communicates connectivity mode: "Online - messages sync" or "Offline - Bluetooth only"
- [ ] Nearby devices with the HavenNYC service shown as "Discoverable users" (UID shown truncated, no names)
- [ ] Platform guard hides the entire screen on web

**Cursor Prompt:**
```
Create the messaging UI for HavenNYC in lib/features/messaging/.
1. MessagingScreen (lib/features/messaging/messaging_screen.dart): the conversations list. Reads recent threads from a local Hive or sqflite database (add sqflite + path_provider — use sqflite for local message persistence). Each thread shows: peer UID (first 8 chars), last message preview, timestamp, unread badge. Tapping opens ChatThreadScreen.
2. ChatThreadScreen: a full-screen chat view. Uses a ListView.builder in reverse order (latest at bottom). Messages from self are right-aligned (blue bubble), messages from peer are left-aligned (grey bubble). Shows timestamp on each bubble. A bottom composer: TextField (max 280 chars) + Send IconButton.
3. Sending a message: creates a BleMessage via BleMeshService.sendMessage(toUid, body). Saves optimistically to local sqflite. Shows a sending indicator (clock icon) until delivery confirmed or queued.
4. ConnectivityBanner widget: reads a connectivityProvider (Riverpod) that wraps connectivity_plus. Shows a non-dismissible banner at the top of MessagingScreen: green "Online — messages backed up" or amber "Offline — Bluetooth relay active."
5. NearbyUsersSheet: a bottom sheet accessible from a FAB on MessagingScreen. Shows a list of currently scanned BLE devices advertising the HavenNYC service UUID. Each item shows a truncated UID and a "Message" button. Tapping "Message" opens a new ChatThreadScreen with that peer UID.
6. Wrap the entire /messaging route in the PlatformGuard widget — show "Download the mobile app to use offline messaging" on web.
```

---

### TICKET P1-005 — Job Listings Screen

**Feature:** Job listings  
**Estimated effort:** M  

**Description:**  
Build a searchable, filterable feed of free job training and employment resources. Data is admin-managed in Firestore. No job application is handled in-app — listings link out to external resources.

**Acceptance Criteria:**
- [ ] Job listings screen at `/jobs` accessible from the map screen's FAB or nav
- [ ] Filter by borough and by tag (Tech, Healthcare, Trades, etc.)
- [ ] Search by keyword (client-side filtering on fetched data)
- [ ] Each card shows: title, organization, borough, tags, deadline (if any), "Free" badge if isFree
- [ ] Tapping a card opens a full detail sheet with description and contact info
- [ ] "Apply / Learn More" button opens website via url_launcher
- [ ] Empty state with a helpful message when no listings match filters

**Cursor Prompt:**
```
Create the job listings feature for HavenNYC in lib/features/jobs/.
1. JobsScreen: a Scaffold with a search bar at the top (TextField with debounce — 300ms), a horizontal filter chip row for boroughs (All, Manhattan, Brooklyn, Queens, Bronx, Staten Island) and a second row for tags (All, Tech, Healthcare, Trades, Food Service, Admin, etc.), and a ListView of JobCard widgets below.
2. JobCard widget: a Material card with: job title (bold, headline), organization name, borough chip, tags as small chips, deadline text ("Deadline: Jan 15" or "Open enrollment"), a green "Free" badge if isFree. Tapping opens JobDetailBottomSheet.
3. JobDetailBottomSheet: a DraggableScrollableSheet with the full job description (scrollable), contact email (tappable mailto:), phone (tappable tel:), and a prominent "Learn More / Apply" ElevatedButton that opens the website URL.
4. JobsNotifier (Riverpod AsyncNotifier): fetches all active jobs from Firestore /jobs where active == true. Client-side filtering by selected borough, selected tags, and search query. Expose filteredJobs as a derived provider.
5. JobSearchNotifier: holds searchQuery (String), selectedBorough (Borough?), selectedTags (Set<String>). Provides methods: updateSearch, toggleBorough, toggleTag, clearAll.
6. Create the Job model in lib/shared/models/job.dart with json_serializable.
```

---

### TICKET P1-006 — Settings Screen

**Feature:** Settings  
**Estimated effort:** M  

**Description:**  
Build the settings screen covering display accessibility, user type switching, notification preferences, and account management. Text scale should default to the OS accessibility setting.

**Acceptance Criteria:**
- [ ] Settings at `/settings` accessible from bottom nav
- [ ] Text size section: "Use device default" (reads OS `textScaleFactor`) or manual override with a slider (0.85x to 1.5x)
- [ ] Mode switch: "I need resources" / "I want to help" (updates `userType` in Firestore)
- [ ] Notification preferences: toggle per notification type (new resources, low supply alerts, etc.)
- [ ] Language selection (stub for P2 — shows "English" only in P1, with "More languages coming soon")
- [ ] Account section: "Save my data across devices" button → opens `AccountUpgradeScreen`; shows current account status
- [ ] "About HavenNYC" section: version number, open source link, privacy policy link

**Cursor Prompt:**
```
Create the settings screen for HavenNYC in lib/features/settings/settings_screen.dart.
1. Use a ListView with ListTile sections separated by section headers (a simple subtitle-style Padding widget with text, no heavy dividers).
2. DISPLAY section: a SwitchListTile "Use device text size" (default ON). When OFF, show a Slider from 0.85 to 1.50 in 0.05 steps with a preview text below showing "Preview text" at the selected scale. The selected value updates SettingsNotifier.textScaleFactor. When ON, textScaleFactor is null (uses MediaQuery default). Persist choice to flutter_secure_storage.
3. MODE section: two RadioListTile options — "I'm looking for resources" and "I want to help my community." Changing this updates SettingsNotifier and writes to Firestore /users/{uid}.userType.
4. NOTIFICATIONS section: SwitchListTile entries for: New resources in my area, Low supply alerts (food pantries), New job listings, Community updates. Each toggle calls NotificationService.subscribeToTopic() or unsubscribeFromTopic(). Persist preferences to Firestore /users/{uid}.
5. LANGUAGE section: a ListTile showing current language ("English") with a trailing ChevronRight. Tapping shows a disabled BottomSheet with a message: "More languages coming in a future update" and a list of the 5 planned languages grayed out.
6. ACCOUNT section: if user is anonymous, show a ListTile "Save data across devices →" that navigates to /account/upgrade. If signed in, show display name (phone/email), a "Sign out" ListTile.
7. ABOUT section: app version (from package_info_plus), "View source on GitHub" (url_launcher), "Privacy Policy" (url_launcher).
```

---

### TICKET P1-007 — Borough/Neighborhood Map Grouping

**Feature:** Map — neighborhood clustering  
**Estimated effort:** M  

**Description:**  
Enhance the map clustering so that at low zoom levels resources are grouped by borough, and at medium zoom by neighborhood. Borough clusters show a summary count and borough name. A "Browse by neighborhood" list view is accessible as an alternative to the map.

**Acceptance Criteria:**
- [ ] At zoom < 10: 5 borough clusters shown with total resource count
- [ ] At zoom 10–13: neighborhood-level clusters
- [ ] At zoom > 13: individual resource pins
- [ ] A "List view" toggle on the map screen switches to a grouped list (borough → neighborhood → resources)
- [ ] List view is search-friendly for users who prefer browsing without a map

**Cursor Prompt:**
```
Enhance the HavenNYC map screen with borough and neighborhood-level grouping.
1. Extend MapNotifier to track currentZoom (double). Update it from the FlutterMap's onMapEvent callback (MapEventMove).
2. Create a derivedMarkersProvider that takes the ResourcesProvider output and currentZoom: if zoom < 10.5, group resources by Borough and return one synthetic marker per borough at the borough's centroid (hardcode the 5 NYC borough centroids); if zoom 10.5–13, group by neighborhood using the resource.neighborhood field and return cluster markers at the average lat/lng of the group; if zoom > 13, return individual resource markers. Each cluster marker shows a count badge and the borough/neighborhood name below it.
3. Tapping a borough or neighborhood cluster at zoom < 13 animates the map camera to zoom into that cluster's bounding box (compute from member coordinates using LatLngBounds).
4. Add a toggle button (list icon) to the map AppBar that sets a isListView bool in MapNotifier. When true, show a NeighborhoodListView widget instead of the FlutterMap.
5. NeighborhoodListView: a Column with a search TextField, then an ExpansionTile per borough, each containing ExpansionTile entries per neighborhood, each containing ListTile entries per resource (icon, name, category chip). Tapping a resource navigates to /resource/:id.
```

---

## ─────────────────────────────────────────
## PRIORITY 2 — Enhanced (v1.2+)
## ─────────────────────────────────────────

---

### TICKET P2-001 — AI Chatbot Assistant

**Feature:** Chatbot  
**Estimated effort:** L  

**Description:**  
Integrate a lightweight AI assistant that helps users find the right resources through natural conversation. Use Gemini Flash (free tier via Google AI Studio) or a similar zero-cost API. The chatbot knows the resource categories and can suggest filters, navigate to resource detail screens, and answer basic questions about service types.

**Acceptance Criteria:**
- [ ] Chatbot screen at `/chat` accessible from map screen FAB or nav
- [ ] Conversation history maintained for the session
- [ ] The chatbot has a system prompt that gives it context about HavenNYC's resource categories
- [ ] It can produce structured "action" responses that trigger in-app navigation (e.g., "I'll open the shelter map for you" → navigates to map with shelter filter active)
- [ ] Clear disclosure that it's an AI
- [ ] Graceful offline fallback: if API is unreachable, show a static help guide

**Cursor Prompt:**
```
Create the chatbot feature for HavenNYC in lib/features/chatbot/.
1. Use the Google Generative AI Dart SDK (google_generative_ai package). API key is loaded from flutter_dotenv as env variable GEMINI_API_KEY. Use the gemini-1.5-flash model (free tier).
2. System prompt: craft a prompt that tells the model it is a compassionate resource navigation assistant for HavenNYC, an app for NYC residents in need. It knows these resource categories: [list all ResourceCategory displayNames]. When users describe a need, it should respond empathetically, briefly explain what type of resource would help, and output a special JSON action block if it wants to trigger in-app navigation: {"action": "FILTER_MAP", "categories": ["shelter"]} or {"action": "OPEN_RESOURCE", "resourceId": "..."} or {"action": "OPEN_JOBS"}. After any JSON block, include a plain-language explanation.
3. ChatbotNotifier (Riverpod): holds List<ChatMessage> history. Sends messages to Gemini API, appends responses. Parses assistant responses for JSON action blocks using a regex. When an action block is found, emit it via a Stream<ChatbotAction> that the ChatbotScreen listens to and dispatches via go_router.
4. ChatbotScreen: a standard chat UI (reuse the bubble style from MessagingScreen). Add a typing indicator when awaiting API response. Show "Powered by Google AI — responses may be inaccurate" footer.
5. Offline fallback: catch network errors and show a static ListView of quick help prompts that navigate directly to map filter views: "Find a shelter near me", "I need food today", "I need medical help", "I need legal help".
```

---

### TICKET P2-002 — Offline City Map (Tile Caching)

**Feature:** Offline map  
**Estimated effort:** L  

**Description:**  
Allow users to download NYC map tiles for offline use. Use `flutter_map_tile_caching` (FMTC) to pre-cache tiles for the NYC bounding box at zoom levels 10–16. Show download progress, estimated size, and allow deletion of the cache.

**Acceptance Criteria:**
- [ ] "Download offline map" option in Settings
- [ ] Download shows progress bar and estimated storage size (~100 MB)
- [ ] Map falls back to cached tiles automatically when offline (no special UI toggle needed)
- [ ] Users can delete the cache from Settings (shows current size used)
- [ ] Download can be paused and resumed
- [ ] Tile download only runs on WiFi by default (with a warning if on cellular)

**Cursor Prompt:**
```
Add offline map tile caching to HavenNYC using flutter_map_tile_caching (FMTC).
1. Add flutter_map_tile_caching to pubspec. Initialize FMTC in main.dart before runApp using FlutterMapTileCaching.initialise().
2. Create a FMTCStore named 'nycTiles' on first app launch. Register it as a TileProvider in the FlutterMap TileLayer.
3. In Settings screen, add an "Offline Map" section: show current cache size (read from FMTCStore stats), a "Download NYC map" button, and a "Delete cache" button.
4. OfflineMapDownloadScreen (lib/features/settings/offline_map_download_screen.dart): shows a map preview of the NYC bounding box (LatLngBounds: SW 40.4774, -74.2591 — NE 40.9176, -73.7004), estimated size text ("~100 MB"), a WiFi-only toggle (default on), a "Start Download" button. Uses FMTC's download API to download all tiles for the bbox at zoom levels 10–16. Shows a LinearProgressIndicator with percent and tile count. Offers Pause/Resume and Cancel buttons.
5. Before starting, check connectivity_plus: if on cellular and WiFi-only is enabled, show an AlertDialog warning. 
6. On the map screen, add a small "offline" icon badge to the tile attribution area when the map is rendering from cache (check FMTC's browseStoreStrategy).
```

---

### TICKET P2-003 — Multilingual Support (5 Languages)

**Feature:** Localization  
**Estimated effort:** L  

**Description:**  
Implement Flutter's ARB-based localization for English, Spanish, Mandarin Chinese, Russian, and Bengali. All user-facing strings must be externalized. Language selection persists to settings. Right-to-left layout is not required (Bengali is LTR).

**Acceptance Criteria:**
- [ ] All user-facing strings in ARB files (`app_en.arb`, `app_es.arb`, `app_zh.arb`, `app_ru.arb`, `app_bn.arb`)
- [ ] Language selection in Settings is functional
- [ ] Selected language persists across sessions in Firestore and secure storage
- [ ] Resource category display names, filter labels, onboarding text, and navigation labels all localized
- [ ] Plurals and gender forms handled where applicable (e.g., "1 resource" vs "5 resources")

**Cursor Prompt:**
```
Implement full localization for HavenNYC supporting English (en), Spanish (es), Mandarin Chinese (zh), Russian (ru), and Bengali (bn).
1. Set up flutter_localizations in pubspec and l10n.yaml pointing to assets/l10n/ with template_arb_file: app_en.arb.
2. Create assets/l10n/app_en.arb with all user-facing strings. Cover: app name, onboarding screen (tagline, button labels), map screen (search hint, filter labels, all ResourceCategory display names, all Borough display names, bottom sheet labels: hours, directions, call, save, last verified, beds available, low supply warning), job listings screen, settings screen (all section titles and option labels), notifications screen, messaging screen, chatbot screen, error messages, empty states.
3. Create stub ARB files for es, zh, ru, bn — populate the Spanish file with accurate translations. For zh, ru, bn, use placeholder translations (mark them TODO for a future translation contributor — add a comment in each key: "@key": { "description": "...", "x-translator-note": "TODO: professional translation needed" }).
4. In SettingsNotifier, add a locale (Locale) field. When changed, update MaterialApp.router's locale prop via a Riverpod provider. Persist the language code to secure storage and to Firestore /users/{uid}.language.
5. Update the Settings screen language section to show a functional LanguageSelectorSheet: a ListView of the 5 languages with their native names (English, Español, 中文, Русский, বাংলা) and a checkmark on the current selection.
6. Ensure all existing screens use AppLocalizations.of(context)! instead of hardcoded strings. Run flutter gen-l10n and verify no compile errors.
```

---

### TICKET P2-004 — Community Neighborhood Fund

**Feature:** Neighborhood mutual aid fund  
**Estimated effort:** L  

**Description:**  
Community partners can create micro-fundraising campaigns scoped to a specific neighborhood. People in need can browse and request support. This is not a payment processor — it links out to external donation platforms (Venmo, Cash App links, or GoFundMe) for actual transactions. HavenNYC stores campaign metadata only.

**Acceptance Criteria:**
- [ ] Community screen at `/community` shows active neighborhood funds as cards
- [ ] Filter by borough
- [ ] Fund card shows: title, neighborhood, description, external donation link, goal/raised amounts (manually updated by campaign creator)
- [ ] Community partners can create a new fund via a form (requires non-anonymous account)
- [ ] Funds have an expiry date and are automatically marked inactive after that date
- [ ] No payment processing happens in-app — only links out

**Cursor Prompt:**
```
Create the community neighborhood fund feature for HavenNYC in lib/features/community/.
1. NeighborhoodFund model in lib/shared/models/neighborhood_fund.dart with all fields from ARCHITECTURE.md. Add json_serializable.
2. CommunityScreen: a DefaultTabController with two tabs: "Neighborhood Funds" and "Volunteer" (Volunteer tab is implemented in P2-005). The Funds tab shows a ListView of FundCard widgets with a borough filter chip row at the top.
3. FundCard widget: shows title, neighborhood + borough badge, a short description (max 2 lines, overflow ellipsis), a LinearProgressIndicator showing raisedAmount/goalAmount, amount text ("$X raised of $Y goal"), and a "Support this fund →" button.
4. Tapping "Support this fund →" opens FundDetailSheet: full description, creator info (anonymous or display name), expiry date, and a list of donation method buttons (each opens an external URL via url_launcher): Venmo, Cash App, GoFundMe — whichever the creator provided.
5. CreateFundScreen: accessible via a FAB on CommunityScreen, only for users where isAnonymous == false (gate with an upgrade prompt for anonymous users). Form fields: title, neighborhood (text field), borough (dropdown), description (multiline), goal amount (number field), expiry date (date picker), donation links (one or more URL fields with platform labels). Saves to Firestore /neighborhood_funds/ with createdBy = current UID.
6. FundsNotifier: streams active funds from Firestore where active == true and (expiresAt == null or expiresAt > now).
```

---

### TICKET P2-005 — Volunteer Opportunity Matching

**Feature:** Volunteer matching  
**Estimated effort:** M  

**Description:**  
Community partners and organizations post volunteer opportunities. Community partner users can browse and filter opportunities. A simple "interest" match is done by comparing opportunity tags against user's saved tag preferences.

**Acceptance Criteria:**
- [ ] Volunteer tab on Community screen (see P2-004)
- [ ] Filter by borough, date (upcoming vs ongoing), and tag
- [ ] Opportunity card shows: title, organization, date/recurring flag, spots available, tags
- [ ] "Express Interest" button sends the user to the external contact/signup link
- [ ] Community partners can post new opportunities (requires non-anonymous account)
- [ ] "Recommended for you" section at top based on tag matching against user's saved interests

**Cursor Prompt:**
```
Create the volunteer opportunity feature for HavenNYC within the CommunityScreen tab structure.
1. VolunteerOpportunity model in lib/shared/models/volunteer_opportunity.dart using json_serializable.
2. VolunteerTab widget (used inside CommunityScreen's TabBarView): shows a "Recommended for you" horizontal scrollable card strip at top (if user has saved interests), then a full list of all active opportunities with filter chips (borough + tags + recurring/one-time toggle).
3. VolunteerCard: shows title, organization, date (or "Ongoing" for recurring), borough + neighborhood, tags as chips, spots available (or "Unlimited"), a green "Volunteer" button.
4. Tapping "Volunteer": if opportunity has a website, open via url_launcher. If only contactEmail, open a mailto: link with a pre-filled subject "Volunteer Interest: [title]".
5. CreateVolunteerScreen: form for community partners (non-anonymous only). Fields: title, organization, description, borough, neighborhood (text), date picker (nullable for ongoing), recurring toggle, tags (multi-select chip picker), spotsAvailable (nullable number), contactEmail, website. Saves to Firestore /volunteer_opportunities/.
6. VolunteerNotifier: streams active opportunities. Add a recommendedOpportunitiesProvider that takes the user's tag preferences (stored in /users/{uid}.volunteerInterests: List<String>) and returns opportunities where any tag matches.
7. Add a "My Interests" button in the volunteer tab that opens an InterestsSheet with tag checkboxes. Saves selected tags to Firestore /users/{uid}.volunteerInterests.
```

---

### TICKET P2-006 — Food Pantry Low Supply Feature

**Feature:** Partner — pantry supply alerts  
**Estimated effort:** S  

**Description:**  
Community partner users can mark a food pantry as "low on supplies" from the resource detail screen. This triggers a push notification to subscribed users and updates the resource pin on the map with a warning badge.

**Acceptance Criteria:**
- [ ] "Mark as low supply" button visible on resource detail screen for food pantry / soup kitchen resources, only for community partner users
- [ ] Toggling low supply updates `resources/{id}.lowSupply` in Firestore
- [ ] The update triggers an FCM topic notification to `category_food` subscribers
- [ ] Resource pin on the map shows a warning badge when `lowSupply == true`
- [ ] A Cloud Function (or callable function) handles the Firestore write + FCM send to avoid giving app users write access to the `resources` collection
- [ ] Low supply banner shown prominently on the resource detail screen

**Cursor Prompt:**
```
Implement the low supply alert feature for HavenNYC food pantries.
1. In resource_detail_screen.dart, add a conditional section visible only when: (a) resource.category is foodPantry or soupKitchen, AND (b) the current user's userType is communityPartner. Show a low supply toggle: if resource.lowSupply is true, show a red banner "⚠ Currently low on supplies" with a "Mark as stocked" button. If false, show a subtle "Mark as low supply" outlined button.
2. The toggle button calls a Firebase Callable Cloud Function named 'updateResourceSupplyStatus' with payload { resourceId: String, lowSupply: bool }. Create the Cloud Function in functions/src/index.ts (TypeScript): it verifies the caller is authenticated, updates the Firestore resource document, and if lowSupply is true, sends an FCM notification to topic 'category_food' with title "Low supply alert" and body "[ResourceName] in [Neighborhood] is running low — can you help stock their shelves?".
3. On the map screen, update the marker builder: for resources where category is foodPantry or soupKitchen and lowSupply is true, add a small warning badge (amber triangle with ! icon) overlaid on the marker widget using a Stack.
4. In NotificationService, add a subscribe/unsubscribe method for 'category_food' topic. In the Settings screen notifications section, add a "Low supply alerts" SwitchListTile that calls this method.
```

---

### TICKET P2-007 — Local Business Sponsorship

**Feature:** Business sponsorship  
**Estimated effort:** M  

**Description:**  
Local businesses can be listed as sponsors of specific resources or neighborhoods. This is a lightweight directory — no payment processing in-app. Sponsor logos appear on relevant resource detail screens and the map. Sponsorships are managed by admins via the Firebase Console.

**Acceptance Criteria:**
- [ ] Sponsor data model in Firestore `/sponsors/` collection
- [ ] Sponsor logo + name shown at the bottom of relevant resource detail screens with "Supported by" label
- [ ] Sponsor card links to the business's website
- [ ] Sponsors can be associated with a resource ID, a neighborhood, or a borough
- [ ] A "Our Sponsors" section on the About/Settings screen
- [ ] No in-app payment — sponsorship is arranged externally, admin activates in Firestore

**Cursor Prompt:**
```
Create the local business sponsorship feature for HavenNYC.
1. Sponsor model in lib/shared/models/sponsor.dart: fields: id, businessName, logoUrl (Firebase Storage URL), website, description, linkedResourceIds (List<String>), linkedNeighborhoods (List<String>), linkedBoroughs (List<Borough>), active (bool). Add json_serializable.
2. SponsorsNotifier (Riverpod): streams all active sponsors from Firestore /sponsors where active == true. Provide a method getSponsorsForResource(Resource resource) that returns sponsors where linkedResourceIds contains resource.id OR linkedNeighborhoods contains resource.neighborhood OR linkedBoroughs contains resource.borough.
3. In resource_detail_screen.dart, add a "Supported by" section at the bottom (above the verification footer). This section is shown only if getSponsorsForResource returns non-empty results. Each sponsor shows: logo (CachedNetworkImage in a 48px height box), business name, and a subtle "Visit website →" link.
4. In Settings/About section, add a "Our Community Sponsors" ListTile that navigates to a SponsorsScreen: a simple grid (2 columns) of sponsor logos with business names, each tappable to open their website via url_launcher. Show a short message: "These local businesses help keep HavenNYC's resources funded and up to date."
5. Logos are loaded via CachedNetworkImage with a placeholder shimmer and error fallback (business name initials in a colored circle using the first letter).
```

---

### TICKET P2-008 — Enhanced Resource Detail: LGBTQ+ & Youth Filtering

**Feature:** Inclusive resource tags  
**Estimated effort:** S  

**Description:**  
Resources tagged with `LGBTQ` or `Youth` should be surfaced with dedicated filter shortcuts on the map. Add a "Resources for me" quick-access section on the map screen that shows tag-based shortcut chips.

**Acceptance Criteria:**
- [ ] Quick-access chip row on map screen includes: "LGBTQ+" and "Youth" as special shortcut chips
- [ ] Tapping these chips filters resources by the respective tag (not just category — tag filtering)
- [ ] LGBTQ+ and Youth resources show an appropriate badge on their pin and detail screen
- [ ] Crisis Hotline category has a persistent "Crisis support" floating chip that is always visible on the map regardless of other filters
- [ ] Deep-link `/map?tag=lgbtq` and `/map?tag=youth` routes work for sharing

**Cursor Prompt:**
```
Add inclusive tag-based filtering to the HavenNYC map screen.
1. Extend MapNotifier to include activeTagFilters (Set<String>) in addition to activeFilters (Set<ResourceCategory>). Add toggleTagFilter(String tag) and add tag filtering logic to the derivedMarkersProvider.
2. In ResourcesProvider, update the filtering to apply both category filters and tag filters: a resource passes if (activeFilters is empty OR resource.category is in activeFilters) AND (activeTagFilters is empty OR resource.tags contains any item in activeTagFilters).
3. Add a second row of quick-access chips below the category filter bar (or integrate into it) specifically for: "LGBTQ+ Friendly" (filters by tag 'LGBTQ+'), "Youth Services" (filters by tag 'Youth'), "Crisis Hotlines" (filters by category crisisHotline — this chip is styled in red/urgent and always visible even when filter bar is collapsed).
4. Update the map marker builder: resources tagged LGBTQ+ get a rainbow-gradient ring on their pin marker. Resources tagged Youth get a star badge. Crisis Hotline resources use a red pin with a phone icon regardless of other styling.
5. Register deep-link routes in go_router: /map?tag=lgbtq and /map?tag=youth. When navigated to, auto-apply the corresponding tag filter in MapNotifier. Test that these URLs work on both mobile and web.
```

---

## ─────────────────────────────────────────
## CROSS-CUTTING TICKETS
## ─────────────────────────────────────────

---

### TICKET CC-001 — Firestore Security Rules

**Feature:** Security  
**Estimated effort:** S  

**Cursor Prompt:**
```
Write complete Firestore security rules for HavenNYC in firestore.rules. Rules must enforce: (1) /resources/** — read: any authenticated user (including anonymous, so request.auth != null); write: only if request.auth.token.admin == true (admin custom claim). (2) /users/{uid}/** — read and write: only request.auth.uid == uid. (3) /jobs/** — read: any authenticated user; write: admin only. (4) /neighborhood_funds/** — read: any authenticated user; write: request.auth.uid == resource.data.createdBy (owner can edit) or admin. (5) /volunteer_opportunities/** — read: any authenticated user; write: authenticated non-anonymous user or admin (check request.auth.token.firebase.sign_in_provider != 'anonymous'). (6) /messages/{roomId}/msgs/{messageId} — read and write: request.auth.uid == resource.data.senderUid or request.auth.uid == resource.data.recipientUid. (7) /sponsors/** — read: any authenticated user; write: admin only. Also write the matching storage.rules ensuring: profile and resource images are readable by all authenticated users, writable only by admin or the owning user for profile images.
```

---

### TICKET CC-002 — Error Handling & Empty States

**Feature:** UX polish  
**Estimated effort:** M  

**Cursor Prompt:**
```
Create a consistent error handling and empty state system for HavenNYC.
1. Create lib/shared/widgets/error_state.dart: a reusable ErrorStateWidget that takes an error message (String) and an optional onRetry (VoidCallback). Shows a centered column: an icon (warning_rounded), the message, and a "Try again" TextButton if onRetry is provided. Style it calmly — no alarming colors, use the surface color.
2. Create lib/shared/widgets/empty_state.dart: EmptyStateWidget that takes a message, an optional subMessage, and an optional actionLabel + onAction. Used for empty lists, no search results, etc.
3. Create lib/shared/widgets/loading_shimmer.dart: a shimmer placeholder (use the shimmer package) that mimics the shape of a ResourceCard, a JobCard, and a generic list tile. Export as ResourceCardShimmer, JobCardShimmer, ListTileShimmer.
4. Create an AppException sealed class in lib/core/utils/app_exception.dart with subtypes: NetworkException, AuthException, PermissionException, NotFoundExceptionType, UnknownException. Each has a userFriendlyMessage getter.
5. Wrap all Riverpod AsyncNotifier build() methods with a try/catch that maps exceptions to AppException. In the UI layer, use AsyncValue.when() with a consistent error builder that shows ErrorStateWidget. For network-related errors, show an additional "You appear to be offline" banner using connectivity_plus.
```

---

### TICKET CC-003 — Accessibility Audit

**Feature:** Accessibility  
**Estimated effort:** M  

**Cursor Prompt:**
```
Perform an accessibility audit and fix on the HavenNYC codebase. Review every screen in lib/features/ and apply the following: 
1. Ensure all interactive widgets have a Semantics label. Replace Icon buttons that have no text with IconButton + tooltip or wrap with Semantics(label: '...').
2. Ensure all images have a Semantics(label: '...') or ExcludeSemantics if purely decorative.
3. Minimum tap target size: wrap any widget smaller than 48x48dp in a SizedBox(width: 48, height: 48) or add padding. Check all icon buttons, chips, and small buttons.
4. Color contrast: review all custom colors in app_theme.dart. Ensure text on colored backgrounds meets WCAG AA (4.5:1 for normal text, 3:1 for large text). Document any contrast ratios in a comment.
5. The textScaleFactor override in the app shell should never go below 0.85 to prevent excessive shrinking. Ensure all text uses theme styles (Theme.of(context).textTheme.*) — no hardcoded font sizes except in the theme file itself.
6. Add a Semantics(liveRegion: true) wrapper around notification banners and connectivity banners so screen readers announce them.
7. Review go_router navigation: ensure back navigation is semantically correct and the Semantics tree doesn't have orphaned focus traps.
```

---

### TICKET CC-004 — CI/CD with GitHub Actions

**Feature:** DevOps  
**Estimated effort:** S  

**Cursor Prompt:**
```
Create a GitHub Actions CI workflow for HavenNYC in .github/workflows/ci.yml. The workflow should trigger on push to main and on pull requests to main. Jobs: (1) lint-and-test: runs on ubuntu-latest, checks out the repo, sets up Flutter (stable channel, 3.16+), runs flutter pub get, flutter analyze, flutter test. (2) build-android: runs after lint-and-test passes, sets up Flutter and Java 17, runs flutter build apk --flavor production -t lib/main_prod.dart --no-tree-shake-icons, uploads the APK as a workflow artifact. (3) build-web: runs after lint-and-test passes, runs flutter build web --release -t lib/main_prod.dart, uploads the web build as a workflow artifact. All jobs should use caching for flutter pub get (cache the .pub-cache directory keyed on the pubspec.lock hash). Firebase config files (google-services.json, GoogleService-Info.plist, firebase_options.dart) should be generated from GitHub Secrets in a setup step using echo with base64 decoding. Document the required secrets in a .github/SECRETS.md file.
```

---

*Last updated: HavenNYC v1.0 planning*
