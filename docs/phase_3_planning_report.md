# Phase 3 Planning Report — State Ownership & setState Reduction

**Branch (documentation):** `docs/phase-3-planning-report`  
**Document date:** June 2026  
**Prior work:** Phase 1 foundations, Phase 2 UI-only extraction ([phase_2_ui_extraction_summary.md](./phase_2_ui_extraction_summary.md))

**Confirmation:** This report is analysis and planning only. **No Dart production files were modified** to produce it.

---

## 1. Executive Summary

### What Phase 3 is intended to solve

Phase 2 reduced visual duplication by extracting 16 stateless widgets. The four parent screens remain **mega-screens** (~1,214–2,140 lines each) with mixed responsibilities: local `setState`, Cubit listeners, map/GPS lifecycle, timers, SharedPreferences, and direct use-case calls (on map-status and active trip).

Phase 3 should **clarify and improve state ownership** so that:

1. Each piece of mutable state has an explicit owner (screen, Cubit, or small local controller).
2. `setState` is reduced where safe — especially for UI-only or isolated local state — without changing API, navigation, or business rules.
3. The team can later extract Cubits/controllers with tests and clear boundaries.

### Why Phase 3 must be planned before implementation

| Risk if skipped | Example |
|-----------------|---------|
| Accidental API/navigation change | Moving delivery submit into a widget |
| Map/GPS regression | Extracting `GoogleMapController` too early |
| Status machine corruption | Splitting active trip primary CTA state |
| Untested Cubit refactor | No baseline tests before moving photo/submit state |

The four screens differ widely in `setState` density (4 vs 21) and coupling. A single “Phase 3 PR” across all screens would be unsafe.

### Phase 3 must NOT start with Cubit rewrites

Existing Cubits (`DeliveryCompletionCubit`, `AttemptedDeliveryChecklistCubit`, `IncomingOrderCubit`, `GoOnlineCubit`, etc.) already own submission and checklist answers. Phase 3 should **not** rewrite them, merge them, or change their public APIs in the first PRs. Optional later work may introduce **small private controllers** (`ValueNotifier`, `ChangeNotifier`) or **documented state holders** before any new Cubit extraction.

### Recommended safest first Phase 3 target

**Phase 3A — characterization tests for delivery Cubits** (test-only PR, no production behavior change).

Rationale: The repo has almost no feature tests (`test/widget_test.dart` only). Delivery has the **lowest `setState` count (4)** but **highest completion-flow risk** (photos + deliver + attempted delivery). Tests lock behavior before any photo-state or `ValueNotifier` work.

**First state-ownership implementation PR (Phase 3B):** Delivery page photo lists via `ValueNotifier<List<XFile>>` + `ValueListenableBuilder` — eliminates 2 of 4 `setState` calls without moving capture/upload/submit logic.

---

## 2. Phase 3 Scope Guardrails

Strict rules for every Phase 3 implementation PR:

| Rule | Detail |
|------|--------|
| No API endpoint changes | Same URLs, methods, headers |
| No payload/response parsing changes | Mappers and models unchanged |
| No route changes | Same paths, same `extra` shapes |
| No OrderMock / MobileOrder migration | Data layer deferred |
| No file movement to final architecture | Stay in current paths |
| No BusinessConstants / RoutePaths / AppColors wiring | Unless separately approved adoption PR |
| No deletion of legacy/dead code | e.g. `_buildServiceChips` stays until cleanup PR |
| No large Cubit rewrites | No merging delivery + checklist Cubits |
| No status integer changes | Rider/pickup status values and progression unchanged |
| No map controller / GPS lifecycle movement in first Phase 3 PR | Map blocks deferred to map-focused phase |
| Small and reversible PRs | One concern per branch; easy revert |

**Allowed in early Phase 3:**

- `ValueNotifier` / `ValueListenableBuilder` for local lists/flags
- Private helper classes **in the same file** holding state + notify
- Unit/widget tests with mocked use cases
- Documentation comments describing ownership (minimal, same PR as state change)

**Not allowed in early Phase 3:**

- New public Cubits replacing screen orchestration
- Moving `BlocConsumer` listeners out of screen
- Extracting `_buildStep2` / primary CTA / accept-reject row
- SharedPreferences consolidation across screens

---

## 3. Per-Screen State Ownership Inventory

### 3.1 Delivery Page

| | |
|--|--|
| **File** | `lib/features/delivery/delivery_to_customer_page.dart` |
| **Current lines** | **1,526** |
| **Main responsibilities** | Multi-step delivery/pickup confirmation; proof photo capture; attempted-delivery checklist dialog; customer call/chat; delivery completion via Cubits; navigation to map-status |

**Existing Cubits**

| Cubit | Role |
|-------|------|
| `DeliveryCompletionCubit` | Deliver + attempt delivery (upload + rider status) |
| `AttemptedDeliveryChecklistCubit` | Load/submit checklist; holds question answers |

**Use cases called directly from screen**

- None — only `getIt<DeliveryCompletionCubit>()` and `getIt<AttemptedDeliveryChecklistCubit>()`

**Local state by category**

| Category | Variables / getters |
|----------|---------------------|
| **UI display** | Widget constructor props (customer, building, notes, hanger); `_resolveL10n` |
| **Photo state** | `_buildingPhotos`, `_orderPhotos` (`List<XFile>`), `_picker`, `_maxRequiredBuildingPhotos` |
| **Business / validation** | `_isProofPhotoRequired`, `_canDeliver` (getter from photos + widget flags) |
| **Submission / loading** | `_isPickupSubmitting`; `_isAnySubmitting`, `_isDelivering`, `_isAttemptingDelivery` (derived from Cubit + pickup flag) |
| **Cubit instances** | `_deliveryCompletionCubit`, `_attemptedDeliveryChecklistCubit` (page-owned lifecycle) |
| **Checklist** | Answers in **Cubit state** (`AttemptedDeliveryChecklistState.questions`); not local `setState` |
| **Dialogs** | `_showCantReachDialog`, `_showSelectedPhotos`, `_showImageViewer` (orchestration in parent) |
| **Navigation** | `context.go('/map-status')`, `Navigator.push` to chat, dialog pop |
| **Map/GPS / timers** | None |

**Must remain in parent for now**

- Cubit create/close/listen (`BlocConsumer` on `DeliveryCompletionCubit`)
- Photo capture (`ImagePicker.pickImage`) and submit path selection
- `_onDeliveredTap`, pickup `onPickupConfirm` callback
- Checklist dialog orchestration and `_submitChecklistAnswers`
- All navigation and validation getters tied to submit

**May be safe to move later (Phase 3B/C)**

- `_buildingPhotos` / `_orderPhotos` → `ValueNotifier` or private `DeliveryPhotoSelectionHolder` (same file)
- `_isPickupSubmitting` → `ValueNotifier<bool>` (same file)

**Must not move before tests**

- Photo lists (submit uses first building photo path)
- `_canDeliver` logic
- Anything inside `_showCantReachDialog` / deliver tap chain

---

### 3.2 Map Status Screen

| | |
|--|--|
| **File** | `lib/screens/courier_map_status_screen.dart` |
| **Current lines** | **1,214** |
| **Main responsibilities** | Full-screen map; go online/offline; heartbeat; freelancer offer polling banner; current order/offer routing; drawer; SharedPreferences online flag |

**Existing Cubits (via `context.read`, not page-owned)**

| Cubit | Role |
|-------|------|
| `GoOnlineCubit` | Go online API + state |
| `GoOfflineCubit` | Go offline |
| `HeartbeatCubit` | Heartbeat start/stop |

**Use cases called directly from screen**

| Use case | Usage |
|----------|--------|
| `GetCurrentOrderUseCase` | Active order lookup when opening offer flow |
| `GetCurrentOfferUseCase` | Fake offer banner polling |

**Local state by category**

| Category | Variables |
|----------|-----------|
| **UI display** | `_profileName`, `_courierMarkerIcon`, `_courierMarkerIconLoading`, `_fakeOfferBannerVisible`, `_locationLoading` |
| **Business / cached** | `_courierOnline`, `_cachedCourierTypeId`, `_kCourierOnlineKey` |
| **Map/GPS** | `_mapController`, `_currentPosition` |
| **Timers** | `_fakeOfferBannerTimer`, `_fakeOfferBannerHideTimer` |
| **Submission / guards** | `_offerLookupInFlight`, `_openingOfferFlow` (guards without `setState`) |
| **Navigation** | `context.go` to incoming-order, active-trip, login; offer flow opening |
| **Other** | `_scaffoldKey`, `widget.autoSearch` |

**Must remain in parent for now**

- Entire go-online/offline + heartbeat listener chain
- Fake offer timer loop and offer navigation
- SharedPreferences read/write for `_courierOnline`
- Geolocator permission + position updates
- `GoogleMapController` lifecycle

**May be safe to move later**

- `_profileName` loading → `ValueNotifier` or `FutureBuilder` wrapper (display only)
- Marker icon loading flags (display only) — low priority

**Must not move before tests / dedicated plan**

- `_courierOnline` + persistence (tied to Cubit listeners)
- Timer + offer lookup pipeline
- Location initialization and `_moveToMyLocation`

---

### 3.3 Incoming Order Page

| | |
|--|--|
| **File** | `lib/features/incoming/presentation/pages/incoming_order_page.dart` |
| **Current lines** | **1,451** |
| **Main responsibilities** | Offer/current order display; accept/reject; countdown; map with labels; drawer; timeout → map-status |

**Existing Cubits**

| Cubit | Role |
|-------|------|
| `IncomingOrderCubit` | Load order/offer; accept/reject API; flow type |

**Use cases called directly from screen**

- None — all API via `IncomingOrderCubit`

**Local state by category**

| Category | Variables |
|----------|-----------|
| **Countdown / timers** | `_remainingSeconds`, `_countdownTimer`, `_kCountdownTotalSeconds` |
| **Map/GPS** | `_mapController`, `_labelOffsets`, `_labelData`, `_initialBounds`, `_mapWidth`, `_mapHeight`, `_didInitialFit`, `_userMovedMap`, `_isProgrammaticFit`, `_cameraMoveDebounce` |
| **UI display** | `_labelsReady`, `_profilePhoto`, `_courierOnline` (drawer display), marker icons (in map widget state) |
| **Submission** | `_isRejectSubmitting` |
| **Navigation guards** | `_expiredNavigated`, `_didStartEntryAlert`, `_handleBackToMapStatus` |
| **Business** | Order/offer from Cubit state; `_shouldUseOfferCountdown` |

**Must remain in parent for now**

- Countdown start/stop/sync with offer + `_handleExpired`
- Accept/reject handlers and post-accept navigation
- Map fit/reset and label offset math
- `IncomingOrderCubit` `BlocConsumer` / load on init

**May be safe to move later**

- `_profilePhoto` + `_courierOnline` (drawer-only display from prefs/profile)
- `_isRejectSubmitting` → derive from Cubit `actionStatus` if aligned (reduces duplicate flag)

**Must not move before tests**

- Countdown timer and expiry navigation
- Label overlay updates tied to map camera
- Accept/reject flow

---

### 3.4 Active Trip Page

| | |
|--|--|
| **File** | `lib/features/trip/presentation/pages/active_trip_page.dart` |
| **Current lines** | **2,140** |
| **Main responsibilities** | Live trip map; rider/pickup status progression; order sync; directions polyline; delivery/pickup confirmation navigation; chat/call/directions |

**Existing Cubits**

| Cubit | Role |
|-------|------|
| `PickupStatusCubit` | Pickup proof upload + status update (page-owned instance) |

**Use cases called directly from screen**

| Use case | Usage |
|----------|--------|
| `GetCurrentOrderUseCase` | Sync current order from API |
| `UpdateRiderStatusUseCase` | Delivery rider status progression |

**Also:** `DirectionsService` (not a use case), `CourierProfileLocalDataSource` (cached courier type)

**Local state by category**

| Category | Variables |
|----------|-----------|
| **Order / business** | `_order`, `_loading`, `_isCurrentActiveOrder`, `_cachedCourierTypeId` |
| **Status integers** | `_deliveryRiderStatus`, `_pickupRiderStatus`, `_useFullTimeInitialDeliveryStep`, `_useFullTimeInitialPickupStep`, `_isUpdatingRiderStatus` |
| **Map/GPS** | `_mapController`, `_currentPosition`, `_positionSubscription`, `_routePolyline`, `_labelOffsets`, `_labelData`, `_labelsReady`, `_initialMapReady`, `_didInitialFit`, `_mapWidth`, `_mapHeight`, `_lastLabelUpdateTime` |
| **Transition guards** | `_openedDeliveryConfirmationPage`, `_openedPickupConfirmationPage`, `_isTransitioningToPickupConfirmation` |
| **UI assets** | `_laundryIcon`, `_homeIcon` |
| **Cubit** | `_pickupStatusCubit` (created in `initState`, closed in `dispose`) |

**Must remain in parent for now**

- Status machine getters (`_effectiveDeliveryRiderStatus`, primary CTA handler)
- GPS stream subscription and polyline fetch
- `DeliveryToCustomerPage` push/pop and transition guards
- Order load/sync and `OrderSessionStore.upsert`
- Map controller dispose

**May be safe to move later**

- Marker icon loading (`_laundryIcon`, `_homeIcon`) — same pattern as incoming
- `_loading` + `_order` display split (only after order-sync tests)

**Must not move before tests + dedicated plan**

- Rider/pickup status integers and `_applyStepStateFromOrder`
- `_positionSubscription` and label throttle
- Primary status button and `_updateRiderStatusUseCase` calls

---

## 4. setState Inventory

Counts verified by static inspection of current workspace files (June 2026).

### Summary table

| File | setState count | Main categories | Risk | Candidate for reduction? |
|------|----------------|-----------------|------|---------------------------|
| `delivery_to_customer_page.dart` | **4** | photo (2), submission flag (2) | Medium | **Yes** (photos + pickup flag) |
| `courier_map_status_screen.dart` | **21** | map/GPS (8), location loading (8), business/cached (3), UI/timer banner (4) | High | **Later** |
| `incoming_order_page.dart` | **11** | timer (1), map/labels (4), UI display (3), submission (2), marker icons (1) | High | **Later** |
| `active_trip_page.dart` | **15** | map/GPS (5), API/order (3), status business (5), labels (1), transition (2) | Very high | **No** (early Phase 3) |

### 4.1 Delivery — 4 setState calls

| Location | Category | Description |
|----------|----------|-------------|
| `_capturePhoto` | Photo state | Add to `_buildingPhotos` or `_orderPhotos` |
| `_removePhoto` | Photo state | Remove at index |
| `_onDeliveredTap` (pickup path) | Submission flag | `_isPickupSubmitting = true` |
| `_onDeliveredTap` `finally` | Submission flag | `_isPickupSubmitting = false` |

**Note:** Delivery completion and checklist UI updates use **Cubit `emit`**, not page `setState`.

### 4.2 Map status — 21 setState calls

| Category | Count (approx.) | Examples |
|----------|-----------------|----------|
| Location loading | 8 | `_initializeLocation`, `_moveToMyLocation` |
| Map/GPS position | 2 | `_currentPosition` updates |
| Business / cached | 3 | `_courierOnline`, `_cachedCourierTypeId` |
| UI display | 4 | `_profileName`, `_courierMarkerIcon`, banner visible/hidden |
| API / offer UI | 2 | `_offerLookupInFlight` |
| Timer-driven UI | 2 | Show/hide fake offer banner |

**Guards without setState:** `_openingOfferFlow` (bool only).

### 4.3 Incoming — 11 setState calls

| Category | Count | Examples |
|----------|-------|----------|
| Timer tick | 1 | `_remainingSeconds--` |
| Map / labels | 4 | `_userMovedMap`, `_labelOffsets`, `_labelsReady`, reset fit |
| UI display | 3 | `_courierOnline`, `_profilePhoto`, marker icon reload |
| API / action UI | 2 | `_isRejectSubmitting` |
| Offer sync | 1 | Reset `_remainingSeconds` from offer |

### 4.4 Active trip — 15 setState calls

| Category | Count | Examples |
|----------|-------|----------|
| Map/GPS | 5 | Initial position, stream updates, polyline |
| API / order | 3 | `_loadOrder`, `_syncCurrentOrder` |
| Business / status | 5 | Rider status update, pickup status, full-time flags |
| Map labels | 1 | `_labelOffsets` batch update |
| Transition guards | 2 | `_isTransitioningToPickupConfirmation` |

---

## 5. Cubit / Controller Candidate Analysis

*Proposals for future work only — not implemented in Phase 3 planning.*

### 5.1 Delivery

| Candidate | Responsibility | Inputs | Outputs | Absorbs | Stays in parent | Risk | Phase |
|-----------|----------------|--------|---------|---------|-----------------|------|-------|
| **DeliveryPhotoSelectionHolder** (`ValueNotifier`) | Building + order photo lists | `XFile` from capture | Listenable lists | `_buildingPhotos`, `_orderPhotos`, 2 setState | Capture, remove API, `_canDeliver`, submit | Low | **3B** |
| **DeliveryPickupSubmitNotifier** | Pickup-only submitting flag | bool | `ValueNotifier<bool>` | `_isPickupSubmitting`, 2 setState | Pickup callback, Cubit deliver path | Low–Med | **3C** |
| **DeliveryFlowCubit coordinator** | Unify deliver + pickup + photos | Many | Unified state | Most page state | Too large for Phase 3 | High | **Later** |
| **ChecklistDialogState helper** | Dialog-only UI state | — | — | Minimal today (Cubit owns answers) | Dialog orchestration | Med | **Later** |

### 5.2 Map status

| Candidate | Responsibility | Risk | Phase |
|-----------|----------------|------|-------|
| **MapStatusUiState** (`ChangeNotifier`) | Profile name, marker icon, banner visible | Med | Later |
| **CourierOnlineDisplayController** | Mirror prefs + Cubit for UI | High (duplicate source of truth) | **Not recommended** without design |
| **OfferPollingController** | Timers + `_getCurrentOfferUseCase` | Very high | Dedicated phase |
| **MapStatusCubit** | Full screen state | Very high | Phase 4+ |

### 5.3 Incoming

| Candidate | Responsibility | Risk | Phase |
|-----------|----------------|------|-------|
| **IncomingCountdownController** | Timer + remaining seconds | High (expiry nav) | Phase 4 |
| **IncomingMapLabelController** | Label offsets + throttle | High (map coupling) | Map phase |
| **IncomingOfferFlowCubit cleanup** | Merge countdown into Cubit | High | Phase 4 |

### 5.4 Active trip

| Candidate | Responsibility | Risk | Phase |
|-----------|----------------|------|-------|
| **TripMapController** | Map + GPS + polyline + labels | Very high | Map phase |
| **RiderStatusController** | Status ints + use case calls | Very high | Phase 4 |
| **TripFlowCubit** | Order + status + navigation | Very high | Phase 4+ |
| **TripMarkerIconsLoader** | Icon loading only | Low | Phase 3C (optional) |

**Phase 3 recommendation:** Prefer **`ValueNotifier` / private holder classes in the same file** over new public Cubits until tests exist.

---

## 6. Safest First Phase 3 Candidates (Ranked)

| Rank | Candidate | Screen | What changes | Why safe | Risks | Manual QA | Est. PR size |
|------|-----------|--------|--------------|----------|-------|-----------|--------------|
| **1** | **Delivery Cubit unit tests** | Delivery | Add `test/features/delivery/...` only | Zero production behavior change; locks deliver/checklist flows | Mocks may not match DI reality | N/A (automated) | Small–medium |
| **2** | **Photo lists → `ValueNotifier`** | Delivery | Replace 2 photo `setState` with `ValueListenableBuilder` | Isolated lists; capture/remove stay in parent | `_canDeliver` must still read same data | Add/remove building & order photos; deliver button enable | Small (~80 lines) |
| **3** | **`_isPickupSubmitting` → `ValueNotifier`** | Delivery | Replace 2 pickup flag `setState` | Only affects pickup branch UI | Must not block deliver path | Pickup confirm loading state | Tiny |
| **4** | **Mapper tests** | Incoming / Active trip | Test `MobileOrderToOrderMockMapper` | No screen changes | Mapping drift | Automated | Small |
| **5** | **Marker icon load → `ValueNotifier`** | Active trip or Incoming | 1 setState for icons | Display only | Low impact | Map markers visible | Tiny |

**Do NOT start with:** active trip status machine, map controller extraction, GPS stream extraction, incoming accept/reject, delivery submit flow, map-status go-online/heartbeat chain.

---

## 7. High-Risk Areas Deferred

| Screen | Area | Why high-risk | Preconditions |
|--------|------|---------------|---------------|
| Active trip | Status machine + primary CTA | Integer progression + use case + navigation branches | Cubit/use-case tests; status matrix doc |
| Active trip | `DeliveryToCustomerPage` navigation | Transition guards + pickup/delivery params | Delivery flow tests |
| Delivery | Photo upload + deliver submit | Cubit sequence + proof path | DeliveryCompletionCubit tests |
| Delivery | Attempted delivery + checklist | Non-v1 API + dialog orchestration | AttemptedDeliveryChecklistCubit tests |
| Incoming | Countdown expiry | Timer + auto-reject/navigate | IncomingOrderCubit + timer tests |
| Incoming | Accept/reject row | API + timeout resume | Integration tests |
| Map status | Go online / heartbeat chain | Multi-Cubit + SharedPreferences | Availability flow tests |
| Map status | Fake offer timers | Timer + use case + navigation | Offer polling spec |
| All | GoogleMap blocks | Controller dispose + camera callbacks | Map refactor phase |
| All | OrderMock migration | Data layer + all screens | Separate migration phase |
| Incoming | `_IncomingOrderMap` | Label math + fit bounds | Map label controller plan |

---

## 8. Characterization Tests Recommended Before Phase 3 Implementation

Do not write tests in this planning task; prioritize before state moves.

### Delivery (High priority)

| Test | Protects | Priority |
|------|----------|----------|
| `delivery_completion_cubit_test.dart` | Deliver + attempt deliver emit sequence, submitting flags | **High** |
| `attempted_delivery_checklist_cubit_test.dart` | Load, answer, submit, `isComplete` | **High** |
| `delivery_to_customer_page_smoke_test.dart` | Page builds with mocked Cubits | Medium |

### Map status (Medium)

| Test | Protects | Priority |
|------|----------|----------|
| `mobile_order_offer_to_order_mock_mapper_test.dart` | Offer → route args | **High** |
| `go_online_cubit_test.dart` | Online flow (if not exists) | Medium |

### Incoming (High)

| Test | Protects | Priority |
|------|----------|----------|
| `incoming_order_cubit_test.dart` | Accept/reject/load flows | **High** |
| `incoming_order_mapper_test.dart` | Order mapping | Medium |

### Active trip (High — before any status work)

| Test | Protects | Priority |
|------|----------|----------|
| `mobile_order_to_order_mock_mapper_test.dart` | Order sync mapping | **High** |
| `update_rider_status_use_case` mock test via screen | Status progression | Medium |
| Manual regression script: full-time vs freelancer paths | Status ints | **High** (manual doc) |

### Cross-cutting

| Test | Protects | Priority |
|------|----------|----------|
| Golden/smoke for extracted Phase 2 widgets | UI regressions | Low |

---

## 9. Recommended Phase 3 First PR

### Decision: Tests/documentation PR first — no production state change yet

The safest first Phase 3 implementation is **not** a `setState` reduction PR. It is **characterization tests for delivery Cubits** because:

1. No production Dart behavior change.
2. Delivery is the next likely target for photo `ValueNotifier` work.
3. Repo currently lacks feature Cubit tests.

---

### First PR specification

| Field | Value |
|-------|-------|
| **Branch** | `test/phase-3-delivery-cubit-characterization` |
| **Goal** | Add unit tests for `DeliveryCompletionCubit` and `AttemptedDeliveryChecklistCubit` with mocked use cases |
| **Scope** | New files under `test/features/delivery/presentation/cubit/` only; optional `test/helpers/` mocks |
| **Out of scope** | Production `lib/` changes except `dev_dependencies` if a mock package is missing |

**Do-not-change list**

- All files under `lib/features/delivery/` (production)
- API, navigation, route paths
- Cubit implementation logic (tests only observe current behavior)
- Other screens

**Validation commands**

```bash
flutter pub get
dart format test/
flutter analyze test/
flutter test test/features/delivery/
```

**Manual QA**

- Run full test suite: `flutter test`
- Smoke: open delivery flow on device — unchanged (no prod diff)

**Rollback plan**

- Revert branch; no production impact.

---

### Second PR (first state-ownership change) — after tests merge

| Field | Value |
|-------|-------|
| **Branch** | `refactor/phase-3-delivery-photo-value-notifier` |
| **Goal** | Hold `_buildingPhotos` / `_orderPhotos` in `ValueNotifier`s; use `ValueListenableBuilder` in step 2/3 and slider; remove 2 `setState` calls |
| **Do-not-change** | Capture logic, remove logic, `_canDeliver`, Cubits, submit, navigation, dialogs |
| **Validation** | `flutter analyze lib/features/delivery/`; manual photo + deliver QA |
| **Rollback** | Revert to `setState` lists |

---

## 10. Recommended Phase 3 Roadmap

### Phase 3A — Safety net (week 1)

- Delivery Cubit unit tests (**first PR**)
- Optional: mapper tests for incoming/active trip
- Team review of this planning report

### Phase 3B — One small state ownership win (week 2)

- Delivery photo `ValueNotifier` only
- Document ownership in file header comment (1 paragraph)

### Phase 3C — Selected setState reduction (week 3+)

- Delivery pickup submitting flag OR incoming reject flag alignment with Cubit
- Optional: marker icon `ValueNotifier` on one screen
- Still **no** map controller / GPS moves

### Phase 3D — Reassess before Cubit extraction

- Measure remaining `setState` counts
- Decide per-screen: continue local controllers vs new Cubits
- Produce Phase 4 plan (Cubit boundaries, map phase, OrderMock migration)

**Conservative rule:** Max **one screen** in active Phase 3 implementation at a time. **Delivery first**, then incoming display-only flags, then map-status, then active trip last.

---

## 11. Open Questions / Decisions Needed

1. **Tests before state moves?** Recommended **yes** for delivery and incoming Cubits at minimum.
2. **First Phase 3 screen target?** Recommended **delivery page** (lowest setState, clearest photo boundary).
3. **State mechanism?** Early Phase 3: **`ValueNotifier` + private holder classes** in same file. Defer new public Cubits to Phase 4.
4. **Micro UI PRs before Phase 3?** Optional (`DeliveryClothesRelationshipCard`, etc.); not required if team moves to 3A tests.
5. **Map/GPS isolated phase?** Recommended **yes** — shared label/map logic across incoming + active trip should be one future **Map UI phase**, not piecemeal Phase 3.
6. **When to wire foundation files?** Separate adoption PR after Phase 3B; not mixed with state work.
7. **Characterization tests mandatory for Phase 3B?** Team should approve; architect recommendation: **mandatory for delivery**.
8. **OrderMock migration timing?** Defer until after Phase 3D reassessment; not coupled to setState reduction.
9. **`lib/screens/widgets/` for map-status?** Keep until map feature module move (align with Phase 2 open question).
10. **Remove `_buildServiceChips`?** Separate cleanup PR; not Phase 3.

---

## Related documents

- [phase_2_ui_extraction_summary.md](./phase_2_ui_extraction_summary.md)
- [file_ownership_map.md](./file_ownership_map.md)
- [flutter_safe_refactoring_execution_plan.md](./flutter_safe_refactoring_execution_plan.md)

---

*End of Phase 3 Planning Report. No Dart production files were modified.*
