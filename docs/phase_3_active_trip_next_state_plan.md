# Phase 3 Active Trip Next State Plan

**Branch (documentation):** `docs/phase-3-active-trip-next-state-plan`  
**Document date:** June 2026  
**Scope:** Planning only — remaining `setState` in `lib/features/trip/presentation/pages/active_trip_page.dart`

**Related documents:**

- [phase_3_map_status_milestone.md](./phase_3_map_status_milestone.md)
- [phase_3_map_status_next_state_plan.md](./phase_3_map_status_next_state_plan.md)
- [phase_3_incoming_next_state_plan.md](./phase_3_incoming_next_state_plan.md)
- [phase_3_delivery_milestone.md](./phase_3_delivery_milestone.md)
- [phase_3_planning_report.md](./phase_3_planning_report.md)

---

## 1. Executive Summary

### Current Active Trip state after Phase 3A

| Item | Status |
|------|--------|
| **PickupStatusCubit tests** | **11/11 passing** (Phase 3A — test-only) |
| **`active_trip_page.dart` setState count** | **15** (unchanged) |
| **Production refactors on active trip** | **None** |
| **Driver availability / incoming / delivery tests** | 28 / 23 / 21 passing (unchanged) |

### PickupStatusCubit behavior now characterized

| Behavior | Finding |
|----------|---------|
| Duplicate-request guard | **None** — concurrent `submitStatus` calls both proceed |
| Proof upload gate | Runs only when `proofPhotoPath` is non-empty **and** `proofPhotoType` is non-null |
| File validation | **Existence only** inside Cubit; no size/extension checks |
| GPS on upload | Best-effort; Geolocator errors → `latitude`/`longitude` passed as `null` |
| Reset API | **`reset()` only** — no `clearError` / `clearMessage` |

### Page vs Cubit split

| Layer | Responsibility |
|-------|----------------|
| **PickupStatusCubit** | Pickup status API + optional proof upload (pickup flow) |
| **`active_trip_page.dart`** | Delivery rider status via direct `UpdateRiderStatusUseCase`, GPS stream, route polyline, map labels, order sync, `DeliveryToCustomerPage` navigation, local status integers |

### Recommendation

**Continue Active Trip Phase 3 with exactly one more safe production PR:** move **`_laundryIcon` / `_homeIcon`** to `ValueNotifier` (Active Trip **Phase 3B**).

**Then pause active-trip production refactoring** and create **`docs/phase_3_active_trip_milestone.md`**.

All remaining **14** `setState` calls after Phase 3B are order sync, GPS stream, route polyline, status machine, delivery update guard, map labels, or pickup-confirmation transition — **none are safe** for ad-hoc ValueNotifier extraction without page/integration tests and a dedicated plan.

**Do not** attempt `_isUpdatingRiderStatus`, transition guards, order/loading, GPS, route polyline, rider/pickup status integers, or map labels in the next PR.

**Prerequisite:** Manual QA on active-trip pickup flow (PickupStatusCubit + map) before merging Phase 3B.

---

## 2. Remaining setState Inventory

Verified against `active_trip_page.dart` (June 2026). **15** `setState` occurrences.

| # | Location / method | State changed | Category | Risk | Notes |
|---|-------------------|---------------|----------|------|-------|
| 1 | `_loadOrder()` (~L166) | `_order`, `_loading`, `_isCurrentActiveOrder`; calls `_applyStepStateFromOrder` (delivery/pickup status ints + full-time step flags) | Order / loading + rider/pickup status | **High** | Initial route order or session; triggers `_maybePrepareInitialMap()` |
| 2 | `_loadIcons()` (~L233) | `_laundryIcon`, `_homeIcon` | Marker icons | **Low** | Async `loadMarkerIcon`; used for map marker display with `defaultMarker` fallback |
| 3 | `_initLocation()` last known (~L248) | `_currentPosition` | GPS / current position | **High** | Triggers `_maybePrepareInitialMap()` |
| 4 | `_initLocation()` getCurrentPosition (~L258) | `_currentPosition` | GPS / current position | **High** | May call `_recenterMap()` + `_fetchOrderRoute` |
| 5 | `_positionSubscription` listen (~L272) | `_currentPosition` | GPS / current position | **Very high** | Geolocator stream; calls `_updateLabelOffsets()` + `_fetchOrderRoute` every tick |
| 6 | `_fetchOrderRoute()` (~L294) | `_routePolyline`, optionally `_initialMapReady` | Route polyline + map ready | **Very high** | `DirectionsService.getDrivingRoutePoints`; gates `GoogleMap` visibility (`_initialMapReady`) |
| 7 | `_syncCurrentOrder()` no match (~L471) | `_loading`, `_isCurrentActiveOrder` | Order / loading | **High** | Order null or wrong id |
| 8 | `_syncCurrentOrder()` success (~L493) | `_order`, `_loading`, `_isCurrentActiveOrder`, full-time step flags, `_deliveryRiderStatus` / `_pickupRiderStatus` | Order / loading + rider/pickup status | **Very high** | Merges live order; triggers navigation handlers + map prep |
| 9 | `_advanceDeliveryRiderStatus()` start (~L615) | `_isUpdatingRiderStatus = true` | Status update guard | **Med–High** | Guarded by `if (_isUpdatingRiderStatus) return`; uses `UpdateRiderStatusUseCase` directly (not Cubit) |
| 10 | `_advanceDeliveryRiderStatus()` success (~L642) | `_deliveryRiderStatus`, `_useFullTimeInitialDeliveryStep` | Rider status integers | **Very high** | Delivery status machine step advance |
| 11 | `_advanceDeliveryRiderStatus()` finally (~L651) | `_isUpdatingRiderStatus = false` | Status update guard | **Med–High** | Clears busy flag for primary action button |
| 12 | `_updateLabelOffsets()` (~L762) | `_labelOffsets`, `_labelsReady = true` | Map labels | **High** | Async `getScreenCoordinate` per label; throttled 150 ms; triggered from GPS stream |
| 13 | `_submitPickupStatus()` after Cubit success (~L932) | `_useFullTimeInitialPickupStep`, `_pickupRiderStatus` | Rider/pickup status integers | **Very high** | Local pickup step advance after `PickupStatusCubit.submitStatus`; may `_fetchOrderRoute` |
| 14 | `_openPickupConfirmationPage()` push (~L953) | `_isTransitioningToPickupConfirmation = true` | Transition guards | **High** | Before `Navigator.push` → `DeliveryToCustomerPage`; shows overlay |
| 15 | `_openPickupConfirmationPage()` `.then` (~L988) | `_isTransitioningToPickupConfirmation = false` | Transition guards | **High** | After page closes; `_openedPickupConfirmationPage` reset **without** setState |

**Non-setState guards (for context):**

- `_openedDeliveryConfirmationPage` — assigned directly (~L684, ~L705); opens `DeliveryToCustomerPage` for delivery completion
- `_openedPickupConfirmationPage` — assigned directly (~L952, ~L986); prevents duplicate pickup confirmation push

**Category totals:**

| Category | setState calls |
|----------|----------------|
| Marker icons | 1 |
| GPS / current position | 3 |
| Route polyline (+ map ready) | 1 |
| Order / loading | 3 (rows 1, 7, 8 — row 1 also sets status) |
| Rider/pickup status integers | 4 (embedded in rows 1, 8, 10, 13) |
| Status update guard (`_isUpdatingRiderStatus`) | 2 |
| Map labels | 1 |
| Transition guards | 2 |

---

## 3. Candidate Analysis

### A. Marker icon state (`_laundryIcon`, `_homeIcon`)

| Aspect | Detail |
|--------|--------|
| **setState involved** | **1** (both icons in `_loadIcons`) |
| **Where used** | `currentMarkerIcon` in `build()` (~L1383–1385); `GoogleMap` markers for current stop |
| **Map coupling** | Display only — falls back to `BitmapDescriptor.defaultMarker` until loaded |
| **ValueNotifier safe?** | **Yes** — mirrors map-status Phase 3C and incoming nested `_IncomingOrderMapState._loadIcons` pattern |
| **QA needed** | Laundry/home markers appear; fallback before load; EN/AR unchanged |
| **Risks** | Wrap only marker-bearing `GoogleMap` subtree; dispose notifiers; preserve `_loadIcons()` from `initState` |

| Verdict | |
|---------|---|
| **Safe now?** | **Yes** |
| **Recommended phase** | **Phase 3B** (next and last safe active-trip production PR) |
| **Why** | Single low-risk display change; PickupStatusCubit tests do not block this |

---

### B. `_isUpdatingRiderStatus`

| Aspect | Detail |
|--------|--------|
| **setState involved** | **2** (true before API, false after) |
| **Where used** | `_advanceDeliveryRiderStatus` guard; `isActionBusy` with `pickupState.isSubmitting` (~L1409–1410) |
| **Coupling** | Direct `UpdateRiderStatusUseCase` on page — **not** covered by PickupStatusCubit tests |
| **ValueNotifier safe?** | **Maybe later** — mechanically similar to incoming `_isRejectSubmitting` / delivery submit flags |
| **QA needed** | Delivery primary button disabled/spinner; pickup + delivery busy interaction |
| **Risks** | Delivery status machine; post-success `_syncCurrentOrder` and `_fetchOrderRoute` |

| Verdict | |
|---------|---|
| **Safe now?** | **Later** |
| **Recommended phase** | **Phase 3C+** after delivery-rider-status characterization or page tests |
| **Why** | Med risk; different code path from characterized PickupStatusCubit |

---

### C. Transition guards (`_openedDeliveryConfirmationPage`, `_openedPickupConfirmationPage`, `_isTransitioningToPickupConfirmation`)

| Aspect | Detail |
|--------|--------|
| **setState involved** | **2** (only `_isTransitioningToPickupConfirmation`; open flags are direct assignment) |
| **Coupling** | `Navigator.push` → `DeliveryToCustomerPage`; pickup proof + `onPickupConfirm` → `_submitPickupStatus` |
| **ValueNotifier safe?** | **No** without navigation integration tests |
| **Risks** | Double-push prevention; overlay visibility; `context.go('/map-status')` on delivery complete |

| Verdict | |
|---------|---|
| **Safe now?** | **No** |
| **Recommended phase** | **Much later** — DeliveryToCustomerPage integration phase |
| **Why** | Navigation side effects; user-facing transition overlay |

---

### D. Order / loading state (`_order`, `_loading`, `_isCurrentActiveOrder`)

| Aspect | Detail |
|--------|--------|
| **setState involved** | **3** (load order, sync no-match, sync success) |
| **Coupling** | `GetCurrentOrderUseCase`, `OrderSessionStore`, full-time orders-list flow, `_handleDeliveryScreenNavigation` / `_handlePickupScreenNavigation` |
| **ValueNotifier safe?** | **No** |
| **Risks** | Entire page body depends on order; sync updates status integers inline |

| Verdict | |
|---------|---|
| **Safe now?** | **No** |
| **Recommended phase** | **Much later** — order sync / Cubit extraction phase |
| **Why** | Core page data model |

---

### E. GPS / current position (`_currentPosition`)

| Aspect | Detail |
|--------|--------|
| **setState involved** | **3** (last known, initial fix, stream ticks) |
| **Coupling** | Geolocator stream (`distanceFilter: 5`); `_recenterMap`, `_fetchOrderRoute`, `_updateLabelOffsets`, courier marker position |
| **ValueNotifier safe?** | **No** |
| **Risks** | High-frequency stream rebuilds; map camera and polyline refresh on every tick |

| Verdict | |
|---------|---|
| **Safe now?** | **No** |
| **Recommended phase** | **Later** — dedicated GPS/map sub-plan (same deferral as map-status) |
| **Why** | Highest-frequency setState source on this page |

---

### F. Route polyline state (`_routePolyline`, `_initialMapReady`)

| Aspect | Detail |
|--------|--------|
| **setState involved** | **1** (also sets `_initialMapReady` when `markMapReady: true`) |
| **Coupling** | `DirectionsService`; gates whether `GoogleMap` renders (`_initialMapReady && courierLatLng != null`) |
| **ValueNotifier safe?** | **No** |
| **Risks** | Map visibility + polyline draw + straight-line fallback |

| Verdict | |
|---------|---|
| **Safe now?** | **No** |
| **Recommended phase** | **Later** — with GPS/map phase |
| **Why** | Controls map mount, not display-only |

---

### G. Rider / pickup status integers (`_deliveryRiderStatus`, `_pickupRiderStatus`, full-time step flags)

| Aspect | Detail |
|--------|--------|
| **setState involved** | **4** across load, sync, delivery advance, pickup submit |
| **Coupling** | Status machine UI (buttons, labels, navigation to confirmation pages); integer constants `_pickupStatus*` / `_riderStatus*` |
| **ValueNotifier safe?** | **No** |
| **Risks** | Wrong step → wrong API status or navigation; pickup uses Cubit, delivery uses direct use case |

| Verdict | |
|---------|---|
| **Safe now?** | **No** |
| **Recommended phase** | **Much later** — status machine redesign or Cubit consolidation |
| **Why** | Core business logic on page |

---

### H. Map labels (`_labelOffsets`, `_labelsReady`)

| Aspect | Detail |
|--------|--------|
| **setState involved** | **1** |
| **Coupling** | `GoogleMapController.getScreenCoordinate`; triggered from GPS stream; same pattern as incoming order page (deferred there) |
| **ValueNotifier safe?** | **Maybe later** |
| **Risks** | Overlay positioning; throttle logic; empty catch swallows coordinate failures |

| Verdict | |
|---------|---|
| **Safe now?** | **No** |
| **Recommended phase** | **Later** — shared map-label planning with incoming |
| **Why** | Controller + GPS coupling |

---

## 4. Risk Comparison Table

Conservative assessment. **Test coverage** = automated tests relevant to the candidate.

| Candidate | setState removed | Risk | Business impact | Test coverage | Recommendation |
|-----------|------------------|------|-----------------|----------------|---------------|
| **A. Marker icons** | 1 → **14 remain** | **Low** | Low — map marker appearance | 11 PickupStatusCubit tests; none page-level | **Do next (Phase 3B)** |
| **B. `_isUpdatingRiderStatus`** | 2 | **Med–High** | High — delivery primary action | None for delivery path on page | **Defer** |
| **C. Transition guards** | 2 | **High** | High — pickup confirmation UX | None | **Do not touch** |
| **D. Order / loading** | 3 | **Very high** | Critical — page content | None | **Do not touch** |
| **E. GPS / position** | 3 | **Very high** | Critical — map + route | None | **Defer** |
| **F. Route polyline** | 1 | **Very high** | High — map visibility + route | None | **Defer** |
| **G. Rider/pickup status ints** | 4 | **Very high** | Critical — status machine | 11 PickupStatusCubit tests (pickup API only) | **Do not touch** |
| **H. Map labels** | 1 | **High** | Med — label overlays | None | **Defer** |
| **Pause → milestone doc** | 0 | **Low** | None | — | **Do after Phase 3B** |
| **Add page/integration tests first** | 0 | **Low** | None | Would help all high-risk areas | **Optional parallel track** |

---

## 5. Recommended Next PR

**Chosen:** **Implement marker icon ValueNotifier** (Active Trip Phase 3B).

| Criterion | Met? |
|-----------|------|
| Small | Yes — 1 file, 1 `setState` removed, 15 → **14** |
| Reversible | Yes — revert single PR |
| No Cubit behavior changes | Yes |
| No API / status integer changes | Yes |
| No navigation changes | Yes |
| No GPS/stream changes | Yes |
| No map controller movement | Yes |
| No route polyline changes | Yes |
| No DeliveryToCustomerPage changes | Yes |

**Not chosen (and why):**

| Alternative | Why not now |
|-------------|-------------|
| Pause → milestone doc only | Valid **after** Phase 3B; marker icon is the only zero-risk production win |
| Add more tests first | PickupStatusCubit characterized; delivery-rider tests would help `_isUpdatingRiderStatus` later, not marker icons |
| No production changes | Only if manual QA bandwidth is zero — marker PR is still very low risk |

**Stop line after Phase 3B:** Do not continue active-trip production refactors until milestone doc is written and team approves GPS/status-machine targets.

---

## 6. Exact Prompt Draft for Next PR

### Phase 3B — Active Trip marker icon ValueNotifier

```
You are a Senior Flutter Developer working on a production courier Flutter app.

We completed Active Trip Phase 3A (11 PickupStatusCubit tests).

Planning report: docs/phase_3_active_trip_next_state_plan.md

Implement **Active Trip Phase 3B only** — one small production refactor.

**Branch:** `refactor/phase-3-active-trip-marker-icon-value-notifier`

**VERY IMPORTANT — DO NOT CHANGE:**

- PickupStatusCubit implementation, wiring, or states
- UpdateRiderStatusUseCase / GetCurrentOrderUseCase usage
- APIs, repositories, models, DTOs
- Navigation, route paths, DeliveryToCustomerPage push/pop
- GPS / Geolocator / `_initLocation` / position stream
- GoogleMapController lifecycle, camera fit, `_recenterMap`
- Route polyline / DirectionsService / `_fetchOrderRoute`
- Rider/pickup status integers, status machine, `_advanceDeliveryRiderStatus`
- `_isUpdatingRiderStatus`, transition guards, order sync
- `_labelOffsets`, map labels
- delivery_to_customer_page.dart, incoming_order_page.dart, courier_map_status_screen.dart
- Do NOT fix unrelated analyzer warnings

**Goal:** Move active trip map marker icon display state to ValueNotifier.

**File:** `lib/features/trip/presentation/pages/active_trip_page.dart` only

**Scope:**

1. Replace `BitmapDescriptor? _laundryIcon` and `_homeIcon` with:
   `ValueNotifier<BitmapDescriptor?> _laundryIconNotifier` and
   `ValueNotifier<BitmapDescriptor?> _homeIconNotifier` (initial null).
2. Update `_loadIcons()` to assign notifier values (no setState).
3. Dispose both notifiers in `dispose()`.
4. Remove the 1 marker-related setState in `_loadIcons` (~L233).
5. Rebuild marker icon selection only:
   - Wrap the smallest subtree that needs `currentMarkerIcon` / `GoogleMap` markers
   - Use `ValueListenableBuilder` for one or both notifiers
   - Preserve `defaultMarker` fallback behavior
   - Do NOT wrap order sheet, action buttons, or PickupStatusCubit listeners

**Expected setState count:** 15 → 14

**Validation:**

```bash
flutter pub get
dart format lib/features/trip/presentation/pages/active_trip_page.dart
flutter analyze lib/features/trip/presentation/pages/active_trip_page.dart
flutter test test/features/trip/
flutter test test/features/driver_availability/
flutter test test/features/incoming/
flutter test test/features/delivery/
```

**Manual QA:**

- [ ] Open active trip (pickup and delivery orders)
- [ ] Laundry/home markers appear on map (or defaultMarker before load)
- [ ] Map route / GPS / labels unchanged
- [ ] Pickup status buttons and delivery rider status buttons unchanged
- [ ] Pickup confirmation → DeliveryToCustomerPage unchanged
- [ ] EN/AR layout unchanged

**Rollback:** Revert branch; setState returns to 15.

**Final response:** setState before/after, files changed, confirmation no forbidden areas touched,
recommended next step (pause production; write active-trip milestone doc).
```

---

### After Phase 3B — Milestone documentation prompt

```
You are a Senior Flutter Architect working on a production courier Flutter app.

Active Trip Phase 3A (PickupStatusCubit tests) and Phase 3B (marker icon ValueNotifier) are complete.

Create **documentation only** on branch `docs/phase-3-active-trip-milestone`.

**File:** docs/phase_3_active_trip_milestone.md

**Include:**
- Phase 3A test summary (11 PickupStatusCubit tests)
- Phase 3B production change (marker icons; setState 15 → 14)
- Remaining 14 setState categories
- Manual QA checklist
- Confirmation: pause active-trip production refactoring
- Link to phase_3_active_trip_next_state_plan.md for deferred targets

**Do NOT modify any Dart file.**
```

---

## 7. Open Questions

| Question | Guidance |
|----------|----------|
| Should marker icons be moved before pausing Active Trip? | **Yes** — one setState, proven pattern from map-status 3C; then pause. |
| Should status machine work require widget/integration tests first? | **Yes** — rider/pickup integers and `_advanceDeliveryRiderStatus` are very high risk; PickupStatusCubit unit tests cover pickup API only. |
| Should GPS stream work be a separate map/GPS phase? | **Yes** — treat GPS (3) + route (1) + labels (1) as one deferred bundle with incoming/map-status GPS items. |
| Should DeliveryToCustomerPage navigation guards remain untouched until integration tests? | **Yes** — transition guards and `_opened*ConfirmationPage` flags control push to delivery/pickup proof flow. |
| Should PickupStatusCubit lack of duplicate guard be addressed later or only documented? | **Document only for now** — changing guard behavior is a Cubit production change requiring explicit product approval and new tests; not a Phase 3 display refactor. |
| Should delivery rider status move to a Cubit? | **Out of Phase 3 scope** — page uses `UpdateRiderStatusUseCase` directly; consolidation is a separate architecture decision. |
| After Phase 3B, continue active trip or switch target? | **Pause active trip production** — write milestone doc; next Phase 3 target TBD by team (no other screen has pending 3A tests). |

---

## Appendix — setState Distribution Summary

```
Total: 15
├── Marker icons (LOW)              1  ← Phase 3B target
├── Status update guard               2  ← defer
├── Transition guards                 2  ← do not touch
├── Map labels                        1  ← defer
├── Route polyline + map ready        1  ← defer
├── GPS / current position            3  ← defer
├── Order / loading (+ status in load) 3  ← do not touch
└── Rider/pickup status (in sync/advance/submit) ← embedded above
                                    --
After Phase 3B:                    14
```

---

*End of Phase 3 Active Trip Next State Plan. No Dart production files were modified to produce this document.*
