# Gaseel Courier — Safe Refactoring Execution Plan

**Companion to:** [flutter_codebase_audit_report.md](./flutter_codebase_audit_report.md)  
**Date:** June 7, 2026  
**Status:** Planning only — no production Dart changes in this document  
**Principle:** Incremental, reversible, manually testable steps that preserve all user-visible behavior

---

## 1. Production Safety Rules

These rules are **mandatory** for every refactor commit on this project.

### 1.1 Scope and sequencing

1. **Never refactor multiple major flows in one step.** One primary concern per PR (e.g. “extract map status drawer widget” only).
2. **Never change UI and business logic in the same commit** unless unavoidable — prefer UI-only extractions first; logic moves come later in dedicated commits.
3. **Never rename or move files** until imports, router references, and navigation call sites are documented and a rollback commit exists.
4. **Never replace `OrderMock` with `MobileOrder`** in Phases 1–5. Mappers and navigation extras must keep working unchanged.
5. **Never remove legacy screens/files** until grep confirms zero route references, zero imports, and QA passes (Phase 6 only).
6. **Never change API endpoints, request payloads, response parsing, or token refresh logic** unless explicitly approved as a separate bugfix.
7. **Never modify `go_router` redirect logic** in Phases 1–4. Route path strings in call sites stay identical until Phase 5.
8. **Every phase must produce a buildable app** (`flutter analyze` with no new errors; app runs on device/emulator).
9. **Every commit must be small and reversible** — one extraction or one additive file; easy to `git revert`.
10. **Never migrate localization systems** (ARB vs GetX vs `CoreLocalizer`) in early phases.
11. **Never introduce new dependencies** without team approval.
12. **Never “clean up while here”** — no drive-by formatting of unrelated files, no opportunistic renames.
13. **Preserve imperative navigation** where it exists today (e.g. `DeliveryToCustomerPage` via `Navigator.push`) until a dedicated routing phase.
14. **Do not change Cubit state shapes or emit sequences** in UI-only phases.
15. **Document before delete** — legacy cleanup requires a pre-deletion reference audit stored in docs.

### 1.2 Commit hygiene

- Prefer **additive commits** (new file + minimal wiring) over large in-place edits.
- Run **analyze + manual smoke test** before every push.
- Tag or note the last known-good commit before each phase starts.
- If a step fails QA, **revert immediately**; do not stack fixes on a broken extraction.

---

## 2. Critical User Journeys That Must Not Break

Run this checklist **after every refactor commit** that touches operational flows (minimum: after each Phase 2 sub-step).

| # | Journey | Why critical |
|---|---------|--------------|
| 1 | App start / splash | First launch, splash flag, redirect to login or map-status |
| 2 | Login | Token storage, navigate to permissions |
| 3 | Logout | Clears tokens, stops heartbeat, returns to login |
| 4 | Token refresh / session persistence | 401 → refresh → retry; app resume after background |
| 5 | Permissions and location setup | Onboarding gate before map-status |
| 6 | Go online | GoOnline API, session id, heartbeat start |
| 7 | Heartbeat while online | Periodic ping; server forced offline handling |
| 8 | Receive current offer | GetCurrentOffer polling / banner on map-status |
| 9 | Incoming order screen opens | Route `/incoming-order` with/without `extra` |
| 10 | Accept offer | Accept API → navigate to active trip |
| 11 | Reject offer | Reject API → return to map-status |
| 12 | Offer timeout behavior | Countdown reaches zero; UI and navigation |
| 13 | Current order fallback | Map-status opens active trip when order exists, no offer |
| 14 | Active trip screen | `/active-trip/:id` with `OrderMock` extra |
| 15 | Pickup status updates | Pickup flow buttons, `UpdatePickupStatusUseCase` |
| 16 | Delivery status updates | Rider status transitions on active trip |
| 17 | Navigate to delivery screen | `Navigator.push` → `DeliveryToCustomerPage` |
| 18 | Delivery with proof photos | Camera/gallery, upload, complete delivery |
| 19 | Attempted delivery checklist | Checklist load/submit via Cubits |
| 20 | Orders list | Filter, refresh, tap order → active trip |
| 21 | Order details | Sheets/cards on trip and orders |
| 22 | Profile | Drawer / home profile navigation |
| 23 | Settings | Language/theme; logout entry |
| 24 | Arabic / English switching | Layout, drawer strings, map labels |
| 25 | Push notifications | FCM init, foreground/background if configured |
| 26 | Google Maps + current location | Markers, polylines, fit bounds, permission denied fallback |

**Minimum smoke subset** (when time is limited): 1, 2, 3, 6, 7, 9, 10, 14, 17, 18, 20, 24.

---

## 3. Refactoring Strategy

### 3.1 Core principle

The first **implementation** work must **not move files across folders**. It must only:

- Add new files alongside existing code, or
- Extract private widgets/classes **from inside the same screen file** into new widget files **in the same directory** (or `presentation/widgets/` under the same feature).

Behavior, API calls, navigation targets, and state ownership stay identical.

### 3.2 Phased strategy

| Phase | Name | Goal | Risk |
|-------|------|------|------|
| **A** | Characterization & safety checks | Document routes, keys, timers, imports; baseline QA | None (docs + grep) |
| **B** | Extract constants/helpers (zero behavior change) | Add `route_paths.dart`, `business_constants.dart`, `app_colors.dart`, l10n extension — **without switching call sites yet** | Very low |
| **C** | Extract UI-only widgets from mega screens | Smaller files; parent keeps all state/API | Low–medium |
| **D** | Extract controllers/Cubits (only after UI stable) | Move logic out of widgets; **same public behavior** | Medium |
| **E** | Move files to target architecture | `lib/screens/` → `features/map_status/`, etc. | Medium–high |
| **F** | Remove legacy | Delete duplicates, mocks, unused l10n — last | High if rushed |

### 3.3 Dependency rule between phases

```
A (document) → B (additive constants) → C (UI widgets) → D (Cubits)
                                                      ↓
                                              E (file moves + routes)
                                                      ↓
                                              F (legacy cleanup)
```

**Do not skip A.** Do not start D before C is stable on at least one screen.

---

## 4. Branching and Commit Plan

### 4.1 Branch naming

```
refactor/safe-phase-1-foundations
refactor/safe-phase-2-ui-map-status-drawer
refactor/safe-phase-2-ui-delivery-widgets
refactor/safe-phase-3-setstate-map-status
refactor/safe-phase-4-cubit-map-status
refactor/safe-phase-5-move-map-status-screen
refactor/safe-phase-6-legacy-cleanup   # only when explicitly scheduled
```

One branch per **sub-deliverable** (not one branch for entire Phase 2).

### 4.2 Example commit sequence (Phase 1 + early Phase 2)

| Commit | Branch | Message (example) | Reversible? |
|--------|--------|-------------------|-------------|
| 1 | `refactor/safe-phase-1-foundations` | `docs: add safe refactoring execution plan and file ownership map` | Yes |
| 2 | same | `chore: add route_paths.dart (unused)` | Yes |
| 3 | same | `chore: add business_constants.dart (unused)` | Yes |
| 4 | same | `chore: add app_colors.dart (unused)` | Yes |
| 5 | same | `chore: add l10n_context_extension.dart (unused)` | Yes |
| 6 | `refactor/safe-phase-2-ui-delivery-widgets` | `refactor(delivery): extract DeliveryStepHeader widget (no behavior change)` | Yes |
| 7 | same | `refactor(delivery): extract DeliveryPhotoSlider widget (no behavior change)` | Yes |
| 8 | `refactor/safe-phase-2-ui-map-status-drawer` | `refactor(map-status): extract MapStatusDrawer widget (no behavior change)` | Yes |
| 9 | same | `refactor(map-status): extract MapStatusOfferBanner widget (no behavior change)` | Yes |
| 10 | `refactor/safe-phase-2-ui-incoming` | `refactor(incoming): move StopCard to presentation/widgets (no behavior change)` | Yes |

### 4.3 PR rules

- Max **~300 lines changed** per PR where possible (excluding generated/l10n).
- PR description must list **manual QA scenarios executed**.
- Require **at least one reviewer** for Phase 4+ (Cubit/logic moves).
- Merge to main only when analyze is clean and smoke tests pass.

---

## 5. Pre-Refactor Safety Checklist

Complete this **before the first Dart refactor commit**. Store results in `docs/file_ownership_map.md` (Phase 1 deliverable).

### 5.1 All routes in `app_router.dart`

| Path | Name | Builder / Screen |
|------|------|------------------|
| `/splash` | splash | `SplashPage` |
| `/login` | login | `LoginPage` |
| Forget password paths | forgetPassword* | Forget password flow pages |
| `/signup` | signup | `SignUpPhonePage` (+ nested otp, documents, awaiting-review) |
| Document routes | doc* | Iqama, Selfie, License, Vehicle, Driver card |
| `SignUpPage.id`, `WelcomePage.id` | signupDetails, signupWelcome | Auth signup |
| `/permissions` | permissions | `PermissionsPage` + `CourierProfileCubit` |
| `/location-setup` | locationSetup | `LocationSetupPage` |
| `/home` | home | `HomeShellPage` (+ orders, stats, profile, settings) |
| `/orders` | orders | `OrdersPage` (duplicate entry to home orders) |
| `/notifications` | notifications | `NotificationsPage` |
| `/map` | map | `MapPage` |
| **`/map-status`** | mapStatus | **`CourierMapStatusScreen`** + GoOnline/GoOffline Cubits |
| **`/active-trip/:id`** | activeTrip | **`ActiveTripPage`** (+ `/map` sub-route) |
| **`/incoming-order`** | incomingOrder | **`IncomingOrderPage`** + `IncomingOrderCubit` (+ `/map` sub-route) |

**Redirect logic (do not touch early):** Uses `OnboardingState.instance` + `SharedPrefKeys.splashCompleted`; logged-out users → `/login`; logged-in without permissions → `/permissions`; without location → `/location-setup`; complete onboarding → **`/map-status`**.

### 5.2 Navigation to mega screens

#### `active_trip_page.dart` / `/active-trip/:id`

| Caller file | Navigation |
|-------------|------------|
| `core/router/app_router.dart` | Route builder |
| `screens/courier_map_status_screen.dart` | `context.go('/active-trip/${id}', extra: ...)` |
| `features/incoming/presentation/pages/incoming_order_page.dart` | `context.go('/active-trip/$resolvedOrderId', ...)` |
| `features/orders/presentation/pages/orders_page.dart` | `context.go('/active-trip/${order.id}', ...)` |
| `features/trip/presentation/pages/active_trip_page.dart` | `context.push('/active-trip/${order.id}/map', ...)` |

#### `delivery_to_customer_page.dart` (not in router)

| Caller file | Navigation |
|-------------|------------|
| `features/trip/presentation/pages/active_trip_page.dart` | `Navigator.push` / `PageRouteBuilder` → `DeliveryToCustomerPage(...)` |

#### `incoming_order_page.dart` / `/incoming-order`

| Caller file | Navigation |
|-------------|------------|
| `core/router/app_router.dart` | Route builder + `IncomingOrderRouteArgs` |
| `screens/courier_map_status_screen.dart` | Multiple `context.push('/incoming-order', extra: ...)` |
| `features/incoming/presentation/pages/incoming_order_full_map_page.dart` | Imports page; `id = '/incoming-order/map'` |

#### `courier_map_status_screen.dart` / `/map-status`

| Caller file | Navigation |
|-------------|------------|
| `core/router/app_router.dart` | Route builder (redirect target) |
| `features/onboarding/presentation/pages/permissions_page.dart` | `context.go('/map-status')` |
| `features/onboarding/presentation/pages/location_setup_page.dart` | `context.go('/map-status')` |
| `features/orders/presentation/pages/orders_page.dart` | `context.go('/map-status', extra: {'autoSearch': ...})` |
| `features/incoming/presentation/pages/incoming_order_page.dart` | Multiple `context.go('/map-status', ...)` |
| `features/delivery/delivery_to_customer_page.dart` | `context.go('/map-status')` on completion |
| `features/trip/presentation/pages/active_trip_page.dart` | `context.go('/map-status')` / entrySource routing |
| `features/trip/presentation/pages/active_trip_full_map_page.dart` | `context.go('/map-status')` |

### 5.3 `OrderMock` usage (do not remove in early phases)

**Definition:** `features/orders/domain/models/order_mock.dart`

**Consumers (26 files):** Including `app_router.dart`, `active_trip_page.dart`, `incoming_order_page.dart`, `incoming_order_cubit.dart`, mappers (`mobile_order_to_order_mock_mapper.dart`, `mobile_order_offer_to_order_mock_mapper.dart`), `orders_page.dart`, `orders_cubit.dart`, `mock_order_card.dart`, `order_session_store.dart`, `mock_orders_data.dart`, trip/incoming widgets, etc.

**Navigation:** Router accepts `OrderMock` or `Map` with `'order'` key for active trip and incoming routes.

### 5.4 `MobileOrder` / `MobileOrderOffer` usage

**Domain models:** `features/orders/domain/models/mobile_order.dart`, `mobile_order_offer.dart`

**Primary consumers:**

- Data: `mobile_order_model.dart`, `orders_remote_data_source.dart`, `mobile_orders_repository_impl.dart`
- Mappers: `mobile_order_to_order_mock_mapper.dart`, `mobile_order_offer_to_order_mock_mapper.dart`, `incoming_order_mapper.dart`
- Cubits: `incoming_order_cubit.dart`, `orders_cubit.dart`
- UI/state: `incoming_order_page.dart`, `incoming_order_state.dart`, `courier_map_status_screen.dart` (logging/describe helpers)
- Use cases: all order/offer use cases in `features/orders/domain/usecases/`

### 5.5 Direct use case calls inside UI ( refactor targets for Phase 4)

| Screen | Use cases called directly from widget/state class |
|--------|---------------------------------------------------|
| **`courier_map_status_screen.dart`** | `GetCurrentOrderUseCase`, `GetCurrentOfferUseCase` |
| **`active_trip_page.dart`** | `GetCurrentOrderUseCase`, `UpdateRiderStatusUseCase` |

**Already in Cubits (do not duplicate):**

- `incoming_order_page.dart` → `IncomingOrderCubit` (accept/reject/load)
- `delivery_to_customer_page.dart` → `DeliveryCompletionCubit`, `AttemptedDeliveryChecklistCubit`
- Map-status online → `GoOnlineCubit`, `GoOfflineCubit`, `HeartbeatCubit`

### 5.6 SharedPreferences / storage keys (session & courier state)

#### `SharedPrefKeys` (`core/helpers/constants.dart`)

`userToken`, `refreshToken`, `authUserId`, `authUserName`, `authPhoneNumber`, `authIsActive`, `authIsRejected`, `authIsPhoneVerified`, `authExpiresInMinutes`, `cachedDetectedPhoneIsoCode`, `firebaseFcmToken`, `lastPushNotificationEvent`, `pendingBackgroundNotificationEvent`, `courierTypeId`, `splashCompleted`, `locationPermissionPromptHandled`

#### OnboardingState keys (`core/onboarding/onboarding_state.dart`)

`isLoggedIn`, `permissionsGranted`, `locationServiceEnabled`, `profileCompleted`, `documentsSubmitted`, `reviewApproved`, `welcomeEntered`

#### Courier online (duplicated — document only; do not consolidate in Phase 1)

| Key | Locations |
|-----|-----------|
| `'courier_online'` | `courier_map_status_screen.dart`, `orders_page.dart`, `incoming_order_page.dart`, `HeartbeatCubit.courierOnlineKey` |

#### Auth logout clears (`core/auth/auth_service.dart`)

SharedPref + SecureStorage token keys; `HeartbeatCubit.courierOnlineKey`; various courier work type override keys.

#### Other

- `'locale'` — `locale_helper.dart`
- Theme key — `ThemeController`
- Profile/document drafts — `profile_service.dart`, `document_draft_service.dart`

### 5.7 API endpoints — orders / offers / trip / delivery

From `core/networking/api_constants.dart` ( **do not change URLs in refactor** ):

| Operation | Endpoint |
|-----------|----------|
| List orders | `GET .../api/v1/mobile/orders` |
| Current order | `GET .../api/v1/mobile/orders/current` |
| Current offer | `GET .../api/v1/mobile/orders/offers/current` |
| Accept offer | `POST .../offers/{id}/accept` |
| Reject offer | `POST .../offers/{id}/reject` |
| Update delivery/rider status | `PUT .../orders/{id}/delivery-status` |
| Update pickup status | `PUT .../orders/{id}/pickup-status` |
| Upload proof photo | `POST .../orders/{id}/proof-photo` |
| Get checklist | `GET .../api/mobile/orders/{id}/checklist` ⚠ non-v1 path |
| Submit checklist | `POST .../api/mobile/orders/{id}/checklist` ⚠ non-v1 path |
| Go online / offline / heartbeat | `.../api/driver-availability/*` |
| Courier profile | `GET .../api/courier/me` |

### 5.8 Cubits — incoming / trip / delivery / availability

| Cubit | Registered | Used by |
|-------|------------|---------|
| `HeartbeatCubit` | get_it + app root | map-status, orders, logout |
| `GoOnlineCubit` | get_it; provided on `/map-status` | map-status |
| `GoOfflineCubit` | get_it; map-status + orders | map-status, orders |
| `IncomingOrderCubit` | get_it; provided on `/incoming-order` | incoming_order_page |
| `PickupStatusCubit` | get_it; created in active_trip | active_trip_page |
| `DeliveryCompletionCubit` | get_it; created in delivery page | delivery_to_customer_page |
| `AttemptedDeliveryChecklistCubit` | get_it; created in delivery page | delivery_to_customer_page |
| `OrdersCubit` | get_it; orders page | orders_page |

### 5.9 Timers / streams / subscriptions in mega screens

| File | Resource | Purpose |
|------|----------|---------|
| `courier_map_status_screen.dart` | `Timer? _fakeOfferBannerTimer` | Periodic fake offer banner |
| | `Timer? _fakeOfferBannerHideTimer` | Hide banner |
| | `GoogleMapController? _mapController` | Map |
| | Geolocator calls | Location init / refresh |
| `incoming_order_page.dart` | `Timer? _countdownTimer` | Offer countdown |
| | `Timer? _cameraMoveDebounce` | Map camera debounce |
| | `GoogleMapController? _mapController` | Map |
| `active_trip_page.dart` | `StreamSubscription<Position>? _positionSubscription` | GPS position stream |
| | `GoogleMapController? _mapController` | Map |
| | `DirectionsService` | Route polyline |
| `delivery_to_customer_page.dart` | `ImagePicker` | Photos (no timers) |
| | Cubits lifecycle | Created in `initState`, closed in `dispose` |

**Rule for Phase 2–3:** Do not move timer start/stop logic out of the parent State class until Phase 4.

### 5.10 Map controllers and location

- All three map screens use **`google_maps_flutter`** with local `GoogleMapController`.
- `active_trip_page.dart` uses **`Geolocator.getPositionStream`** — highest risk for regressions.
- Shared map utilities: `features/incoming/utils/incoming_map_utils.dart`, `core/maps/directions_service.dart`, `labeled_marker_widget.dart`.

---

## 6. Build and Test Commands

Run from project root: `d:\GasselExpress\GitHub\Mobile App\Courier-App--flutter`

### 6.1 After every small change

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib/
flutter analyze
```

Fix any **new** analyze issues before committing. Pre-existing warnings may be tracked separately; do not introduce new errors.

### 6.2 Tests

```bash
flutter test
```

**Current state:** Only default `test/widget_test.dart` exists (`App` smoke widget test). It may fail without Firebase/mock setup — **do not rely on CI tests** for operational flows until characterization tests are added.

**Recommendation (Phase A, optional):** Add mapper unit tests before Phase 4 — not required for Phase 1–2.

### 6.3 Run on device / emulator

```bash
flutter run
# or explicit:
flutter run -d <device_id>
```

Manual regression is **required** after any Phase 2+ change.

### 6.4 Android release sanity (before merging phase branches)

```bash
flutter build apk --debug
# or when signing is configured:
flutter build appbundle --release
```

Run only at phase boundaries, not every commit.

### 6.5 When to use `flutter clean`

Use **only when**:

- Dependency or plugin native code changed
- Build cache corruption suspected
- After switching Flutter SDK channel

```bash
flutter clean
flutter pub get
```

Not needed for widget extraction commits.

---

## 7. Manual QA Checklist

### 7.1 Splash & auth

**Steps:** Cold start → splash → login with valid credentials  
**Expected:** Lands on permissions (first time) or map-status (returning user per onboarding flags)  
**Can break:** Router redirect, splash flag, token save  
**Files:** `splash_page.dart`, `app_router.dart`, `login_cubit.dart`, `onboarding_state.dart`

**Steps:** Logout from settings or drawer  
**Expected:** Login screen; tokens cleared; heartbeat stopped  
**Can break:** `AuthService.logout`, `HeartbeatCubit.stopHeartbeat`  
**Files:** `auth_service.dart`, `settings_page.dart`, `courier_map_status_screen.dart`

**Steps:** Background app 15+ min, resume, trigger API  
**Expected:** Session persists or clean re-login on 401  
**Can break:** `AuthTokenInterceptor`  
**Files:** `auth_token_interceptor.dart`

---

### 7.2 Permissions & location

**Steps:** Fresh install → login → grant/deny permissions → location setup  
**Expected:** Cannot reach map-status until gates satisfied  
**Can break:** `permissions_page.dart`, `location_setup_page.dart`, redirect logic  
**Files:** onboarding pages, `app_router.dart`

---

### 7.3 Go online / offline & heartbeat

**Steps:** On map-status, toggle online ON  
**Expected:** Go online API success, heartbeat starts, online persisted  
**Can break:** Cubit listeners in map-status, `'courier_online'` key  
**Files:** `courier_map_status_screen.dart`, `go_online_cubit.dart`, `heartbeat_cubit.dart`

**Steps:** Toggle OFF  
**Expected:** Go offline API, heartbeat stops  
**Can break:** Same + orders page if shared key out of sync  
**Files:** `go_offline_cubit.dart`, `orders_page.dart`

**Steps:** Go online, kill app, reopen  
**Expected:** Online state restored; heartbeat resumes appropriately  
**Can break:** SharedPreferences read on init  

---

### 7.4 Offer receiving & incoming order

**Steps:** While online, wait for offer / trigger test offer flow  
**Expected:** Banner or navigation to incoming order  
**Can break:** `_fakeOfferBannerTimer`, `_getCurrentOfferUseCase` in map-status  
**Files:** `courier_map_status_screen.dart`

**Steps:** Open `/incoming-order` with active offer  
**Expected:** Map, countdown, accept/reject buttons  
**Can break:** Widget extraction breaking BlocProvider scope  
**Files:** `incoming_order_page.dart`, `incoming_order_cubit.dart`

**Steps:** Accept offer  
**Expected:** Navigate to `/active-trip/:id` with order data  
**Can break:** `OrderMock` mapping, cubit accept methods  
**Files:** mappers, `incoming_order_cubit.dart`, `app_router.dart`

**Steps:** Reject offer  
**Expected:** Return map-status; no stale trip  
**Can break:** Reject use case wiring  

**Steps:** Let countdown expire  
**Expected:** Timeout UI matches current production behavior  
**Can break:** `_countdownTimer` if moved incorrectly  

---

### 7.5 Active trip & delivery

**Steps:** Open active trip from map-status, orders, or after accept  
**Expected:** Map, order details, status actions correct for order type  
**Can break:** Any extraction of map or action bar  
**Files:** `active_trip_page.dart`, `active_order_details_sheet.dart`

**Steps:** Progress pickup/delivery status buttons  
**Expected:** API calls succeed; UI updates  
**Can break:** `_updateRiderStatusUseCase` direct calls, status ints  
**Files:** `active_trip_page.dart`

**Steps:** Open delivery screen from trip  
**Expected:** `DeliveryToCustomerPage` opens with correct customer data  
**Can break:** Navigator push arguments  
**Files:** `active_trip_page.dart`, `delivery_to_customer_page.dart`

**Steps:** Add building photos, complete delivery  
**Expected:** Upload + status update + return to map-status  
**Can break:** `DeliveryCompletionCubit`, photo picker UI extraction  
**Files:** `delivery_completion_cubit.dart`, delivery widgets

**Steps:** Attempted delivery → complete checklist  
**Expected:** Checklist load/submit  
**Can break:** `AttemptedDeliveryChecklistCubit`  
**Files:** delivery page step 2/3 widgets

---

### 7.6 Orders, profile, settings

**Steps:** Open orders list, filter, tap in-progress order  
**Expected:** Navigate to active trip  
**Files:** `orders_page.dart`, `orders_cubit.dart`

**Steps:** Profile from drawer  
**Expected:** Profile page opens  
**Files:** `courier_map_status_screen.dart`, `profile_page.dart`

**Steps:** Switch EN ↔ AR in settings  
**Expected:** Drawer, orders, trip strings update; RTL layout on map labels  
**Can break:** Hardcoded strings, `_resolveL10n` duplication  
**Files:** settings, map screens, `app.dart`

---

### 7.7 Edge cases

| Scenario | Expected | Risk |
|----------|----------|------|
| App restart while online | Online + map-status | Heartbeat + prefs |
| App restart during active trip | Trip recoverable or clear error | `GetCurrentOrderUseCase` |
| Push notification tap (if wired) | Opens correct screen | `push_notification_service.dart` |
| Location denied | Fallback map center (Riyadh) | Geolocator handling in map-status |

---

## 8. Phase 1 Detailed Plan — Zero Behavior Change

**Branch:** `refactor/safe-phase-1-foundations`  
**Goal:** Additive scaffolding and documentation only.

### 8.1 Deliverables (new files only)

| File | Purpose | Usage in Phase 1 |
|------|---------|------------------|
| `docs/file_ownership_map.md` | Screen ownership, navigators, cubits, keys | Documentation |
| `lib/core/router/route_paths.dart` | `class RoutePaths { static const mapStatus = '/map-status'; ... }` | **Not imported by production code yet** |
| `lib/core/constants/business_constants.dart` | Rider status ints, `_fullTimeCourierTypeId = 3`, courier online key name | **Not imported yet** |
| `lib/core/theme/app_colors.dart` | `primary = Color(0xFF23C1B2)`, etc. | **Not imported yet** |
| `lib/core/locale/l10n_context_extension.dart` | `extension L10nX on BuildContext { AppLocalizations get l10nOrEn }` | **Not imported yet** |

### 8.2 Optional safe documentation comments

- Add **file-level doc comments** on mega screens describing ownership and critical timers (comment-only change).
- Do **not** add `@Deprecated` annotations to Dart symbols yet — documentation table only in `file_ownership_map.md`.

### 8.3 Explicitly out of scope for Phase 1

- Modifying `app_router.dart` redirect logic
- Replacing hardcoded paths/colors with new constants files
- Touching `OrderMock`, mappers, or API layer
- Deleting commented login files
- Moving `courier_map_status_screen.dart`

### 8.4 Phase 1 exit criteria

- [ ] All Phase 1 files added; app builds unchanged
- [ ] `file_ownership_map.md` complete (section 5 of this doc expanded)
- [ ] Team sign-off on Phase 2 order

---

## 9. Phase 2 Detailed Plan — Extract UI-Only Widgets

**Branch pattern:** `refactor/safe-phase-2-ui-<screen>-<widget>`  
**Rule:** Parent `State` keeps timers, controllers, Cubits, use cases, and navigation.

### 9.1 Verified extraction order (safest first)

Audit suggested order was map-status → incoming → delivery → active trip. **Based on code inspection, recommended order:**

| Order | Screen | Rationale |
|-------|--------|-----------|
| **1** | `delivery_to_customer_page.dart` | Already has isolated private widgets (`_Card`, `_StepHeader`, `_PhotoSlider`, checklist cards). **No router entry.** Cubits handle API. Lowest coupling. |
| **2** | `courier_map_status_screen.dart` | `_buildDrawer` is a clear ~300-line UI block; offer banner UI separable. **Hub screen** — test thoroughly after each extract. |
| **3** | `incoming_order_page.dart` | Partial extraction exists (`_StopCard`, `_IncomingOrderMap`). Countdown + Cubit bloc in parent — extract cautiously. |
| **4** | `active_trip_page.dart` | GPS stream, use cases, status machine in one State — **highest risk**; extract passive widgets only (`_CompactActionBtn`, `_MapControlBtn`) first. |

### 9.2 Target: `delivery_to_customer_page.dart` (~1,715 lines)

**Existing private widgets to move** (UI-only, safe first moves):

| Widget | Suggested new file | Inputs | Callbacks | Stays in parent |
|--------|-------------------|--------|-----------|-----------------|
| `_StepHeader` | `features/delivery/presentation/widgets/delivery_step_header.dart` | title, step index | none | Step flow state |
| `_Card` | `delivery_section_card.dart` | child, padding | none | — |
| `_InfoRow` | `delivery_info_row.dart` | label, value | none | — |
| `_ChecklistQuestionCard` | `delivery_checklist_question_card.dart` | question, selected answer | `onSelect` | Cubit submit |
| `_ChecklistAnswerChoice` | same file or `delivery_checklist_answer_choice.dart` | label, selected | `onTap` | — |
| `_buildPhotoSlider` → widget | `delivery_photo_slider.dart` | `List<XFile>`, `isBuilding` | onAdd, onRemove | ImagePicker calls |
| `_buildBottomBar` → widget | `delivery_bottom_bar.dart` | enabled flags, labels | onDeliver, onAttempt | Cubit loading state |

**Do not move yet:** `_capturePhoto`, `_submitDelivery`, `_log`, Cubit creation/dispose, `Navigator`/`context.go` calls.

### 9.3 Target: `courier_map_status_screen.dart` (~1,270 lines)

| Section | Suggested new file | Pass as props |
|---------|-------------------|---------------|
| `_buildDrawer` | `features/map/presentation/widgets/map_status_drawer.dart` (or colocate under future `map_status/widgets/`) | `profileName`, `courierOnline`, `availabilityBusy`, `l10n` | `onProfileTap`, `onSettingsTap`, `onOrdersTap`, `onNotificationsTap`, `onOnlineChanged`, `onLogout` |
| Fake offer banner UI | `map_status_offer_banner.dart` | `visible`, `message` | `onTap`, `onDismiss` |
| Map shell (optional later) | `map_status_google_map.dart` | `markers`, `initialTarget`, `isRtl` | `onMapCreated` |

**Stays in parent:** `_fakeOfferBannerTimer*`, `_getCurrentOfferUseCase`, `_getCurrentOrderUseCase`, `_handlePostGoOnlineNavigation`, all `BlocListener`s.

### 9.4 Target: `incoming_order_page.dart` (~1,545 lines)

| Widget | Suggested new file | Notes |
|--------|-------------------|-------|
| `_StopCard` / `_StopConnector` | `incoming_stop_card.dart` | Already semi-isolated |
| `_IncomingInfoField` | `incoming_info_field.dart` | Stateless |
| `_IncomingOrderMap` | Keep as widget file `incoming_order_map.dart` | **Careful:** map controller callback stays wired in parent |
| `_buildServiceChips` | `incoming_service_chips.dart` | Pure display |

**Stays in parent:** `_countdownTimer`, accept/reject handlers calling `IncomingOrderCubit`, navigation to active trip.

### 9.5 Target: `active_trip_page.dart` (~2,066 lines)

**Phase 2 scope — passive controls only:**

| Widget | New file |
|--------|----------|
| `_CompactActionBtn` | `trip_compact_action_button.dart` |
| `_MapControlBtn` | `trip_map_control_button.dart` |

**Do not extract yet:** Map label overlay system, `_positionSubscription`, rider status button logic, `DeliveryToCustomerPage` launch, complaint drawer wiring.

### 9.6 Phase 2 per-commit workflow

1. Copy widget to new file (same parameters).
2. Replace inline class with import.
3. `flutter analyze`
4. Manual QA: screen-specific subset from section 7
5. Commit

### 9.7 Phase 2 exit criteria

- [ ] Each mega file reduced by ≥15% lines ( cumulative )
- [ ] No new analyze errors
- [ ] All section 2 journeys pass on device
- [ ] No API or navigation path changes

---

## 10. Phase 3 Detailed Plan — Reduce setState Safely

**Prerequisite:** Phase 2 stable on at least delivery + map-status drawer.  
**Goal:** Document and optionally group **local UI state** — **no new Cubits yet**.

### 10.1 `courier_map_status_screen.dart`

| State | Type | Phase 3 action |
|-------|------|----------------|
| `_courierOnline` | Business + UI | **Keep** — ties to prefs + heartbeat |
| `_profileName` | UI display | Keep; optional `ValueNotifier` wrapper **only if zero behavior change** |
| `_currentPosition`, `_locationLoading` | GPS | **Keep in State** |
| `_fakeOfferBannerVisible` | UI | Could use `ValueNotifier<bool>` to reduce setState count |
| `_courierMarkerIcon` | UI/resource | Keep |
| `_offerLookupInFlight`, `_openingOfferFlow` | Business guard | **Keep** — do not move |
| Timers | Lifecycle | **Keep in State** |

### 10.2 `incoming_order_page.dart`

| State | Action |
|-------|--------|
| `_courierOnline` (duplicate read) | Document; consolidate in Phase 4 only |
| Map label offsets, `_labelsReady` | Keep local |
| `_countdownTimer` | Keep local |
| Cubit-driven offer/order | Keep using `BlocBuilder` |

### 10.3 `delivery_to_customer_page.dart`

| State | Action |
|-------|--------|
| `_buildingPhotos`, `_orderPhotos` | Keep local (UI lists) |
| `_isPickupSubmitting` | Keep until DeliveryFlowCubit in Phase 4 |
| Cubit `isSubmitting` flags | Already external |

### 10.4 `active_trip_page.dart`

| State | Action |
|-------|--------|
| `_order`, `_loading` | Business — Phase 4 |
| `_deliveryRiderStatus`, `_pickupRiderStatus` | Business — Phase 4 |
| `_routePolyline`, map dimensions | Map UI — keep local Phase 3 |
| `_positionSubscription` | **Never move in Phase 3** |

### 10.5 Phase 3 exit criteria

- setState count reduced on map-status/incoming **only if** QA identical
- Documented state ownership table in `file_ownership_map.md` updated
- Still no new Cubits

---

## 11. Phase 4 Detailed Plan — Cubit/Controller Extraction

**Prerequisite:** Phases 2–3 complete for target screen.  
**Rule:** Reuse existing use cases; **same API call order and navigation side effects**.

### 11.1 `MapStatusController` / `MapStatusCubit` (new)

**Absorb from `courier_map_status_screen.dart`:**

- Offer lookup orchestration (`_getCurrentOfferUseCase`, `_getCurrentOrderUseCase`)
- Post-go-online navigation decisions
- Fake offer banner timing (or separate `OfferBannerController`)

**Inputs:** `autoSearch` flag, cached courier type  
**Outputs:** States: idle, loadingOffer, offerReady(OrderMock), currentOrderReady, error  
**Reuse:** Existing use cases — no repository changes  
**UI listens:** Banner visibility, navigation commands via `BlocListener`  
**Do not change:** GoOnline/GoOffline/Heartbeat Cubit contracts

### 11.2 `IncomingOrderCubit` cleanup (existing)

**File:** `incoming_order_cubit.dart` (~502 lines)

- Split **accept path** vs **reject path** into private methods (same file first)
- Move any remaining offer-load logic from page into cubit **only if** page has duplicate calls
- **Do not change** public method signatures used by page until call sites updated in same PR

### 11.3 `TripFlowCubit` / `TripCubit` (new)

**Absorb from `active_trip_page.dart`:**

- `GetCurrentOrderUseCase` refresh logic
- `UpdateRiderStatusUseCase` transitions
- Status integer machine (delivery vs pickup vs full-time courier)

**Keep in widget:** Map rendering, `GoogleMapController`, `Geolocator` stream (until Phase 5 map widget)

**UI listens:** Order loaded, status updating flags, error messages  
**Reuse:** `PickupStatusCubit` for pickup-specific subflow — do not merge blindly

### 11.4 `DeliveryFlowCubit` enhancement (optional)

**Existing:** `DeliveryCompletionCubit`, `AttemptedDeliveryChecklistCubit`

- Consider thin coordinator if delivery page still orchestrates too much
- **Do not change** upload/submit API sequences

### 11.5 Phase 4 exit criteria

- No direct `getIt<UseCase>()` in `courier_map_status_screen.dart` or `active_trip_page.dart`
- All Phase 2 journeys pass
- Characterization tests for mappers recommended before this phase merges

---

## 12. Phase 5 Detailed Plan — File Movement to Target Architecture

**Prerequisite:** Phase 4 stable; imports verified via IDE + grep.

### 12.1 Move map status screen

| From | To |
|------|-----|
| `lib/screens/courier_map_status_screen.dart` | `lib/features/map_status/presentation/pages/map_status_page.dart` |

**Steps:**

1. Copy file to new path; export typedef or `typedef CourierMapStatusScreen = MapStatusPage` in old file **temporarily** (compat shim — one commit).
2. Update `app_router.dart` import only.
3. Grep all imports of old path; update.
4. Remove shim in follow-up commit after QA.

**Route path stays:** `/map-status`

### 12.2 Move delivery page

| From | To |
|------|-----|
| `lib/features/delivery/delivery_to_customer_page.dart` | `lib/features/delivery/presentation/pages/delivery_to_customer_page.dart` |

**Update import in:** `active_trip_page.dart` only (verified).

**Optional Phase 5b:** Add go_router route for delivery — **separate approved PR** (changes navigation behavior surface).

### 12.3 Widget moves

Move Phase 2 widgets into `features/<feature>/presentation/widgets/` with corrected imports — one feature per PR.

### 12.4 Import safety rules

1. Run: `rg "courier_map_status_screen" lib/` before and after
2. Run: `rg "delivery_to_customer_page" lib/`
3. Full `flutter analyze`
4. Full manual QA section 2

### 12.5 Rollback plan

- Revert the move commit — shim file restores instantly if kept one release
- Do not combine move + logic change

---

## 13. Phase 6 Detailed Plan — Legacy Cleanup

**Last phase only.** Requires sign-off checklist per item.

### 13.1 Candidates (analyze before removing)

| Item | Location | Remove when |
|------|----------|-------------|
| Legacy onboarding signup/otp/document pages | `features/onboarding/presentation/pages/sign_up_page.dart`, etc. | No router/import references |
| Old permission page | `features/permission/presentation/pages/permission_page.dart` | Only `/permission` redirect remains — verify no direct links |
| Commented login files | `auth/presentation/pages/login_page.dart`, `login_screen.dart` | Team confirms unused |
| Mock repositories | `mock_orders_repository.dart`, `mock_orders_data.dart` | Grep shows no DI registration |
| `OrdersRepository` (legacy) | `domain/repositories/orders_repository.dart` | No consumers |
| `OrderMock` | widespread | **Only after all UI uses MobileOrder + view models** — separate major program |
| GetX `core_translations_data.dart` | core/locale | After ARB migration project |
| `lib/screens/` folder | after map status moved | Empty |

### 13.2 Deletion gate (all must pass)

- [ ] `rg` import count = 0
- [ ] Not in `app_router.dart`
- [ ] Not in navigation `extra` types
- [ ] `flutter analyze` clean
- [ ] Full critical journey QA (section 2)

---

## 14. Risk Matrix

| Risk | Severity | Files involved | How to avoid | How to test | Rollback |
|------|----------|----------------|--------------|-------------|----------|
| Break go_router redirect | Critical | `app_router.dart`, `onboarding_state.dart` | Do not edit redirect until Phase 5+ | Cold start paths: logged out/in, partial onboarding | Revert router commit |
| Break token refresh | Critical | `auth_token_interceptor.dart` | No interceptor changes in Phases 1–3 | Login → background → API call | Revert |
| Break go online / heartbeat | Critical | map-status, heartbeat/go_online cubits | Do not modify Cubit emit order | Toggle online 5x, kill app | Revert |
| Break offer accept → trip | Critical | incoming cubit, mappers, router | No mapper changes Phase 1–3 | Accept offer E2E | Revert |
| Break delivery photo upload | High | delivery cubits, data source | UI-only Phase 2 | Complete delivery with photos | Revert widget PR |
| GPS stream leak / freeze | High | `active_trip_page.dart` | Do not move subscription Phase 2–3 | Long trip simulation | Revert |
| OrderMock cast crash | High | router, trip, incoming | Never change extra types early | Navigate with/without extra | Revert |
| Duplicate online key desync | Medium | map-status, orders, incoming, heartbeat | Document only until approved consolidation | Toggle online on each screen | Revert consolidation |
| RTL layout regression | Medium | map labels, drawer | Extract widgets with same Directionality | AR locale QA | Revert widget |
| Import break on file move | Medium | moved files | Shim + grep | analyze + compile | Revert move |
| Timer not cancelled | Medium | map-status, incoming | Keep timer lifecycle in State | Open/close screens rapidly | Revert |
| Accidental API URL change | Critical | `api_constants.dart`, data sources | Exclude from refactor PRs | API smoke | Revert |

---

## 15. Definition of Done

The safe refactoring program (Phases 1–5) is **done** when:

### 15.1 Functional

- [ ] All **26 critical journeys** (section 2) pass on Android (and iOS if supported)
- [ ] API behavior unchanged (endpoints, payloads, parsing, token refresh)
- [ ] Navigation paths and redirect behavior unchanged from pre-refactor baseline
- [ ] Session persistence and logout unchanged
- [ ] Arabic and English both verified on map-status, trip, incoming, delivery, orders

### 15.2 Structural

- [ ] `active_trip_page.dart` ≤ 800 lines **or** justified with remaining map/GPS ownership
- [ ] `delivery_to_customer_page.dart` ≤ 600 lines (logic in Cubits)
- [ ] `incoming_order_page.dart` ≤ 800 lines
- [ ] `courier_map_status_screen.dart` moved to `features/map_status/` and ≤ 600 lines
- [ ] No direct use case calls in widget/state classes for map-status and active trip
- [ ] `lib/screens/` removed or empty

### 15.3 Quality

- [ ] `flutter analyze` — no errors (new warnings documented)
- [ ] No new dependencies required for structure
- [ ] `file_ownership_map.md` reflects final ownership
- [ ] Each phase branch merged with QA notes

### 15.4 Explicitly NOT required for Phase 1–5 done

- OrderMock removal
- GetX localization removal
- Legacy onboarding deletion (Phase 6)
- Full unit test coverage
- New delivery route in go_router

---

## Appendix A — Suggested `file_ownership_map.md` outline (Phase 1)

Create this file in Phase 1 with:

1. Mega screen ownership table (state, cubits, use cases, timers)
2. Navigation graph (mermaid) for map-status ↔ incoming ↔ trip ↔ delivery
3. SharedPreferences key ownership
4. Legacy file registry with “keep until Phase 6” flag
5. Open questions / known checklist URL version mismatch

---

## Appendix B — Quick reference: first implementation PR

**Smallest safe first code PR after Phase 1 docs:**

> Extract `_StepHeader` from `delivery_to_customer_page.dart` to  
> `features/delivery/presentation/widgets/delivery_step_header.dart`  
> — no logic changes, one widget, one import update.

**Verify with:** open delivery flow from active trip → confirm all three steps render.

---

*End of execution plan. No production Dart files were modified.*
