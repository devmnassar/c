# Phase 3 Map Status Milestone — Availability Tests and Profile Name State Isolated

**Branch (documentation):** `docs/phase-3-map-status-milestone`  
**Document date:** June 2026  
**Scope:** Map status screen — `lib/screens/courier_map_status_screen.dart` and driver availability Cubits

**Related documents:**

- [phase_3_next_target_after_incoming.md](./phase_3_next_target_after_incoming.md)
- [phase_3_incoming_milestone.md](./phase_3_incoming_milestone.md)
- [phase_3_delivery_milestone.md](./phase_3_delivery_milestone.md)
- [phase_3_planning_report.md](./phase_3_planning_report.md)

---

## 1. Executive Summary

Phase 3 on the map status screen was executed in three small, reversible steps so far:

| Step | Focus |
|------|--------|
| **Phase 3A Part 1** | Added **GoOnlineCubit** and **GoOfflineCubit** characterization tests (13 tests). |
| **Phase 3A Part 2** | Added **HeartbeatCubit** characterization tests (15 tests; driver availability total **28**). |
| **Phase 3B** | Moved **drawer profile-name display state** (`_profileName`) to `ValueNotifier<String>` and removed related `setState`. |

**Result:** `courier_map_status_screen.dart` **`setState` count reduced from 21 to 20**.

**Confirmation:** No `GoOnlineCubit`, `GoOfflineCubit`, or `HeartbeatCubit` implementation, API, navigation, route path, timer, heartbeat wiring, fake offer banner logic, GPS/location flow, map controller lifecycle, SharedPreferences `courier_online` behavior, or offer/order lookup navigation was **intentionally changed** during Phase 3A–3B.

This milestone is **limited to availability Cubit characterization tests and drawer profile-name display state only**. Fake offer timers, courier online persistence, heartbeat wiring, GPS, map controller, and offer/order navigation remain **untouched**.

---

## 2. Changes Completed

| Phase | Branch | Change | Production behavior impact |
| ----- | ------ | ------ | -------------------------- |
| **3A Part 1** | `test/phase-3-map-status-go-online-offline-cubit-characterization` | Added unit tests for `GoOnlineCubit` and `GoOfflineCubit` under `test/features/driver_availability/presentation/cubit/`. Helper fixtures under `test/features/driver_availability/helpers/`. Uses existing dev deps: `bloc_test`, `mocktail`. | **None** — test-only PR |
| **3A Part 2** | `test/phase-3-map-status-heartbeat-cubit-characterization` | Added unit tests for `HeartbeatCubit` in `heartbeat_cubit_test.dart`. Extended helpers with `sampleHeartbeatRequest()` / `sampleHeartbeatResult()`. Uses `fake_async` for timer tests; `SharedPreferences.setMockInitialValues` for forced-offline prefs check. | **None** — test-only PR |
| **3B** | `refactor/phase-3-map-status-profile-name-value-notifier` | `_profileName` → `_profileNameNotifier` (`ValueNotifier<String>`, default `'Courier'`); drawer profile name `Text` wrapped in `ValueListenableBuilder<String>`; 1 `setState` removed | **None intentional** — same `ProfileService.getProfile()` read, same default/fallback name, same drawer layout and callbacks |

---

## 3. Test Coverage Added

### GoOnlineCubit (6 tests)

| Scenario | Covered |
|----------|---------|
| Initial state | Yes |
| `goOnline` success | Yes |
| Request build failure | Yes |
| API / use case failure | Yes |
| Duplicate request ignored while in progress | Yes |
| `resetStatus` clears error, returns to initial | Yes |

### GoOfflineCubit (7 tests)

| Scenario | Covered |
|----------|---------|
| Initial state | Yes |
| `goOffline` success (default `UserRequested` reason) | Yes |
| Custom reason passed to request builder | Yes |
| Request build failure | Yes |
| API / use case failure | Yes |
| Duplicate request ignored while in progress | Yes |
| `resetStatus` clears error, returns to initial | Yes |

### HeartbeatCubit (15 tests)

| Scenario | Covered |
|----------|---------|
| Initial state | Yes |
| `startHeartbeat` success (immediate tick + running/result) | Yes |
| Default interval when `initialIntervalSeconds` is 0 | Yes |
| Request build failure | Yes |
| API failure | Yes |
| No internet — skips API, stays running | Yes |
| Server forced offline — `courier_online` false, `serverForcedOffline` | Yes |
| `stopHeartbeat` → `stopped` | Yes |
| `clearTransientMessage` | Yes |
| `runHeartbeatNow` skipped when inactive | Yes |
| Duplicate `startHeartbeat` — second immediate tick | Yes |
| Periodic timer — additional tick after interval | Yes |
| `stopHeartbeat` blocks further periodic ticks | Yes |
| Server `nextHeartbeatAfterSeconds` reschedules timer | Yes |
| `runHeartbeatNow` skipped while request in progress | Yes |

**Driver availability test total:** **28/28 passing** (6 + 7 + 15).

---

## 4. Current Map Status State Ownership

### Profile name display state (local — ValueNotifier)

| Field | Type | UI rebuild |
|-------|------|------------|
| `_profileNameNotifier` | `ValueNotifier<String>` | Drawer profile name `Text` via `ValueListenableBuilder<String>` |

**Loading:** `_loadProfileName()` assigns `_profileNameNotifier.value = name` when `ProfileService` returns non-empty `fullName`.

**Default:** `'Courier'` (unchanged from pre–Phase 3B behavior).

### Cubit-owned / Cubit-driven state (unchanged)

| Cubit | Role on map status screen |
|-------|---------------------------|
| `GoOnlineCubit` | Go To Online API flow; page listens and triggers post-online navigation / prefs |
| `GoOfflineCubit` | Go offline API flow |
| `HeartbeatCubit` | Periodic heartbeat while online; forced-offline handling |

Page still uses `BlocListener` / `BlocBuilder` / `context.watch` — **not moved or modified** in Phase 3B.

### Parent still owns (not extracted)

| Area | Fields / behavior |
|------|-------------------|
| Courier online | `_courierOnline`, `_kCourierOnlineKey`, `_loadCourierOnline`, `_persistCourierOnline`, `_setCourierOnline` |
| Courier type | `_cachedCourierTypeId`, freelancer offer polling gate |
| GPS / location | `_locationLoading`, `_currentPosition`, `_initializeLocation`, `_moveToMyLocation` |
| Fake offer banner | `_fakeOfferBannerVisible`, `_fakeOfferBannerTimer`, `_fakeOfferBannerHideTimer` |
| Marker icon | `_courierMarkerIcon`, `_courierMarkerIconLoading`, `_loadCourierMarkerIcon` |
| Offer lookup UI | `_offerLookupInFlight`, `_openingOfferFlow` (guard without setState) |
| Map | `_mapController`, camera animation |
| Direct use cases | `GetCurrentOfferUseCase`, `GetCurrentOrderUseCase` (page-level navigation routing) |
| Navigation | `/incoming-order`, `/active-trip`, `/orders`, `/login`, drawer routes |

---

## 5. setState Status

| Milestone | `setState` count in `courier_map_status_screen.dart` |
|-----------|------------------------------------------------------|
| Before Map Status Phase 3B | **21** |
| After Map Status Phase 3B | **20** |
| **Current (verified)** | **20** |

### What was removed (Phase 3B)

| Removed `setState` | Replaced with |
|--------------------|---------------|
| Profile name load (`_loadProfileName`) | `_profileNameNotifier.value = name` |

### What remains (intentionally untouched)

| Category | Purpose |
|----------|---------|
| Courier online load / persist | `_courierOnline` from SharedPreferences and after Cubit success |
| Cached courier type | `_cachedCourierTypeId` — gates fake offer polling |
| Location loading | `_locationLoading` in init and move-to-location |
| Current GPS position | `_currentPosition` updates |
| Fake offer banner | `_fakeOfferBannerVisible` show/hide |
| Marker icon | `_courierMarkerIcon`, `_courierMarkerIconLoading` |
| Offer lookup in-flight | `_offerLookupInFlight` during banner tap API |

---

## 6. Tests and Validation

### Automated

| Command | Result |
|---------|--------|
| `flutter test test/features/driver_availability/` | **28/28 passing** |
| `flutter test test/features/incoming/` | **23/23 passing** |
| `flutter test test/features/delivery/` | **21/21 passing** |
| `flutter analyze lib/screens/courier_map_status_screen.dart` | Pre-existing infos only (see below) |

### Analyzer notes (intentionally not fixed)

**Production (`courier_map_status_screen.dart`):**

- Deprecated `BitmapDescriptor.fromAssetImage`
- Geolocator `desiredAccuracy` / `timeLimit` deprecations (2 locations)

**Tests (`heartbeat_cubit_test.dart`):**

- Direct `fake_async` import may show `depend_on_referenced_packages` unless `fake_async` is added as an explicit `dev_dependency` in a future optional cleanup — **not required for this milestone**.

### Phase 3 validation pattern (per PR)

```bash
flutter pub get
dart format lib/screens/courier_map_status_screen.dart   # or test/ only for 3A
flutter analyze lib/screens/courier_map_status_screen.dart
flutter test test/features/driver_availability/
flutter test test/features/incoming/
flutter test test/features/delivery/
```

**Full suite:** `flutter test` may still fail on pre-existing `test/widget_test.dart` (App/DI/plugin setup) — not in Phase 3 scope.

---

## 7. Manual QA Checklist

Run on device/emulator before treating this milestone as production-ready:

- [ ] Login and reach map-status screen
- [ ] Open drawer
- [ ] Verify profile name shows default `Courier` then loaded name as before
- [ ] Verify drawer profile area layout unchanged
- [ ] Verify drawer online switch unchanged
- [ ] Verify drawer actions unchanged:
  - [ ] Profile
  - [ ] Orders
  - [ ] Notifications
  - [ ] Settings
  - [ ] Logout
- [ ] Verify Go Online behavior unchanged
- [ ] Verify Go Offline behavior unchanged
- [ ] Verify heartbeat behavior unchanged
- [ ] Verify fake offer banner unchanged (freelancer courier type)
- [ ] Verify map / current location unchanged
- [ ] Verify incoming-order / active-trip navigation unchanged
- [ ] Verify EN/AR layout unchanged

---

## 8. Known Notes / Risks

| Note | Detail |
|------|--------|
| Profile name isolated | Main map body no longer rebuilds when profile name loads; only drawer name `Text` rebuilds. |
| `_courierOnline` on setState | Tied to SharedPreferences, GoOnline/GoOffline Cubits, and Heartbeat forced-offline — **high risk** to move without dedicated plan. |
| Fake offer timers untouched | Periodic show/hide and offer tap lookup unchanged. |
| GPS / location untouched | 8+ `setState` calls in location init and move-to-location. |
| Marker icon candidate | `_courierMarkerIcon` / loading flag — possible next **display-only** ValueNotifier (2 `setState`). |
| Heartbeat characterized | 15 tests lock current Cubit behavior; production Cubit **not modified** in Phase 3B. |
| `resetStatus` on Go Online/Offline | Does **not** clear `result` on Cubit state — documented in 3A tests. |
| No map/navigation change | `GoogleMapController`, post go-online routing, and drawer callbacks unchanged. |

---

## 9. Recommended Next Step

1. **Stop map-status production refactoring temporarily** — Phase 3A + 3B milestone complete for tests and profile name.
2. **Run manual QA** on map-status drawer and online/offline flow (§7).
3. **If QA passes**, run a **planning pass** before choosing the next map-status production state target.
4. **Candidate for next tiny refactor (optional):** `_courierMarkerIcon` / `_courierMarkerIconLoading` → `ValueNotifier` (2 `setState`, map marker display only).
5. **Do not touch** without dedicated plan:
   - `_courierOnline` / SharedPreferences persistence
   - Fake offer timers and banner logic
   - GPS / location loading
   - Offer/order lookup navigation
   - Heartbeat wiring on the page

---

## 10. Suggested Next Planning Task

### Branch

`docs/phase-3-map-status-next-state-plan`

### Scope

- **Planning only** — no Dart file modifications.
- Compare remaining **20** `setState` calls in `courier_map_status_screen.dart`.
- Candidate analysis:

  | Candidate | setState (approx.) | Risk |
  |-----------|-------------------|------|
  | Marker icon state | 2 | Low — display only |
  | Location loading | 8 | High — GPS coupling |
  | Current position | 2 | High — map camera |
  | Fake offer banner | 2 | High — timers |
  | Offer lookup in-flight | 2 | Med — API + navigation |
  | Courier online | 2 | Very high — prefs + Cubits |
  | Cached courier type | 1 | Med — gates offer polling |

- Recommend: **marker icon ValueNotifier** vs **pause map-status** vs switch Phase 3 target to active-trip.
- Document test impact and manual QA per candidate.

### Deliverable

Single Markdown report under `docs/` (e.g. `phase_3_map_status_next_state_plan.md`).

---

## Appendix — Phase 3 Map Status Branch Index

| Branch | Type |
|--------|------|
| `test/phase-3-map-status-go-online-offline-cubit-characterization` | Tests (3A Part 1) |
| `test/phase-3-map-status-heartbeat-cubit-characterization` | Tests (3A Part 2) |
| `refactor/phase-3-map-status-profile-name-value-notifier` | Production (3B) |
| `docs/phase-3-map-status-milestone` | Documentation (this file) |
| `docs/phase-3-map-status-next-state-plan` | Documentation (planned — §10) |

---

*End of Phase 3 Map Status Milestone summary. No Dart production files were modified to produce this document.*
