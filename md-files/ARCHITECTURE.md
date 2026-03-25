# HavenNYC — Architecture & Data Reference

This document covers the Firestore data model, authentication flow, BLE mesh design, and key architectural decisions. Keep this updated as the schema evolves.

---

## Authentication Flow

```
App Launch
    │
    ▼
Firebase Anonymous Auth
    │  (silent, automatic — generates temp UID)
    │
    ▼
Local UID stored in secure storage
    │
    ├─── User continues anonymously ──────────────────────────────────────────┐
    │        (all features available, no PII stored anywhere)                  │
    │                                                                           │
    └─── User opts into account upgrade (Settings → Save my data)             │
             │                                                                  │
             ▼                                                                  │
         OTP (phone) or Google Sign-In                                         │
             │                                                                  │
             ▼                                                                  │
         Firebase linkWithCredential() called on existing anonymous user       │
             │  (anonymous UID is PRESERVED — no data loss on upgrade)         │
             │                                                                  ▼
             └─────────────────────────────────────────────────────────► Active Session
```

**Key rule:** Anonymous auth is the default. The upgrade path uses `linkWithCredential` so the anonymous UID is promoted rather than replaced. Users never lose saved data.

---

## Firestore Data Model

### Collections Overview

```
/resources/{resourceId}
/users/{uid}
/users/{uid}/saved_resources/{resourceId}
/messages/{meshRoomId}/msgs/{messageId}
/jobs/{jobId}
/neighborhood_funds/{fundId}
/volunteer_opportunities/{oppId}
/sponsors/{sponsorId}
/notifications/{notificationId}
```

---

### `/resources/{resourceId}`

Core collection. Seeded by admins/volunteers. Read-only for all app users.

```
{
  id: string,
  name: string,
  category: ResourceCategory,       // enum — see below
  borough: Borough,                 // MANHATTAN | BROOKLYN | QUEENS | BRONX | STATEN_ISLAND
  neighborhood: string,             // e.g. "East Harlem"
  address: string,
  lat: number,
  lng: number,
  phone: string | null,
  website: string | null,
  hours: {                          // null if always open or unknown
    mon: string | null,
    tue: string | null,
    wed: string | null,
    thu: string | null,
    fri: string | null,
    sat: string | null,
    sun: string | null,
  } | null,
  availableBeds: number | null,     // shelters only; updated externally via admin tool
  lowSupply: boolean,               // pantries only; toggled by partner users
  languages: string[],             // ISO 639-1 codes of languages spoken on-site
  tags: string[],                  // e.g. ["LGBTQ+", "Youth", "Veteran"]
  lastVerified: Timestamp,
  active: boolean,
}
```

**ResourceCategory enum values:**
`SHELTER | FOOD_PANTRY | SOUP_KITCHEN | AFFORDABLE_HOUSING | PUBLIC_BATHROOM | FREE_WIFI | LIBRARY | HYGIENE_SHOWER | MEDICAL | DENTAL | MENTAL_HEALTH | LEGAL_AID | CLOTHING | JOB_TRAINING | CRISIS_HOTLINE | YOUTH | LGBTQ`

---

### `/users/{uid}`

Created on first launch (anonymous or signed-in). Contains only preference data — no PII for anonymous users.

```
{
  uid: string,
  userType: "PERSON_IN_NEED" | "COMMUNITY_PARTNER",
  isAnonymous: boolean,
  displayName: string | null,       // only set if user upgrades account
  language: string,                 // ISO 639-1, default "en"
  notificationsEnabled: boolean,
  fcmToken: string | null,
  textScaleFactor: number | null,   // null = use OS setting
  createdAt: Timestamp,
  lastSeen: Timestamp,
}
```

---

### `/users/{uid}/saved_resources/{resourceId}`

Subcollection for bookmarked resources per user.

```
{
  resourceId: string,
  savedAt: Timestamp,
}
```

---

### `/jobs/{jobId}`

Job training and employment listings.

```
{
  id: string,
  title: string,
  organization: string,
  description: string,
  borough: Borough | "CITYWIDE",
  neighborhood: string | null,
  address: string | null,
  contactEmail: string | null,
  contactPhone: string | null,
  website: string | null,
  isFree: boolean,
  deadline: Timestamp | null,
  tags: string[],                  // e.g. ["Tech", "Healthcare", "Trades"]
  active: boolean,
  postedAt: Timestamp,
}
```

---

### `/neighborhood_funds/{fundId}`

Community mutual aid funds per neighborhood. (P2)

```
{
  id: string,
  title: string,
  description: string,
  borough: Borough,
  neighborhood: string,
  goalAmountCents: number,
  raisedAmountCents: number,
  createdBy: string,               // uid of creating partner
  active: boolean,
  createdAt: Timestamp,
  expiresAt: Timestamp | null,
}
```

---

### `/volunteer_opportunities/{oppId}` (P2)

```
{
  id: string,
  title: string,
  organization: string,
  description: string,
  borough: Borough | "CITYWIDE",
  neighborhood: string | null,
  date: Timestamp | null,          // null = ongoing
  recurring: boolean,
  spotsAvailable: number | null,
  contactEmail: string | null,
  website: string | null,
  tags: string[],
  active: boolean,
  postedAt: Timestamp,
}
```

---

### `/messages/{meshRoomId}/msgs/{messageId}` (P1)

Used for queued offline BLE messages that arrive when connectivity is restored. The mesh itself operates device-to-device; Firestore only holds queued messages for users who were offline during delivery.

```
{
  id: string,
  senderUid: string,               // anonymous UID — no display name stored server-side
  recipientUid: string,
  body: string,
  sentAt: Timestamp,
  delivered: boolean,
  deliveredAt: Timestamp | null,
  expiresAt: Timestamp,            // messages purged after 7 days
}
```

---

## Firestore Security Rules Summary

```
- /resources/** → read: any authenticated user (including anonymous); write: admin only
- /users/{uid}/** → read/write: uid == request.auth.uid only
- /jobs/** → read: any authenticated user; write: admin or verified partner
- /neighborhood_funds/** → read: any authenticated user; write: verified partner or admin
- /volunteer_opportunities/** → read: any authenticated user; write: verified partner or admin
- /messages/{room}/msgs/** → read/write: sender or recipient uid only
```

Full rules live in `firestore.rules`.

---

## Map Architecture

### Tile Provider
- **flutter_map** renders the map widget (free, no API key required)
- **OpenStreetMap** tiles used by default (`https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png`)
- Attribution must be displayed per OSM requirements

### Resource Clustering
- Use **flutter_map_marker_cluster** for grouping pins at lower zoom levels
- Cluster by borough at zoom < 11, by neighborhood at zoom 11–13, individual pins at zoom > 13

### Offline Map (P2)
- Use **flutter_map_tile_caching** to pre-cache tiles for NYC bounding box at zoom levels 10–16
- Download triggered manually from Settings → "Download offline map"
- Estimated size: ~80–120 MB for full NYC at those zoom levels

---

## BLE Mesh Architecture (P1)

### Library
- **flutter_blue_plus** — actively maintained, supports Android 6+ and iOS 13+

### Protocol Design (keep it simple)

```
Device A ──BLE advertise──► Device B ──BLE advertise──► Device C
              RELAY                         RELAY
```

1. Each device advertises a custom service UUID and its anonymous Firebase UID in the BLE advertisement payload
2. Messages are small JSON blobs: `{ to, from, body, ts, ttl }`
3. TTL starts at 5 (decrements each relay hop); dropped when TTL = 0
4. Each device stores a set of seen message IDs to prevent relay loops
5. When a device with the target UID is in range, it delivers directly
6. When internet is restored, queued messages sync to Firestore `/messages/` collection for server-assisted delivery

### Limitations to communicate to users
- Range: ~10–30 meters per hop
- Requires Bluetooth + location permission on Android
- Background scanning is limited on iOS (use foreground-only with clear UX indication)
- This is best-effort, not guaranteed delivery

---

## Notification Architecture

### Firebase Cloud Messaging (FCM)
- FCM token stored in `/users/{uid}.fcmToken`
- Updated on every app launch
- Topics subscribed per borough: `borough_manhattan`, `borough_brooklyn`, etc.
- Topics subscribed per category interest: `category_shelter`, `category_food`, etc.
- Admin can send targeted pushes via Firebase Console or a simple Cloud Function

### Notification Types
| Type | Trigger |
|---|---|
| `LOW_SUPPLY` | Partner marks a pantry as low on supplies |
| `NEW_RESOURCE` | New resource added in user's borough |
| `NEW_JOB` | New job listing matching user's saved tags |
| `FUND_GOAL_MET` | Neighborhood fund reaches goal |
| `MESH_MESSAGE` | Queued BLE message delivered via server |

---

## State Management (Riverpod)

```
AuthNotifier          → holds current Firebase User, auth state
ResourcesNotifier     → map resources, filtered by category/borough
MapNotifier           → zoom level, selected resource, viewport
JobsNotifier          → job listings, pagination
MessagingNotifier     → BLE state, message queue
SettingsNotifier      → language, textScaleFactor, userType
NotificationNotifier  → unread count, notification list
```

All providers are defined in `lib/shared/providers/`.

---

## Supported OS Versions

| Platform | Minimum | Notes |
|---|---|---|
| Android | API 23 (Android 6.0) | BLE requires API 21+; location permissions API 23+ |
| iOS | 13.0 | flutter_blue_plus requires iOS 13+ |
| Web | Evergreen browsers | BLE mesh not available on web; degraded gracefully |

---

## Localization

Top 5 NYC languages supported (P2):
1. English (`en`) — default
2. Spanish (`es`)
3. Mandarin Chinese (`zh`)
4. Russian (`ru`)
5. Bengali (`bn`)

ARB files live in `assets/l10n/`. Use Flutter's `gen-l10n` tool to generate typed accessors.

```bash
flutter gen-l10n
```

---

## Performance Budget

| Metric | Target |
|---|---|
| Cold start (Android mid-range) | < 3 seconds |
| Map initial load | < 2 seconds (cached tiles) |
| APK size | < 25 MB |
| Firestore reads per session | < 100 (use local caching aggressively) |
| Firebase free tier headroom | Keep Firestore reads < 40k/day |
