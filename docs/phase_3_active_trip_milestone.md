# Phase 3 Active Trip Milestone — Cubit Tests and Marker Icon State Isolated

**Branch (documentation):** `docs/phase-3-active-trip-milestone`  
**Document date:** June 2026  
**Scope:** Active trip page — `lib/features/trip/presentation/pages/active_trip_page.dart` and `PickupStatusCubit`

**Related documents:**

- [phase_3_active_trip_next_state_plan.md](./phase_3_active_trip_next_state_plan.md)
- [phase_3_map_status_milestone.md](./phase_3_map_status_milestone.md)
- [phase_3_incoming_milestone.md](./phase_3_incoming_milestone.md)
- [phase_3_delivery_milestone.md](./phase_3_delivery_milestone.md)
- [phase_3_planning_report.md](./phase_3_planning_report.md)

---

## 1. Executive Summary

Phase 3 on the active trip screen was executed in two small, reversible steps:

| Step | Focus |
|------|--------|
| **Phase 3A** | Added **PickupStatusCubit** characterization tests (**11** tests). |
| **Phase 3B** | Moved **map marker icon display state** (`_laundryIcon`, `_homeIcon`) to `ValueNotifier` and removed related `setState`. |

**Result:** `active_trip_page.dart` **`setState` count reduced from 15 to 14**.

**Confirmation:** No `PickupStatusCubit` implementation, API, navigation, route path, rider/pickup status integer logic, status machine, GPS/Geolocator stream, route polyline, `GoogleMapController` lifecycle, map labels, order sync, or `DeliveryToCustomerPage` navigation was **intentionally changed** during Phase 3A–3B.

This milestone is **limited to PickupStatusCubit characterization tests and marker icon display state only**. Order loading, GPS stream, route polyline, status machine, delivery rider updates, transition guards, and map labels remain **untouched**.

**Production refactoring on active trip is now paused.** Remaining state is high risk and intentionally deferred.

---

## 2. Changes Completed

| Phase | Branch | Change | Production behavior impact |
| ----- | ------ | ------ | -------------------------- |
| **3A** | `test/phase-3-active-trip-cubit-characterization` | Added unit tests for `PickupStatusCubit` in `test/features/trip/presentation/cubit/pickup_status_cubit_test.dart`. Helper fixtures in `test/features/trip/helpers/trip_cubit_test_helpers.dart`. Uses existing dev deps: `bloc_test`, `mocktail`. | **None** — test-only PR |
| **3B** | `refactor/phase-3-active-trip-marker-icon-value-notifier` | `_laundryIcon` / `_homeIcon` → `_laundryIconNotifier` / `_homeIconNotifier`; nested `ValueListenableBuilder` around `GoogleMap` destination marker icon; 1 `setState` removed from `_loadIcons()` | **None intentional** — same assets, same `loadMarkerIcon`, same `defaultMarker` fallback, same map marker IDs/positions |

---

## 3. Test Coverage Added

### PickupStatusCubit (11 tests)

| Scenario | Covered |
|----------|---------|
| Initial state | Yes |
| `submitStatus` success without proof photo | Yes |
| `submitStatus` failure without proof photo | Yes |
| Missing proof file — failure, no upload/update | Yes |
| Upload failure — stops before status update | Yes |
| Upload success → status update success | Yes |
| Upload success → status update failure | Yes |
| Skips upload when `proofPhotoType` is null | Yes |
| Skips upload when `proofPhotoPath` is empty/whitespace | Yes |
| No duplicate-request guard — concurrent calls both proceed | Yes |
| `reset()` returns to initial state | Yes |

### Behavior notes (characterized, not changed)

| Behavior | Detail |
|----------|--------|
| **No duplicate-request guard** | Overlapping `submitStatus` calls both proceed; `lastSubmittedStatus` reflects the latest call |
| **Proof upload gate** | Upload runs only when `proofPhotoPath` is non-empty **and** `proofPhotoType` is non-null |
| **File validation** | Cubit checks file **existence** only — no size/extension validation (unlike `DeliveryCompletionCubit`) |
| **GPS on upload** | Best-effort via `_tryGetCurrentPosition()`; Geolocator errors → `latitude`/`longitude` passed as `null` |
| **Reset API** | **`reset()` only** — no `clearError` / `clearMessage` / `resetStatus` |

**Active trip test total:** **11/11 passing**.

---

## 4. Current Active Trip State Ownership

### Marker icon display state (local — ValueNotifier)

| Field | Type | UI rebuild |
|-------|------|------------|
| `_laundryIconNotifier` | `ValueNotifier<BitmapDescriptor?>` | Nested `ValueListenableBuilder` around `GoogleMap` marker icon selection |
| `_homeIconNotifier` | `ValueNotifier<BitmapDescriptor?>` | Same builders; laundry vs home chosen by `currentMapStop.type` |

**Loading:** `_loadIcons()` from `initState` assigns both notifiers after `loadMarkerIcon('assets/markers/ic_laundry.png')` and `loadMarkerIcon('assets/markers/ic_home.png')`.

**Fallback:** `BitmapDescriptor.defaultMarker` until icons load (unchanged).

### Cubit-owned / Cubit-driven state (unchanged)

| Cubit | Role on active trip page |
|-------|--------------------------|
| `PickupStatusCubit` | Pickup status API + optional proof upload; page uses `BlocListener` / `BlocBuilder` for submit busy state and error SnackBars |

Delivery rider status still uses **`UpdateRiderStatusUseCase` directly on the page** (`_advanceDeliveryRiderStatus`) — not moved or modified in Phase 3B.

### Parent still owns (not extracted)

| Area | Fields / behavior |
|------|-------------------|
| Order / loading | `_order`, `_loading`, `_isCurrentActiveOrder`, `_syncCurrentOrder`, `_loadOrder` |
| GPS / position | `_currentPosition`, `_initLocation`, Geolocator position stream |
| Route | `_routePolyline`, `_initialMapReady`, `_fetchOrderRoute`, `DirectionsService` |
| Map controller | `_mapController`, `_recenterMap`, `_runInitialFitOnce`, camera fit |
| Rider status (delivery) | `_deliveryRiderStatus`, `_useFullTimeInitialDeliveryStep`, `_advanceDeliveryRiderStatus` |
| Pickup status (local ints) | `_pickupRiderStatus`, `_useFullTimeInitialPickupStep`, `_submitPickupStatus` post-Cubit `setState` |
| Status update guard | `_isUpdatingRiderStatus` |
| Transition guards | `_openedDeliveryConfirmationPage`, `_openedPickupConfirmationPage`, `_isTransitioningToPickupConfirmation` |
| Navigation | `DeliveryToCustomerPage` push (pickup proof + delivery complete), `context.go('/map-status')` |
| Map labels | `_labelOffsets`, `_labelsReady`, `_updateLabelOffsets` |
| Actions | Chat, call, directions, order details sheet |
| Use cases (page-level) | `GetCurrentOrderUseCase`, `UpdateRiderStatusUseCase` |

---

## 5. setState Status

| Milestone | `setState` count in `active_trip_page.dart` |
|-----------|---------------------------------------------|
| Before Active Trip Phase 3B | **15** |
| After Active Trip Phase 3B | **14** |
| **Current (verified)** | **14** |

### What was removed (Phase 3B)

| Removed `setState` | Replaced with |
|--------------------|---------------|
| Marker icon load in `_loadIcons()` | `_laundryIconNotifier.value` / `_homeIconNotifier.value` |

### What remains (intentionally untouched)

| Category | setState calls (approx.) | Purpose |
|----------|--------------------------|---------|
| Order / loading | 3 | Initial load, sync no-match, sync success |
| GPS / current position | 3 | Last known, initial fix, stream ticks |
| Route polyline (+ map ready) | 1 | Directions + `_initialMapReady` |
| Rider / pickup status integers | 4 (embedded in load/sync/advance/submit) | Status machine steps |
| Status update guard | 2 | `_isUpdatingRiderStatus` true/false |
| Transition guards | 2 | `_isTransitioningToPickupConfirmation` overlay |
| Map labels | 1 | `_labelOffsets`, `_labelsReady` |

---

## 6. Tests and Validation

### Automated

| Command | Result |
|---------|--------|
| `flutter test test/features/trip/` | **11/11 passing** |
| `flutter test test/features/driver_availability/` | **28/28 passing** |
| `flutter test test/features/incoming/` | **23/23 passing** |
| `flutter test test/features/delivery/` | **21/21 passing** |
| `flutter analyze lib/features/trip/presentation/pages/active_trip_page.dart` | Pre-existing issues only (see below) |

### Full suite note

`flutter test` may still fail on pre-existing `test/widget_test.dart` (App/DI/plugin setup) — not in Phase 3 scope.

### Analyzer notes (intentionally not fixed)

**Production (`active_trip_page.dart`):**

- Unnecessary underscores in `PageRouteBuilder` (`_, __, ___`)
- Unused local variable `targetStop`

### Phase 3 validation pattern (per PR)

```bash
flutter pub get
dart format lib/features/trip/presentation/pages/active_trip_page.dart   # or test/ only for 3A
flutter analyze lib/features/trip/presentation/pages/active_trip_page.dart
flutter test test/features/trip/
flutter test test/features/driver_availability/
flutter test test/features/incoming/
flutter test test/features/delivery/
```

---

## 7. Manual QA Checklist

Run on device/emulator before treating this milestone as production-ready:

- [ ] Login and reach active trip screen
- [ ] Verify laundry/home markers appear on map
- [ ] Verify default marker fallback before icon load is unchanged if observable
- [ ] Verify map route unchanged
- [ ] Verify GPS/current position behavior unchanged
- [ ] Verify map labels unchanged
- [ ] Verify pickup status buttons unchanged
- [ ] Verify delivery rider status buttons unchanged
- [ ] Verify primary status action unchanged
- [ ] Verify pickup confirmation → DeliveryToCustomerPage unchanged
- [ ] Verify delivery confirmation → DeliveryToCustomerPage unchanged
- [ ] Verify chat/call/directions/details unchanged
- [ ] Verify EN/AR layout unchanged

---

## 8. Known Notes / Risks

| Note | Detail |
|------|--------|
| Marker icons isolated | Only the `GoogleMap` subtree rebuilds when icons load; order sheet, actions, and Cubit listeners unchanged |
| **14 setState remain — high risk** | GPS stream, route polyline, status machine, order sync, labels, transition guards |
| GPS / position | Treat as dedicated GPS/map phase — 3 setState + stream side effects (`_fetchOrderRoute`, `_updateLabelOffsets`) |
| Route polyline | Do not touch without map/route tests — controls `_initialMapReady` and map visibility |
| Status machine | Rider/pickup integers drive buttons, navigation, and API calls — requires dedicated tests and product approval |
| DeliveryToCustomerPage guards | `_opened*ConfirmationPage` and transition overlay — leave until integration tests exist |
| PickupStatusCubit duplicate guard | **Document only** — no guard today; changing behavior requires explicit approval and new tests |
| Delivery vs pickup split | Pickup uses Cubit; delivery uses page-level `UpdateRiderStatusUseCase` — consolidation is out of Phase 3 scope |

---

## 9. Safe Initial Refactor Stop Point

**We are intentionally stopping the safe initial refactor here.**

### Completed safe scope

| Phase | Scope |
|-------|--------|
| **Phase 1** | Foundation files (constants, routes, theme helpers) |
| **Phase 2** | UI-only widget extraction |
| **Phase 3** | Cubit characterization tests + low-risk `ValueNotifier` display-state isolation |

**Phase 3 screens completed:**

| Screen | Tests | Production setState change | Final setState (page) |
|--------|-------|----------------------------|------------------------|
| Delivery | 21 Cubit tests | Multiple ValueNotifier PRs | **0** |
| Incoming | 23 Cubit tests | Profile/online/reject submitting | **7** |
| Map Status | 28 availability tests | Profile name + marker icon | **18** |
| Active Trip | 11 Cubit tests | Marker icon only | **14** |

### Do not continue production refactoring into (without new approved phase + dedicated tests)

- GPS / location / position streams
- Countdown timers
- Map labels / `getScreenCoordinate` overlays
- Route polyline / `DirectionsService`
- Fake offer timers (map status)
- Courier online / heartbeat page wiring (map status)
- Active trip status machine (rider/pickup integers, `_advanceDeliveryRiderStatus`)
- `DeliveryToCustomerPage` navigation guards
- PickupStatusCubit duplicate-request guard behavior change

---

## 10. Recommended Next Step

1. **Stop production refactoring** — safe initial boundary reached.
2. **Run full manual QA** across the courier flow:
   - Map status (online/offline, drawer, fake offer banner)
   - Incoming order (accept/reject, countdown, map)
   - Active trip (pickup + delivery paths, map, status buttons)
   - Delivery confirmation (`DeliveryToCustomerPage`)
3. **Merge milestone docs** (delivery, incoming, map status, active trip).
4. **Optional:** Create a single **`docs/phase_3_safe_initial_refactor_summary.md`** consolidating all four screen milestones and stop-point decision.
5. **Any future deep refactor** must start as a **new phase** with planning document + tests first — no ad-hoc `setState` or Cubit changes on high-risk areas.

---

## Appendix — Active Trip Branch Index

| Branch | Type |
|--------|------|
| `test/phase-3-active-trip-cubit-characterization` | Tests (3A) |
| `refactor/phase-3-active-trip-marker-icon-value-notifier` | Production (3B) |
| `docs/phase-3-active-trip-next-state-plan` | Planning |
| `docs/phase-3-active-trip-milestone` | Documentation (this file) |

---

## Appendix — Cross-Reference: Phase 3 Milestone Documents

| Screen | Milestone doc |
|--------|---------------|
| Delivery | [phase_3_delivery_milestone.md](./phase_3_delivery_milestone.md) |
| Incoming | [phase_3_incoming_milestone.md](./phase_3_incoming_milestone.md) |
| Map Status | [phase_3_map_status_milestone.md](./phase_3_map_status_milestone.md) |
| Active Trip | This document |

---

*End of Phase 3 Active Trip Milestone summary. No Dart production files were modified to produce this document.*
