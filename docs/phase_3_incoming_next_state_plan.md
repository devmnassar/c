# Phase 3 Incoming Next State Plan

**Branch (documentation):** `docs/phase-3-incoming-next-state-plan`  
**Document date:** June 2026  
**Scope:** Planning only — remaining `setState` in `lib/features/incoming/presentation/pages/incoming_order_page.dart`

**Related documents:**

- [phase_3_incoming_milestone.md](./phase_3_incoming_milestone.md)
- [phase_3_delivery_milestone.md](./phase_3_delivery_milestone.md)
- [phase_3_planning_report.md](./phase_3_planning_report.md)

---

## 1. Executive Summary

### Current state after Phase 3A / 3B

| Item | Status |
|------|--------|
| **IncomingOrderCubit tests** | 23/23 passing (Phase 3A — test-only) |
| **Drawer display state** | `_profilePhotoNotifier`, `_courierOnlineNotifier` + `_buildOrdersDrawer()` (Phase 3B) |
| **`setState` count** | **9** (down from 11) |
| **Cubit / API / navigation** | Unchanged intentionally |

### Already moved (Phase 3B)

- `_profilePhoto` → `ValueNotifier<File?>`
- `_courierOnline` → `ValueNotifier<bool>`

### Still on `setState` (9 calls)

| Category | Calls |
|----------|-------|
| Countdown | 2 |
| Reject submitting | 2 |
| Map user-moved flag | 2 |
| Map label offsets / ready | 2 |
| Marker icon load (nested widget) | 1 |

### Recommendation

**Continue incoming Phase 3 with one safe target:** move **`_isRejectSubmitting`** to `ValueNotifier<bool>` (incoming Phase 3C).

**Do not pause** the incoming screen yet — one more small PR mirrors the proven delivery Phase 3C pattern (2 `setState` → 0 for that flag, localized button rebuild).

**Defer** countdown, map user-moved, map label offsets, and marker icons until after Phase 3C QA — or until a dedicated map/countdown planning pass is approved.

**Do not switch** to map-status or active trip for the *next implementation PR*; those screens remain higher risk (21 and 15 `setState` respectively, with GPS/status-machine coupling).

---

## 2. Remaining setState Inventory

Verified against `incoming_order_page.dart` (June 2026).

| # | Location / method | State changed | Category | Risk | Notes |
|---|-------------------|---------------|----------|------|-------|
| 1 | `_startCountdown()` → `Timer.periodic` callback (~L400) | `_remainingSeconds--` | Countdown timer tick | **High** | Fires every second; triggers `_handleExpired()` at zero → dialog + `context.go('/map-status')` |
| 2 | `BlocConsumer` `listener` (~L612) | `_remainingSeconds = offerRemainingSeconds` | Offer remaining sync | **High** | Syncs from `state.offer.remainingSeconds`; may call `_startCountdown()` when timer null |
| 3 | `_showRejectModal()` after confirm (~L1094) | `_isRejectSubmitting = true` | Reject submitting | **Low–Med** | Only freelancer offer path; before `cubit.rejectCurrentOffer()` |
| 4 | `_showRejectModal()` after API (~L1098) | `_isRejectSubmitting = false` | Reject submitting | **Low–Med** | In `finally`-like position; on success navigates to `/map-status`; on failure calls `_resumeOfferCountdownIfNeeded()` |
| 5 | `_resetCamera()` (~L529) | `_userMovedMap = false` | Map reset / user moved false | **High** | After programmatic camera reset; calls `_updateLabelOffsets()` |
| 6 | `onCameraMoveStarted` on `_IncomingOrderMap` (~L775) | `_userMovedMap = true` | Map user moved flag | **High** | Skipped when `_isProgrammaticFit`; drives `IncomingMapControls.showReset` |
| 7 | `_updateLabelOffsets()` success (~L571–575) | `_labelOffsets`, `_labelsReady = true` | Map label offsets | **High** | Async `getScreenCoordinate` per label; throttled 150 ms; parent `build` passes offsets to map stack |
| 8 | `_updateLabelOffsets()` catch (~L578–581) | `_labelOffsets` clear, `_labelsReady = false` | Map label offsets | **High** | Clears overlays on controller/coordinate failure |
| 9 | `_IncomingOrderMapState._loadIcons()` (~L1182) | Full rebuild (icons loaded) | Marker icon load | **Low** | Isolated nested `State`; `_laundryIcon` / `_homeIcon` from assets; falls back to default markers until loaded |

**Owner split:**

- **`_IncomingOrderPageState`:** 8 `setState` calls (rows 1–8)
- **`_IncomingOrderMapState`:** 1 `setState` call (row 9)

---

## 3. Candidate Analysis

### A. `_isRejectSubmitting`

| Aspect | Detail |
|--------|--------|
| **setState involved** | **2** (true before API, false after) |
| **Where used** | Reject `OutlinedButton` disabled state, reject button spinner, accept `FilledButton` disabled state, accept button distinguishes Cubit `isSubmitting` vs reject spinner |
| **Reject modal relation** | Set only **after** user confirms dialog (`confirmed == true`); dialog itself has no submitting state |
| **Countdown relation** | Countdown **stopped** when reject button pressed (`_stopCountdown()` before `_showRejectModal`); on reject failure or dialog cancel → `_resumeOfferCountdownIfNeeded()` — **independent** of `_isRejectSubmitting` flag |
| **ValueNotifier safe?** | **Yes** — same pattern as delivery `_isPickupSubmittingNotifier`; wrap bottom button row only |
| **QA needed** | Reject spinner on freelancer offer; accept disabled during reject; reject failure resumes countdown; reject success → map-status |
| **Risks** | Must keep `state.isSubmitting \|\| _isRejectSubmitting` logic identical; must not change Cubit reject flow |

| Verdict | |
|---------|---|
| **Safe now?** | **Yes** |
| **Recommended phase** | **Phase 3C** (next PR) |
| **Why** | Smallest reversible win; Cubit reject behavior already covered by 23 tests; no timer/map/controller coupling |

---

### B. Marker icon load in nested `_IncomingOrderMap`

| Aspect | Detail |
|--------|--------|
| **setState involved** | **1** (`setState(() {})` after async `loadMarkerIcon`) |
| **Isolation** | **Fully isolated** inside `_IncomingOrderMapState`; parent page unaffected |
| **ValueNotifier worth it?** | **Marginal** — removes 1 call but requires notifier + dispose + builder inside nested widget only |
| **QA needed** | Custom laundry/home markers appear; fallback markers before load; EN/AR map unchanged |
| **Risks** | Low functional risk; easy to revert; low ROI vs reject flag |

| Verdict | |
|---------|---|
| **Safe now?** | **Yes**, but low priority |
| **Recommended phase** | **Optional 3D or leave alone** |
| **Why** | Display-only, already scoped to nested widget; acceptable as permanent local `setState` |

---

### C. Countdown `_remainingSeconds`

| Aspect | Detail |
|--------|--------|
| **setState involved** | **2** (timer tick + Cubit offer sync) |
| **Timer ownership** | Parent owns `_countdownTimer`, `_startCountdown`, `_stopCountdown`, `_resumeOfferCountdownIfNeeded` |
| **Expiry navigation** | `_handleExpired()` → non-dismissible dialog → `context.go('/map-status')` (with/without `autoSearch` extra) |
| **UI coupling** | `AcceptCountdownTimer` in `OrderHeaderLabelRow`; also gates accept/reject via `_stopCountdown` on press |
| **Defer?** | **Yes — strongly** |

| Verdict | |
|---------|---|
| **Safe now?** | **No** |
| **Recommended phase** | **Dedicated countdown phase (3E+)** or controller extracted with characterization tests first |
| **Why** | Business-critical timeout path; timer + Cubit sync + navigation; widget tests absent |

---

### D. Map user moved / reset flags

| Aspect | Detail |
|--------|--------|
| **setState involved** | **2** (`true` on user pan, `false` on reset) |
| **Camera / reset** | `_resetCamera` uses `_initialBounds`; `_isProgrammaticFit` prevents false “user moved” on programmatic moves |
| **GoogleMapController risk** | Controller owned by parent; callbacks wired through `_IncomingOrderMap` |
| **UI coupling** | `IncomingMapControls.showReset`, `onReset` → `_resetCamera` → triggers label update |
| **Defer?** | **Yes** |

| Verdict | |
|---------|---|
| **Safe now?** | **No** |
| **Recommended phase** | **Map sub-phase (3F+)** — bundle with label offsets or map controls ValueNotifier |
| **Why** | Tied to controller lifecycle and label refresh chain |

---

### E. Map label offsets / `_labelsReady`

| Aspect | Detail |
|--------|--------|
| **setState involved** | **2** (success batch update + error clear) |
| **Mechanism** | Async screen-coordinate projection; 150 ms throttle; debounced on `onCameraMove` |
| **Risk** | Mis-timed rebuild → label drift, flicker, or missing overlays on RTL/full-map |
| **Defer?** | **Yes** |

| Verdict | |
|---------|---|
| **Safe now?** | **No** |
| **Recommended phase** | **Dedicated map-label phase** — possibly never on parent; consider keeping on map subtree |
| **Why** | Highest coupling in incoming page after countdown; original Phase 3 planning flagged incoming map as **High** risk |

---

## 4. Risk Comparison Table

| Candidate | setState removed | Risk | Business impact | Test coverage | Recommendation |
|-----------|------------------|------|-----------------|----------------|----------------|
| **`_isRejectSubmitting` → ValueNotifier** | **2** | **Low–Med** | Reject UX only; navigation unchanged if logic preserved | Cubit reject flows in 23 tests; **no widget tests** for button row | **Do next (Phase 3C)** |
| **Marker icons → ValueNotifier** | **1** | **Low** | Cosmetic marker swap after asset load | None | **Optional / defer / leave alone** |
| **Countdown `_remainingSeconds`** | **2** | **High** | Offer expiry, auto navigation, accept/reject timing | Cubit offer seconds only; **no page timer tests** | **Defer** |
| **Map `_userMovedMap`** | **2** | **High** | Reset control visibility and camera UX | None | **Defer** |
| **Map labels / `_labelsReady`** | **2** | **High** | Stop label overlay positioning | None | **Defer** |
| **Pause incoming → switch screen** | 0 | Med (context switch) | Shifts effort to map-status (21) or active trip (15) | Delivery 21; Incoming 23 | **Not for next PR** |
| **Add widget/page tests first** | 0 | Low | Improves safety before countdown/map | N/A | **Optional parallel**; not blocking 3C |

---

## 5. Recommended Next PR

### Choice: **Implement `_isRejectSubmitting` ValueNotifier** (Incoming Phase 3C)

| Criterion | Meets? |
|-----------|--------|
| Small | Yes — ~2 `setState` removed, localized to button row |
| Reversible | Yes — single-file revert |
| No Cubit behavior changes | Yes |
| No API changes | Yes |
| No navigation changes | Yes |
| No countdown changes | Yes — do not touch timer methods |
| No map controller movement | Yes — do not touch map block |

**Expected outcome:** `setState` count **9 → 7** (8 → 6 in `_IncomingOrderPageState`).

**Not chosen:**

| Alternative | Why not now |
|-------------|-------------|
| Marker icon ValueNotifier | Low ROI; 1 isolated call is acceptable |
| Pause + switch screen | Incoming still has one low-risk win aligned with delivery milestone |
| More tests first | Cubit coverage sufficient for reject API; widget tests valuable but not required for this flag |

---

## 6. Exact Prompt Draft for Next PR

Use this prompt for **Incoming Phase 3C**:

---

You are a Senior Flutter Developer working on a production courier Flutter app.

We completed Incoming Phase 3A (Cubit tests) and 3B (drawer ValueNotifiers).

Now implement **Incoming Phase 3C only**.

**Branch:** `refactor/phase-3-incoming-reject-submitting-value-notifier`

**VERY IMPORTANT — do NOT change:**

- `IncomingOrderCubit` or its state/methods
- API calls, use cases, repositories, models
- Navigation (accept → active trip; reject / expire → map-status; full map route)
- Route paths
- Countdown timer (`_remainingSeconds`, `_countdownTimer`, `_startCountdown`, `_stopCountdown`, `_handleExpired`, `_resumeOfferCountdownIfNeeded`)
- Reject modal content / confirm flow (only replace submitting flag rebuild mechanism)
- Map logic, label offsets, `_userMovedMap`, `GoogleMapController` lifecycle
- Drawer notifiers (`_profilePhotoNotifier`, `_courierOnlineNotifier`)
- `OrdersDrawer`, `OrderMock` / `MobileOrder` / `MobileOrderOffer` mapping
- `delivery_to_customer_page.dart`, `courier_map_status_screen.dart`, `active_trip_page.dart`
- Do not wire RoutePaths, BusinessConstants, AppColors, or l10n_context_extension
- Do not extract new widgets
- Do not fix unrelated analyzer warnings
- Do not format unrelated files

**Target file:** `lib/features/incoming/presentation/pages/incoming_order_page.dart`

**Goal:** Move `_isRejectSubmitting` to `ValueNotifier<bool>`.

**Implementation:**

1. Replace `bool _isRejectSubmitting = false` with `final ValueNotifier<bool> _isRejectSubmittingNotifier = ValueNotifier<bool>(false)` and optional getter `bool get _isRejectSubmitting => _isRejectSubmittingNotifier.value`.
2. In `_showRejectModal`, replace both `setState` assignments with `_isRejectSubmittingNotifier.value = true/false`.
3. Dispose notifier in `dispose()`.
4. Wrap **only** the bottom button `Row` (reject + accept) in `ValueListenableBuilder<bool>` listening to `_isRejectSubmittingNotifier`.
5. Preserve exact disabled/spinner logic: `state.isSubmitting || _isRejectSubmitting`, reject spinner vs accept Cubit spinner.

**Validation:**

```bash
flutter pub get
dart format lib/features/incoming/presentation/pages/incoming_order_page.dart
flutter analyze lib/features/incoming/presentation/pages/incoming_order_page.dart
flutter test test/features/incoming/
flutter test test/features/delivery/
```

**Manual QA:**

- [ ] Freelancer offer: tap Reject → confirm → spinner on reject button; accept disabled
- [ ] Reject success → map-status
- [ ] Reject failure → countdown resumes if applicable
- [ ] Cancel reject dialog → countdown resumes
- [ ] Accept flow unchanged
- [ ] Countdown tick and expiry unchanged
- [ ] Map / drawer unchanged
- [ ] EN/AR unchanged

**Rollback:** Revert single file to restore `setState` for reject flag.

---

### If pausing instead (not recommended for next step)

Planning prompt for **map-status Phase 3**:

- Branch: `docs/phase-3-map-status-next-state-plan`
- Inventory 21 `setState` in `courier_map_status_screen.dart`
- Compare GPS stream, offer lookup guards, heartbeat, and map camera categories
- Recommend test-first vs display-only ValueNotifier first
- **Do not modify Dart files**

---

## 7. Open Questions

| Question | Recommendation |
|----------|----------------|
| **Should reject submitting move before or after reject modal widget tests?** | **Before widget tests.** Cubit tests already characterize `rejectCurrentOffer`. Modal is stateless confirm UI; submitting flag is page-local display. Add widget tests later if countdown/map work begins. |
| **Should countdown state move to a controller later?** | **Yes, if at all** — prefer a small `IncomingOfferCountdownController` (or similar) with explicit start/stop/sync API **after** widget or integration tests exist for expiry navigation. Not a bare ValueNotifier swap. |
| **Should map label state be handled in a dedicated map phase?** | **Yes.** Treat labels + user-moved + camera debounce as one **map sub-phase**; do not mix with reject or countdown PRs. |
| **Should marker icon local setState be considered acceptable and left alone?** | **Yes.** One isolated nested-widget rebuild after asset load is idiomatic and low risk. Only touch if pursuing “zero setState on incoming page” as a cosmetic goal after all high-value items are done. |

---

## Appendix — Projected setState Roadmap (Incoming)

| Phase | Target | setState after | Status |
|-------|--------|----------------|--------|
| 3A | Cubit tests | 11 | Done |
| 3B | Drawer display | 9 | Done |
| **3C** | **`_isRejectSubmitting`** | **7** | **Recommended next** |
| 3D (optional) | Marker icons | 6 | Optional / skip |
| 3E+ | Countdown | 5 or fewer | Defer — needs plan + tests |
| 3F+ | Map flags + labels | 0–1 | Defer — dedicated map phase |

---

*End of Phase 3 Incoming Next State Plan. No Dart production files were modified to produce this document.*
