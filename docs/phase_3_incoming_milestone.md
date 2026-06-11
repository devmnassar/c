# Phase 3 Incoming Milestone — Drawer and Reject Display State Isolated

**Branch (documentation):** `docs/phase-3-incoming-milestone-update`  
**Document date:** June 2026  
**Scope:** Incoming order page display state only — `lib/features/incoming/presentation/pages/incoming_order_page.dart`

**Related documents:**

- [phase_3_incoming_next_state_plan.md](./phase_3_incoming_next_state_plan.md)
- [phase_3_planning_report.md](./phase_3_planning_report.md)
- [phase_3_delivery_milestone.md](./phase_3_delivery_milestone.md)
- [phase_2_ui_extraction_summary.md](./phase_2_ui_extraction_summary.md)

---

## 1. Executive Summary

Phase 3 on the incoming order page was executed in three small, reversible steps:

| Step | Focus |
|------|--------|
| **Phase 3A** | Added **IncomingOrderCubit characterization tests** (23 tests) to lock current behavior before state refactors. |
| **Phase 3B** | Moved **drawer-only display state** (`_profilePhoto`, `_courierOnline`) to `ValueNotifier` and removed related `setState` calls. |
| **Phase 3C** | Moved **reject submitting display state** (`_isRejectSubmitting`) to `ValueNotifier` and removed related `setState` calls. |

**Result:** `incoming_order_page.dart` **`setState` count reduced from 11 to 7**.

**Confirmation:** No `IncomingOrderCubit` implementation, API, navigation, route path, countdown timer, accept/reject API flow, timeout behavior, map controller lifecycle, map label offsets, or `OrderMock` / `MobileOrder` / `MobileOrderOffer` mapping was **intentionally changed** during Phase 3A–3C.

This milestone is **limited to incoming page display state only** (drawer + reject button row). Countdown, expiry navigation, map labels, map user-moved flags, and marker icon state are **intentionally untouched**.

---

## 2. Changes Completed

| Phase | Branch | Change | Production behavior impact |
| ----- | ------ | ------ | -------------------------- |
| **3A** | `test/phase-3-incoming-order-cubit-characterization` | Added unit tests for `IncomingOrderCubit` under `test/features/incoming/presentation/cubit/`. Helper fixtures under `test/features/incoming/helpers/`. Uses existing dev deps: `bloc_test`, `mocktail`. | **None** — test-only PR |
| **3B** | `refactor/phase-3-incoming-drawer-display-value-notifier` | `_profilePhoto` → `_profilePhotoNotifier` (`ValueNotifier<File?>`); `_courierOnline` → `_courierOnlineNotifier` (`ValueNotifier<bool>`); `_buildOrdersDrawer()` with nested `ValueListenableBuilder`; 2 `setState` removed | **None intentional** — same `ProfileService` / `SharedPreferences` reads, same `OrdersDrawer` parameters and callbacks, same online toggle → `/map-status` navigation |
| **3C** | `refactor/phase-3-incoming-reject-submitting-value-notifier` | `_isRejectSubmitting` → `_isRejectSubmittingNotifier` (`ValueNotifier<bool>`); bottom accept/reject `Row` wrapped in `ValueListenableBuilder<bool>`; 2 `setState` removed | **None intentional** — same reject modal, `rejectCurrentOffer` call, success/failure navigation, countdown pause/resume, reject/accept disabled and spinner logic |

---

## 3. Current Incoming Page State Ownership

### Drawer display state (local — ValueNotifier)

| Field | Type | UI rebuild |
|-------|------|------------|
| `_profilePhotoNotifier` | `ValueNotifier<File?>` | `OrdersDrawer` via `_buildOrdersDrawer()` |
| `_courierOnlineNotifier` | `ValueNotifier<bool>` | `OrdersDrawer` via `_buildOrdersDrawer()` |

**Private getter (still used):**

- `bool get _courierOnline => _courierOnlineNotifier.value` — read by `_handleDrawerAvailabilityChange`

**Drawer rebuild pattern:**

- `_buildOrdersDrawer()` wraps `OrdersDrawer` in nested `ValueListenableBuilder<File?>` and `ValueListenableBuilder<bool>`
- LTR: `drawer`; RTL: `endDrawer` — both call the same builder

### Reject submitting display state (local — ValueNotifier)

| Field | Type | UI rebuild |
|-------|------|------------|
| `_isRejectSubmittingNotifier` | `ValueNotifier<bool>` | Bottom accept/reject `Row` via `ValueListenableBuilder<bool>` |

**Preserved logic (unchanged):**

- Reject disabled when `state.isSubmitting || isRejectSubmitting`
- Accept disabled when `state.isSubmitting || isRejectSubmitting`
- Reject button shows spinner when `isRejectSubmitting`
- Accept button shows Cubit submitting spinner when `state.isSubmitting && !isRejectSubmitting`
- Reject API, modal confirm/cancel, and `_resumeOfferCountdownIfNeeded()` unchanged

### Cubit state (unchanged ownership)

| Cubit | Role |
|-------|------|
| `IncomingOrderCubit` | Load current order/offer; accept delivery/pickup; reject offer; flow type and action status |

Page still creates, closes, and listens via `BlocConsumer` / `BlocBuilder` — **not moved or modified** in Phase 3A–3C.

### Parent still owns (not extracted)

| Area | Fields / behavior |
|------|-------------------|
| Countdown | `_remainingSeconds`, `_countdownTimer`, `_startCountdown`, `_stopCountdown`, `_handleExpired`, `_resumeOfferCountdownIfNeeded` |
| Accept / reject handlers | `_handleAcceptPressed`, `_showRejectModal`, reject modal content |
| Timeout | `_expiredNavigated`, expire → map-status navigation |
| Map | `_mapController`, `_userMovedMap`, `_isProgrammaticFit`, `_didInitialFit`, camera debounce |
| Map labels | `_labelOffsets`, `_labelsReady`, `_labelData`, `_updateLabelOffsets` |
| Marker icons | Nested `_IncomingOrderMap` local state (`_laundryIcon`, `_homeIcon`) |
| Drawer callbacks | Profile, orders, notifications, settings, logout, coming soon |
| Navigation | Accept → active trip; reject / expire → map-status; full-map route |
| Mapping | `OrderMock` / `MobileOrder` / `MobileOrderOffer` via existing mappers |
| Alert sound | `AlertSoundService` entry alert on offer open |

---

## 4. setState Status

| Milestone | `setState` count in `incoming_order_page.dart` |
|-----------|------------------------------------------------|
| Before Incoming Phase 3B | **11** |
| After Incoming Phase 3B | **9** |
| After Incoming Phase 3C | **7** |
| **Current (verified)** | **7** |

### What was removed

| Phase | Removed `setState` | Replaced with |
|-------|---------------------|---------------|
| **3B** | Profile photo load (`_loadProfilePhoto`) | `_profilePhotoNotifier.value = photoFile` |
| **3B** | Courier online display load (`_loadCourierOnline`) | `_courierOnlineNotifier.value = prefs.getBool(...)` |
| **3C** | Reject submitting true (`_showRejectModal`) | `_isRejectSubmittingNotifier.value = true` |
| **3C** | Reject submitting false (`_showRejectModal`) | `_isRejectSubmittingNotifier.value = false` |

### What remains (intentionally untouched)

| `setState` location | Purpose |
|---------------------|---------|
| Countdown timer tick | `_remainingSeconds--` each second |
| Offer remaining sync | `_remainingSeconds = offerRemainingSeconds` from Cubit offer |
| Map user interaction | `_userMovedMap = true` on user camera pan |
| Map reset | `_userMovedMap = false` after programmatic camera reset |
| Map label offsets (success) | `_labelOffsets`, `_labelsReady = true` after screen-coordinate projection |
| Map label offsets (error) | Clear offsets, `_labelsReady = false` on failure |
| Marker icons (nested widget) | Rebuild after async marker icon load |

**Breakdown:** 6 `setState` calls in `_IncomingOrderPageState`, 1 in nested map widget (`_IncomingOrderMapState` marker icon load).

---

## 5. Tests and Validation

### Automated

| Command | Result |
|---------|--------|
| `flutter test test/features/incoming/` | **23/23 passing** |
| `flutter test test/features/delivery/` | **21/21 passing** |
| `flutter analyze lib/features/incoming/presentation/pages/incoming_order_page.dart` | Pre-existing issues only (see below) |

### IncomingOrderCubit characterization coverage (Phase 3A)

- Initial state
- `loadCurrentOrder` — `showEmptyState`, `initialOffer`, `initialOrder`, API success/failure/empty, `loadCurrentOfferOnOpen`, duplicate load guard
- Accept delivery/pickup — full-time and freelancer flows
- Reject offer — success, failure, null-offer guard

### Analyzer notes (intentionally not fixed)

- Unused `_buildServiceChips` (pre-existing)
- 2× `use_build_context_synchronously` (pre-existing)

### Phase 3 validation pattern (per PR)

```bash
flutter pub get
dart format lib/features/incoming/presentation/pages/incoming_order_page.dart   # or test/ only for 3A
flutter analyze lib/features/incoming/presentation/pages/incoming_order_page.dart
flutter test test/features/incoming/
flutter test test/features/delivery/
```

**Full suite:** `flutter test` may still fail on pre-existing `test/widget_test.dart` (App/DI/plugin setup) — not in Phase 3 scope.

---

## 6. Manual QA Checklist

Run on device/emulator before treating this milestone as production-ready:

- [ ] Open incoming order page with an offer
- [ ] Open drawer
- [ ] Verify profile photo displays as before
- [ ] Verify courier online display/toggle area displays as before
- [ ] Tap Reject
- [ ] Verify reject dialog opens as before
- [ ] Cancel reject and verify countdown resumes if applicable
- [ ] Reject again and confirm
- [ ] Verify reject spinner appears on reject button
- [ ] Verify accept button disabled while reject submitting
- [ ] Verify reject success returns to map-status
- [ ] Verify reject failure resumes countdown if applicable
- [ ] Verify accept flow unchanged
- [ ] Verify timeout behavior unchanged
- [ ] Verify countdown ticks correctly
- [ ] Verify map and full-map navigation unchanged
- [ ] Verify drawer actions unchanged:
  - [ ] Profile
  - [ ] Orders
  - [ ] Notifications
  - [ ] Settings
  - [ ] Logout
- [ ] Verify EN/AR layout unchanged

---

## 7. Known Notes / Risks

| Note | Detail |
|------|--------|
| Drawer-only rebuild scope | Profile photo and courier online load no longer trigger a full page `setState`; only `OrdersDrawer` rebuilds via `ValueListenableBuilder`. |
| Reject submitting isolated | Reject API call no longer triggers full page rebuild; only the bottom accept/reject row rebuilds. |
| `_courierOnline` getter retained | `_handleDrawerAvailabilityChange` still compares against current online value before navigating to `/map-status`. |
| Countdown untouched | Timer tick, expire navigation, and offer sync from Cubit remain on `setState` — **high risk** due to timeout/navigation coupling. |
| Map label state untouched | Label offsets tied to `GoogleMapController`, camera fit, and throttle — defer until dedicated map phase. |
| Map user-moved untouched | `_userMovedMap` and reset control remain on `setState` — coupled to label refresh chain. |
| Marker icon local setState | One isolated nested-widget rebuild after asset load; **acceptable to leave as-is** unless pursuing cosmetic zero-`setState`. |
| No Cubit changes | `IncomingOrderCubit` behavior characterized by 23 tests; production Cubit **not modified** in Phase 3B/3C. |
| Other mega-screens | `delivery_to_customer_page.dart`, `courier_map_status_screen.dart`, `active_trip_page.dart` **not touched**. |

---

## 8. Recommended Next Step

1. **Stop incoming production refactoring temporarily** — Phase 3A + 3B + 3C milestone is complete for safe display-state isolation.
2. **Run manual QA** on the incoming page (§6).
3. **Do not touch countdown or map labels** without a dedicated plan (see [phase_3_incoming_next_state_plan.md](./phase_3_incoming_next_state_plan.md)).
4. **Choose next Phase 3 target via planning only** — either:
   - **Map-status** Phase 3 planning (21 `setState`, GPS/offer coupling), or
   - **Active-trip** test-first planning (15 `setState`, status-machine risk).
5. **Prefer documentation/planning before any production changes** on remaining incoming `setState` (countdown, map) or other mega-screens.

**Do not start:**

- Incoming countdown controller extraction
- Incoming map label / user-moved ValueNotifier work
- Cubit rewrites on incoming page
- RoutePaths / AppColors wiring

---

## 9. Suggested Next Planning Task

### Branch

`docs/phase-3-next-target-after-incoming`

### Scope

- **Planning only** — no Dart file modifications.
- Compare **map-status** (`courier_map_status_screen.dart`, 21 `setState`) vs **active-trip** (`active_trip_page.dart`, 15 `setState`) as the next Phase 3 target.
- Recommend test-first approach for either screen (characterization tests before state refactors).
- Document risk categories, existing Cubit coverage gaps, and manual QA scope per screen.
- Do **not** recommend touching incoming countdown/map state in the same planning pass unless explicitly scoped.

### Deliverable

Single Markdown report under `docs/` (e.g. `phase_3_next_target_after_incoming.md`).

---

## Appendix — Phase 3 Incoming Branch Index

| Branch | Type |
|--------|------|
| `test/phase-3-incoming-order-cubit-characterization` | Tests (3A) |
| `refactor/phase-3-incoming-drawer-display-value-notifier` | Production (3B) |
| `refactor/phase-3-incoming-reject-submitting-value-notifier` | Production (3C) |
| `docs/phase-3-incoming-milestone` | Documentation (initial) |
| `docs/phase-3-incoming-milestone-update` | Documentation (this file) |
| `docs/phase-3-incoming-next-state-plan` | Documentation (remaining setState analysis) |
| `docs/phase-3-next-target-after-incoming` | Documentation (planned — §9) |

---

*End of Phase 3 Incoming Milestone summary. No Dart production files were modified to produce this document.*
