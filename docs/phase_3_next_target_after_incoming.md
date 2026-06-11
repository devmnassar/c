# Phase 3 Next Target After Incoming

**Branch (documentation):** `docs/phase-3-next-target-after-incoming`  
**Document date:** June 2026  
**Scope:** Planning only — choose next Phase 3 screen after delivery and incoming milestones

**Related documents:**

- [phase_3_incoming_milestone.md](./phase_3_incoming_milestone.md)
- [phase_3_delivery_milestone.md](./phase_3_delivery_milestone.md)
- [phase_3_incoming_next_state_plan.md](./phase_3_incoming_next_state_plan.md)
- [phase_3_planning_report.md](./phase_3_planning_report.md)

---

## 1. Current Milestone Summary

### Delivery (complete — paused)

| Item | Status |
|------|--------|
| Cubit tests | **21/21 passing** (`DeliveryCompletionCubit`, `AttemptedDeliveryChecklistCubit`) |
| `delivery_to_customer_page.dart` `setState` | **0** (Phase 3B/3C ValueNotifiers) |
| Production behavior | Unchanged intentionally |
| Status | **Paused** — manual QA + milestone doc complete |

### Incoming (display state complete — paused)

| Item | Status |
|------|--------|
| Cubit tests | **23/23 passing** (`IncomingOrderCubit`) |
| `incoming_order_page.dart` `setState` | **7** (down from 11; drawer + reject submitting isolated) |
| Deferred | Countdown (2), map user-moved (2), map labels (2), nested marker icon (1) |
| Production behavior | Unchanged intentionally |
| Status | **Paused** — countdown/map require dedicated plan before further production work |

### Decision required

Choose the next Phase 3 **screen target**:

1. **Map Status** — `lib/screens/courier_map_status_screen.dart`
2. **Active Trip** — `lib/features/trip/presentation/pages/active_trip_page.dart`

**Conservative rule:** Do **not** start production `setState` reduction on either screen until characterization tests exist for extracted Cubits (same pattern as delivery 3A → 3B and incoming 3A → 3B).

---

## 2. Current Metrics

Verified from workspace (June 2026).

| Screen | File | Line count | setState count | Tests exist? | Main risks |
|--------|------|------------|----------------|--------------|------------|
| **Delivery** *(context)* | `lib/features/delivery/delivery_to_customer_page.dart` | ~1,491 | **0** | Yes — 21 Cubit tests | Complete; paused |
| **Incoming** *(context)* | `lib/features/incoming/presentation/pages/incoming_order_page.dart` | ~1,362 | **7** | Yes — 23 Cubit tests | Countdown/map deferred |
| **Map Status** | `lib/screens/courier_map_status_screen.dart` | ~1,137 | **21** | **No** feature tests | GPS/location init, go-online/offline + heartbeat, offer polling timers, post-online navigation |
| **Active Trip** | `lib/features/trip/presentation/pages/active_trip_page.dart` | ~1,991 | **15** | **No** feature tests | Rider/pickup status machine, GPS stream, route polyline, `DeliveryToCustomerPage` navigation |

**Existing test coverage under `test/features/`:** delivery (21), incoming (23) only. No map-status or active-trip tests.

---

## 3. Map Status Analysis

**File:** `lib/screens/courier_map_status_screen.dart`

### Current responsibilities

- Full-screen Google Map with courier position marker
- Courier online/offline toggle (drawer + persistence)
- Go To Online / searching UI
- Post go-online navigation routing (full-time → orders; freelancer → offer/order → incoming or active trip)
- Freelancer fake-offer banner loop + tap-to-fetch real offer
- Drawer (profile name, stats, notifications, settings, logout)
- Location permission flow and “move to my location”
- Direct offer/order lookup when opening freelancer offer flow

### Cubits used (injected via app / `BlocProvider`)

| Cubit | Role on screen |
|-------|----------------|
| `GoOnlineCubit` | Build request + go-online API; duplicate-request guard |
| `GoOfflineCubit` | Build request + go-offline API; duplicate-request guard |
| `HeartbeatCubit` | Periodic heartbeat while online; timer lifecycle; persists online flag via `SharedPrefHelper` |

Screen listens via `BlocListener` / `BlocBuilder` / `context.watch` — success triggers `_persistCourierOnline`, `_handlePostGoOnlineNavigation`, `HeartbeatCubit.startHeartbeat()` / `stopHeartbeat()`.

### Direct use cases (page-level, not in Cubits)

| Use case | Usage |
|----------|--------|
| `GetCurrentOfferUseCase` | Freelancer offer fetch (banner tap, post go-online step 1) |
| `GetCurrentOrderUseCase` | Post go-online routing, order-based navigation to incoming/active trip |

Also uses `CourierProfileLocalDataSource.getCachedCourierTypeId()` for freelancer vs full-time branching.

### Local state categories (`setState` — 21 total)

| Category | Fields / behavior | setState (approx.) |
|----------|-------------------|-------------------|
| Courier online | `_courierOnline` load + persist after Cubit success | 2 |
| Cached courier type | `_cachedCourierTypeId` — gates fake-offer polling | 1 |
| Profile name | `_profileName` from `ProfileService` | 1 |
| Location loading | `_locationLoading` in `_initializeLocation`, `_moveToMyLocation` | 8 |
| Current position | `_currentPosition` in location init / move | 2 |
| Fake offer banner | `_fakeOfferBannerVisible` show/hide | 2 |
| Marker icon | `_courierMarkerIcon`, `_courierMarkerIconLoading` | 2 |
| Offer lookup UI | `_offerLookupInFlight` during banner tap API | 2 |

**Guards without setState:** `_openingOfferFlow`, `_courierMarkerIconLoading` flag before load.

### Timers

| Timer | Purpose |
|-------|---------|
| `_fakeOfferBannerTimer` | Periodic show (30s interval) for freelancer polling UX |
| `_fakeOfferBannerHideTimer` | Initial delay (1s) and visible duration (10s) for banner overlay |

### SharedPreferences

- Key: `courier_online` (`_kCourierOnlineKey`) — load on init, write in `_persistCourierOnline`
- **Note:** `HeartbeatCubit` also references `courierOnlineKey` — duplicate touchpoint; do not refactor prefs without plan

### GPS / map risks

- `_initializeLocation` / `_moveToMyLocation` — permission denied paths, service disabled, 8+ `setState` on loading flags
- `GoogleMapController` animate camera on position updates
- Marker icon load depends on `MediaQuery.devicePixelRatio` in build path

### Navigation risks

| Destination | Trigger |
|-------------|---------|
| `/incoming-order` | No order, empty offer, or order routing |
| `/active-trip/:id` | Current order with in-progress rider status |
| `/orders` | Full-time courier after go-online |
| `/login` | Logout |
| `/home/profile`, `/notifications`, `/home/settings` | Drawer |

Navigation logic intertwined with `GetCurrentOfferUseCase` / `GetCurrentOrderUseCase` results and `courierTypeId`.

### Test gaps

- No tests for `GoOnlineCubit`, `GoOfflineCubit`, `HeartbeatCubit`
- No tests for page-level offer/order routing helpers
- No widget tests for map screen

### Safe first PR options

| Option | Type | Risk | Notes |
|--------|------|------|-------|
| **GoOnline + GoOffline Cubit characterization** | Test-only | **Low** | Mirrors delivery/incoming 3A; no production changes |
| **HeartbeatCubit characterization** | Test-only | **Med** | Timer + session id; use `bloc_test` fake async; can follow GoOnline/GoOffline PR |
| **`_profileName` → ValueNotifier** | Production | **Low** | 1 `setState`; drawer-only — **only after Cubit tests** |
| **Courier marker icon ValueNotifier** | Production | **Low** | 2 `setState`; display-only — **only after Cubit tests** |

### Do not touch yet (production)

- Go online / go offline / heartbeat wiring on the page
- Fake offer banner timers and `_startFakeOfferBannerLoop`
- `_courierOnline` persistence + `_setCourierOnline` Cubit dispatch
- `_initializeLocation` / `_moveToMyLocation` / `_currentPosition`
- `_handlePostGoOnlineNavigation` / offer-order routing
- `GoogleMapController` lifecycle

---

## 4. Active Trip Analysis

**File:** `lib/features/trip/presentation/pages/active_trip_page.dart`

### Current responsibilities

- Active order map with route polyline, stop markers, label overlays
- Continuous GPS position stream for courier marker
- Delivery rider status step machine (full-time + freelancer paths)
- Pickup rider status step machine + `PickupStatusCubit` for proof submission
- Primary CTA (“Arrived”, status advances, confirmation dialogs)
- Navigation to `DeliveryToCustomerPage` for delivery/pickup confirmation
- Complaint drawer, customer chat, call
- Order load/sync via `GetCurrentOrderUseCase` + route `initialOrder`

### Cubit used

| Cubit | Role |
|-------|------|
| `PickupStatusCubit` | Pickup proof upload + `UpdatePickupStatusUseCase`; submission status in Cubit state |

Page also calls `UpdateRiderStatusUseCase` **directly** for delivery status advances (not in a Cubit).

### Direct use cases

| Use case | Usage |
|----------|--------|
| `GetCurrentOrderUseCase` | `_loadOrder`, `_syncCurrentOrder` |
| `UpdateRiderStatusUseCase` | `_advanceDeliveryRiderStatus` |

### Local state categories (`setState` — 15 total)

| Category | Fields / behavior | setState (approx.) |
|----------|-------------------|-------------------|
| Order / loading | `_order`, `_loading`, `_isCurrentActiveOrder`, step flags from order | 3 |
| GPS / position | `_currentPosition` — last known, initial fix, **stream updates** | 4 |
| Route polyline | `_routePolyline`, `_initialMapReady` via `_fetchOrderRoute` | 1 |
| Rider / pickup status | `_deliveryRiderStatus`, `_pickupRiderStatus`, full-time step flags | 2 |
| Status update guard | `_isUpdatingRiderStatus` during API | 3 |
| Transition guards | `_openedDeliveryConfirmationPage`, pickup transition flags | 2 |
| Map labels | `_labelOffsets`, `_labelsReady` | 1 |
| Marker icons | `_laundryIcon`, `_homeIcon` in `_loadIcons` | 1 |

### GPS stream risks

- `Geolocator.getPositionStream` → `setState` on every position update (high rebuild frequency)
- Route fetch triggered when status ≥ picked up — coupled to status ints

### GoogleMapController risks

- Initial fit, camera updates, label offset projection via `getScreenCoordinate`
- Same label/throttle pattern as incoming (150 ms)

### DeliveryToCustomerPage navigation risks

- `_openDeliveryConfirmationPage` / `_openPickupConfirmationPage` — `Navigator.push` with order props, proof requirements, callbacks
- `_openedDeliveryConfirmationPage` / `_openedPickupConfirmationPage` guards prevent double-open
- Status thresholds (e.g. rider status 5 → delivery page; pickup arrived → pickup page)

### Status machine risks

- Multiple int constants for delivery and pickup flows (`_riderStatusEnRouteToLaundry` … `_pickupStatusDroppedOffAtLaundry`)
- `_effectiveDeliveryRiderStatus` / `_effectivePickupRiderStatus` derived logic
- Full-time vs freelancer vs orders-list entry source (`entrySource`, `_shouldUseOrdersListFlow`)
- Wrong local status → wrong CTA label or premature navigation to delivery page

### Test gaps

- No `PickupStatusCubit` tests (proof validation, upload failure, status submit)
- No tests for page status machine or navigation guards
- No mapper tests for active-trip-specific mapping (uses shared `fromMobileOrder`)

### Safe first PR options

| Option | Type | Risk | Notes |
|--------|------|------|-------|
| **`PickupStatusCubit` characterization** | Test-only | **Low–Med** | Smaller surface than page; includes file upload path |
| **Mapper tests** (`fromMobileOrder` shared) | Test-only | **Low** | Lower value; mapping shared with incoming |
| **Marker icon ValueNotifier** | Production | **Low** | 1 `setState` in `_loadIcons` — **only after Cubit tests** |

### Do not touch yet (production)

- Rider / pickup status machine and `_advanceDeliveryRiderStatus`
- GPS stream and `_initLocation`
- `GoogleMapController` and label offsets
- Route polyline / `DirectionsService`
- `DeliveryToCustomerPage` navigation and transition guards
- `PickupStatusCubit` implementation

---

## 5. Risk Comparison

| Screen | setState count | Risk level | Business criticality | Test coverage | Safest first PR | Recommendation |
|--------|----------------|------------|------------------------|---------------|-----------------|----------------|
| **Map Status** | 21 | **High** (page); **Low** (Cubit tests) | **Very high** — app hub, go-online, offer entry | **None** | Test-only: `GoOnlineCubit` + `GoOfflineCubit` (+ `HeartbeatCubit` follow-up) | **Choose as next target** |
| **Active Trip** | 15 | **Very high** | **Very high** — in-order execution, delivery handoff | **None** | Test-only: `PickupStatusCubit` | **Defer screen target** until map-status Cubit tests land |

**Conservative read:** Active trip has **fewer** `setState` calls but **higher** behavioral coupling (status machine + GPS stream + delivery page). Map status has **more** `setState` but **three already-extracted Cubits** that can be tested without touching the page — matching the proven delivery/incoming sequence.

---

## 6. Recommended Next Target

### Choice: **Map Status** — with **test-only first PR**

| Criterion | Map Status | Active Trip |
|-----------|------------|-------------|
| Safer test-only starting point | **Yes** — 3 isolated availability Cubits | Partial — only `PickupStatusCubit`; most logic stays in page |
| Lower blast radius for first PR | **Yes** — tests under `test/features/driver_availability/` | Med — pickup proof path is critical |
| Production criticality | Hub / go-online | In-trip execution |
| Small reversible first PR | **Cubit tests, no `lib/` changes** | Cubit tests possible but page risk remains high afterward |
| Maps/GPS/status break likelihood on refactor | High on page refactor; **avoid for now** | **Very high** on any page refactor |

**Do not** recommend production state refactor (ValueNotifier) as the first map-status PR — tests are missing.

**Do not** switch to active trip first — status machine and GPS stream make it the highest-risk mega-screen per original Phase 3 planning report.

**Incoming** remains paused (countdown/map deferred).

---

## 7. Recommended First PR for Chosen Target

### Map Status Phase 3A — Cubit characterization (test-only)

| Field | Value |
|-------|--------|
| **Branch** | `test/phase-3-map-status-go-online-offline-cubit-characterization` |
| **Goal** | Lock current behavior of `GoOnlineCubit` and `GoOfflineCubit` before any map-status page state work |
| **Type** | **Test-only** — no production `lib/` changes |

#### Exact scope

**Create:**

- `test/features/driver_availability/presentation/cubit/go_online_cubit_test.dart`
- `test/features/driver_availability/presentation/cubit/go_offline_cubit_test.dart`
- `test/features/driver_availability/helpers/driver_availability_cubit_test_helpers.dart` (optional, minimal)

**Optional follow-up PR (same target, separate branch):**

- `test/phase-3-map-status-heartbeat-cubit-characterization`
- `test/features/driver_availability/presentation/cubit/heartbeat_cubit_test.dart`

#### Files allowed to change

- `test/features/driver_availability/**` only
- `pubspec.yaml` / `pubspec.lock` **only if** dev deps already present (`bloc_test`, `mocktail` exist from delivery 3A)

#### Files forbidden to change

- `lib/screens/courier_map_status_screen.dart`
- All other `lib/**` production Dart files
- `incoming_order_page.dart`, `delivery_to_customer_page.dart`, `active_trip_page.dart`

#### Test scenarios (GoOnlineCubit)

- Initial state
- `goOnline` success (request build + API success)
- `goOnline` failure — request build fails
- `goOnline` failure — API fails
- Duplicate `goOnline` ignored while in progress
- `resetStatus` clears transient state

#### Test scenarios (GoOfflineCubit)

- Initial state
- `goOffline` success
- `goOffline` failure — request build / API
- Duplicate request guard
- `resetStatus`

#### Validation commands

```bash
flutter pub get
dart format test/features/driver_availability/
flutter analyze test/features/driver_availability/
flutter test test/features/driver_availability/
flutter test test/features/incoming/
flutter test test/features/delivery/
```

#### Manual QA

**Not required** — test-only PR. Smoke-test app informally optional.

#### Rollback

Delete test files — zero production impact.

---

## 8. Alternatives Rejected

### Active Trip as first target

| Reason | Detail |
|--------|--------|
| Status machine in page | 15 `setState` with 5+ business/status categories; not isolated like availability Cubits |
| GPS stream | Continuous `setState` on position — unsafe for early ValueNotifier work |
| Delivery page coupling | `_openDeliveryConfirmationPage` ties to live order execution |
| Original plan ordering | Phase 3 planning report ranked active trip **last** among mega-screens |
| Test-only alone insufficient | `PickupStatusCubit` tests help but leave the highest-risk page logic untested |

Active trip should receive **PickupStatusCubit tests** when map-status Phase 3A is complete — not as the primary screen target first.

### Map Status production refactor first (`_profileName` ValueNotifier)

| Reason | Detail |
|--------|--------|
| Tests missing | No safety net for go-online/offline regressions while touching same file |
| Precedent | Delivery and incoming both did **3A tests before 3B production** |

Display-only ValueNotifier for profile name (1 `setState`) is a valid **Phase 3B** after Cubit tests pass.

### Continue incoming countdown/map

| Reason | Detail |
|--------|--------|
| Explicitly deferred | [phase_3_incoming_next_state_plan.md](./phase_3_incoming_next_state_plan.md) rates countdown/map as **high risk** |
| Milestone pause | Incoming display-state milestone complete at 7 `setState` |

---

## 9. Exact Next Prompt Draft

Copy-paste for the recommended **test-only** PR:

---

You are a Senior Flutter Developer working on a production courier Flutter app.

We completed Phase 3 on delivery (0 setState) and incoming (7 setState, display state isolated). Planning selected **map-status** as the next target.

Implement **Map Status Phase 3A only** — test-only PR.

**Branch:** `test/phase-3-map-status-go-online-offline-cubit-characterization`

**VERY IMPORTANT:**

- Do NOT modify any production file under `lib/`.
- Do NOT refactor `courier_map_status_screen.dart`.
- Do NOT change Cubit implementations (`GoOnlineCubit`, `GoOfflineCubit`, `HeartbeatCubit`).
- Do NOT change APIs, use cases, repositories, navigation, route paths, timers, GPS, SharedPreferences, or map logic.
- Do NOT touch `delivery_to_customer_page.dart`, `incoming_order_page.dart`, or `active_trip_page.dart`.

**Goal:** Add characterization unit tests for current behavior of `GoOnlineCubit` and `GoOfflineCubit`.

**Inspect:**

- `lib/features/driver_availability/presentation/cubit/go_online_cubit.dart`
- `lib/features/driver_availability/presentation/cubit/go_offline_cubit.dart`
- Related state files and injected use cases

**Create:**

- `test/features/driver_availability/presentation/cubit/go_online_cubit_test.dart`
- `test/features/driver_availability/presentation/cubit/go_offline_cubit_test.dart`
- Optional: `test/features/driver_availability/helpers/driver_availability_cubit_test_helpers.dart`

**Use:** `bloc_test`, `mocktail` (already in dev_dependencies).

**Strategy:** Direct Cubit construction with mocked use cases. Characterize current behavior only — do not change production code to make tests pass.

**Cover:** initial state, success paths, failure paths (request build + API), duplicate-request guards, `resetStatus`.

**Validation:**

```bash
flutter pub get
dart format test/features/driver_availability/
flutter analyze test/features/driver_availability/
flutter test test/features/driver_availability/
flutter test test/features/incoming/
flutter test test/features/delivery/
```

**Final response:** files created, test count, scenarios covered, confirmation no `lib/` changes, recommended next step (HeartbeatCubit tests or map-status Phase 3B `_profileName` ValueNotifier after tests pass).

---

## Appendix — Suggested Phase 3 Sequence (Map Status)

| Phase | Branch (suggested) | Type | setState impact |
|-------|-------------------|------|-----------------|
| **3A** | `test/phase-3-map-status-go-online-offline-cubit-characterization` | Tests | None |
| **3A₂** | `test/phase-3-map-status-heartbeat-cubit-characterization` | Tests | None |
| **3B** | `refactor/phase-3-map-status-profile-name-value-notifier` | Production | 21 → 20 (after approval) |
| **3C+** | TBD planning | — | Location/banner/online — **not yet** |

---

*End of Phase 3 Next Target After Incoming plan. No Dart production files were modified to produce this document.*
