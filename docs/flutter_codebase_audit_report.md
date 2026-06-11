# Gaseel Courier — Flutter Codebase Audit Report

**Project:** `gaseel_courier` (v1.0.4+101)  
**Audit date:** June 7, 2026  
**Scope:** Full `lib/` analysis — read-only, no refactoring performed  
**Dart files in `lib/`:** 276  
**Primary stack:** Flutter 3.8+, `go_router`, `flutter_bloc`, `get_it`, `Dio`, Firebase Messaging, Google Maps

---

## Executive Summary

The Gaseel Courier app is a functional courier/delivery application with a **partially modernized architecture**. Several domains (authentication, orders API, driver availability, courier profile) follow a recognizable **Clean Architecture** pattern with data sources, repositories, use cases, and Cubits. However, the **core operational flows** — map status, incoming orders, active trip, and delivery completion — are implemented as **very large monolithic screens** that mix UI, map logic, GPS, API calls, navigation, and business rules in single files (1,000–2,000+ lines).

The folder structure is **feature-based with significant inconsistency**: some features are fully layered (`auth/login`, `orders`, `driver_availability`), while others lack `data/`/`domain/` layers entirely (`trip`, `incoming`, `delivery`, `chat`, `profile`, `settings`, `stats`). A legacy `lib/screens/` folder and duplicate onboarding/auth pages add navigation and maintenance risk.

State management is **primarily Cubit/BLoC**, but heavy `setState` remains in map/trip screens. Localization uses **three parallel systems** (Flutter ARB gen-l10n, GetX translation maps, legacy proxies). API networking is **reasonably centralized** via Dio and interceptors, though some screens bypass repositories and call use cases or services directly.

**Overall assessment:** The codebase is maintainable for the current team but **not yet scalable** for parallel feature development. Refactoring should prioritize splitting mega-screens, consolidating duplicate flows/models, and standardizing feature structure before adding new features.

---

## 1. Current Project Structure Analysis

### 1.1 Top-Level Layout

```
lib/
├── app.dart                 # Root widget (GetMaterialApp.router + ScreenUtil + Bloc)
├── main.dart                # Bootstrap, Firebase, DI, error zones
├── firebase_options.dart
├── core/                    # Cross-cutting infrastructure & shared UI
├── features/                # Feature modules (17 top-level features)
├── l10n/                    # Generated + ARB localization
└── screens/                 # Legacy screen(s) outside features
```

### 1.2 `core/` Modules

| Folder | Purpose |
|--------|---------|
| `audio/` | Alert sound for incoming orders |
| `auth/` | Session logout, login flags (`AuthService`) |
| `config/` | Maps/API keys config |
| `courier/` | Courier-related helpers |
| `di/` | GetIt dependency injection (`dependency_injection.dart`, ~401 lines) |
| `diagnostics/` | App diagnostics |
| `firebase/` | FCM token, push notifications (~388 lines) |
| `helpers/` | SharedPreferences keys, helpers |
| `locale/` | Locale controller, GetX translations, CoreLocalizer, legacy proxies (~1,464 lines in `core_translations_data.dart`) |
| `localization/` | Thin re-export/compatibility layer for `AppLocalizations` |
| `maps/` | Directions service, marker factory |
| `networking/` | Dio client, API constants, interceptors, `ApiException` |
| `onboarding/` | Global onboarding/session gate (`OnboardingState`) |
| `orders/` | Mock order matcher (legacy) |
| `profile/` | Profile service (local profile data) |
| `router/` | Central `GoRouter` config (~374 lines) |
| `theme/` | `AppTheme`, `ThemeController` |
| `utils/` | Validators (~497 lines), locale helper, observers |
| `widgets/` | Shared buttons, text fields, OTP page, snack bar (5 files) |

### 1.3 `features/` Modules

| Feature | Structure | Notes |
|---------|-----------|-------|
| `auth/` | Sub-features: `login`, `sign_up`, `forget_password`, `otp`, `documents/*`, legacy `presentation/` | Best-structured area; clean layers in login/signup/forget-password |
| `courier_profile/` | Full clean architecture | Remote + local data sources |
| `driver_availability/` | Full clean architecture | Go online/offline, heartbeat |
| `orders/` | Full clean architecture + mock legacy | `MobileOrdersRepository` is live; `OrdersRepository` + mocks remain |
| `delivery/` | Cubits only + root-level page | `delivery_to_customer_page.dart` not under `presentation/pages/` |
| `incoming/` | Cubit + mappers + mega pages | No repository layer |
| `trip/` | Cubit + mega pages/widgets | No data/domain layers |
| `onboarding/` | Pages only | **Duplicates** auth signup/document flows |
| `permission/` | Single legacy page | Superseded by `onboarding/permissions_page.dart` |
| `splash`, `home`, `map`, `profile`, `settings`, `stats`, `notifications`, `chat` | Mostly presentation-only | Minimal or no domain/data layers |

### 1.4 Where Things Live

| Concern | Location |
|---------|----------|
| **Screens/Pages** | `features/*/presentation/pages/`, plus legacy `lib/screens/`, and root-level pages (`delivery_to_customer_page.dart`, `customer_chat_screen.dart`) |
| **Widgets** | Feature `presentation/widgets/`, `core/widgets/` |
| **Models** | `features/*/data/models/` (DTOs), `features/*/domain/models/` or `domain/entities/` |
| **State (Cubits)** | `features/*/presentation/cubit/` |
| **API calls** | `features/*/data/datasources/*_remote_data_source.dart`, `core/networking/` |
| **Repositories** | `features/*/data/repositories/` + domain interfaces |
| **Use cases** | `features/*/domain/usecases/` |
| **Constants** | `core/helpers/constants.dart`, `core/networking/api_constants.dart`, feature UI constants (e.g. `orders_ui_constants.dart`) |
| **Routing** | `core/router/app_router.dart` |
| **Localization** | `lib/l10n/*.arb`, generated `app_localizations*.dart`, `core/locale/core_translations_data.dart`, GetX `AppTranslations` |
| **Assets** | `assets/logo/`, `assets/images/`, `assets/markers/`, `assets/audio/`, `assets/sounds/` (declared in `pubspec.yaml`) |
| **Theme** | `core/theme/app_theme.dart` |

### 1.5 Structure Classification

**Mixed architecture — feature-based shell with inconsistent internal layering.**

- ~40% of features follow **Clean Architecture** (auth subflows, orders, driver availability, courier profile).
- ~60% are **presentation-heavy or monolithic**, especially operational/map flows.
- Legacy artifacts (`lib/screens/`, mock repositories, duplicate onboarding) indicate an **ongoing migration** rather than a finished structure.

---

## 2. Large Files / Code Smells

### 2.1 Critical Large Files (>400 lines, excluding generated l10n)

| File | ~Lines | Responsibilities (mixed) |
|------|--------|---------------------------|
| `features/trip/presentation/pages/active_trip_page.dart` | **2,066** | Google Map rendering, polyline/labels, GPS tracking, rider/pickup status machine, API via use cases, navigation, delivery handoff, chat launch, complaint drawer, localization helpers |
| `features/delivery/delivery_to_customer_page.dart` | **1,715** | Photo capture/upload UI, delivery & attempted-delivery flows, checklist Cubits, hardcoded colors, navigation, chat, proof photo logic, inline `_resolveL10n` |
| `features/incoming/presentation/pages/incoming_order_page.dart` | **1,545** | Incoming offer map UI, curved polylines, accept/reject, countdown, audio alerts, drawer, online toggle, logout, navigation |
| `core/locale/core_translations_data.dart` | **1,464** | Manual EN/AR string maps (parallel to ARB) |
| `screens/courier_map_status_screen.dart` | **1,270** | Main hub map, go online/offline, offer polling, fake offer banner, profile drawer, heartbeat integration, direct use case calls |
| `features/chat/customer_chat_screen.dart` | **1,034** | Chat UI (likely mock/local), RTL handling, hardcoded strings |
| `features/trip/presentation/pages/active_trip_full_map_page.dart` | **807** | Full-screen trip map variant |
| `features/orders/data/datasources/orders_remote_data_source.dart` | **592** | All order API endpoints, logging, error mapping, multipart upload |
| `features/onboarding/presentation/pages/sign_up_page.dart` | **586** | Legacy signup UI (duplicates auth signup) |
| `features/auth/sign_up/presentation/cubit/sign_up_phone_number_cubit.dart` | **558** | OTP send/verify/register orchestration — too large for a Cubit |
| `features/onboarding/presentation/pages/permissions_page.dart` | **525** | Permissions UI + platform logic (active route) |
| `features/incoming/presentation/cubit/incoming_order_cubit.dart` | **502** | Offer accept/reject, order mapping, audio, state machine |
| `core/utils/validator_utils.dart` | **497** | All form validators + English-only messages |
| `features/auth/sign_up/presentation/pages/sign_up_page.dart` | **462** | Registration form UI |
| `features/orders/presentation/widgets/mock_order_card.dart` | **439** | Order card UI (still mock-oriented naming) |
| `features/orders/presentation/pages/orders_page.dart` | **431** | Orders list + online toggle + profile photo + filtering |
| `features/profile/presentation/pages/profile_page.dart` | **421** | Profile UI |
| `core/di/dependency_injection.dart` | **401** | All DI registrations in one file |

### 2.2 UI + Business Logic + API Mixed Together

These files contain **direct API/use-case invocation inside StatefulWidgets**, not just Cubits:

- `courier_map_status_screen.dart` — calls `GetCurrentOrderUseCase`, `GetCurrentOfferUseCase` directly
- `active_trip_page.dart` — calls `GetCurrentOrderUseCase`, `UpdateRiderStatusUseCase`, manages map + status transitions
- `incoming_order_page.dart` — mixes Cubit with extensive local map/GPS state
- `delivery_to_customer_page.dart` — Cubits exist but page owns most flow orchestration
- `orders_page.dart` — Cubit for orders but local state for online status, profile, courier type

### 2.3 Duplication Patterns

| Pattern | Examples |
|---------|----------|
| **`_resolveL10n` helper** | Duplicated in 11 files (trip, incoming, delivery, map status, chat widgets) |
| **Login pages** | `auth/login/presentation/pages/login_page.dart` (active), commented-out `auth/presentation/pages/login_page.dart`, commented-out `login_screen.dart` |
| **Signup flows** | `features/auth/sign_up/*` (active) vs `features/onboarding/presentation/pages/sign_up_page.dart` (586 lines, legacy) |
| **Permissions** | `onboarding/permissions_page.dart` (routed) vs `permission/permission_page.dart` (legacy, `/permission` redirects) |
| **Document upload** | `auth/documents/document_upload/` vs `onboarding/document_upload_page.dart` |
| **OTP verification** | `auth/otp/` vs `onboarding/otp_verification_page.dart` |
| **Order models** | `MobileOrder` (API domain) + `OrderMock` (UI) + mappers in `incoming/data/mappers/` |
| **Orders repositories** | `MobileOrdersRepository` (live) vs `OrdersRepository` + `MockOrdersRepository` (legacy) |
| **Primary color** | `AppTheme.primaryColor` vs hardcoded `Color(0xFF23C1B2)` in delivery and many widgets |
| **Text form fields** | `core/widgets/custom_text_form_field.dart` vs auth-specific duplicates (`custon_text_form_feild.dart`, `custom_textFormFeild.dart`) |
| **Loading/error snackbars** | Repeated `ScaffoldMessenger` / `AppSnackBar` patterns per screen |

### 2.4 Naming / Path Smells

- `vehicle_registration_details/presentaion/` — typo (**presentaion**)
- `forget_passoword_otp_verification_page.dart` — typo (**passoword**)
- `custon_text_form_feild.dart`, `phone_number_feild.dart` — typos (**custon**, **feild**)
- `mock_order_card.dart` used in production orders UI

---

## 3. State Management Review

### 3.1 Current Approach

| Tool | Usage |
|------|-------|
| **flutter_bloc / Cubit** | Primary pattern for auth, orders, driver availability, incoming offers, delivery completion, pickup status |
| **get_it** | Service locator for Cubits, repositories, use cases, Dio |
| **ChangeNotifier** | `OnboardingState`, `LocaleController`, `ThemeController` |
| **setState** | Heavy use in map/trip/incoming/delivery screens (15–21 calls in largest files) |
| **GetX** | Used mainly for `GetMaterialApp`, `.tr` in a few places, and `AppTranslations` — **not** primary state management |

### 3.2 Where State Lives

- **Global/session:** `OnboardingState.instance` (login, permissions, location setup flags) — drives router redirects
- **App-level Cubit:** `HeartbeatCubit` provided at app root
- **Route-level Cubits:** Created in `AppRouter` or page `BlocProvider` (e.g. `IncomingOrderCubit`, `GoOnlineCubit`)
- **Local widget state:** Map controllers, GPS streams, photo lists, timers, banners — inside mega StatefulWidgets

### 3.3 Separation Quality

| Area | UI / State Separation |
|------|----------------------|
| Auth login, forget password | Good — Cubits own form/API state |
| Sign up phone OTP | Moderate — `sign_up_phone_number_cubit.dart` is oversized (558 lines) |
| Orders list | Moderate — `OrdersCubit` exists but page keeps online/profile state locally |
| Map status / trip / incoming / delivery | **Poor** — business rules, API, and UI intertwined |

### 3.4 Screens with Heavy setState + Business Logic

1. `courier_map_status_screen.dart` (21 setState, direct use cases)
2. `active_trip_page.dart` (15 setState, status machine inline)
3. `incoming_order_page.dart` (11 setState)
4. `active_trip_full_map_page.dart` (10 setState)
5. `onboarding/sign_up_page.dart` (15 setState — legacy)
6. `permission_page.dart` (11 setState — legacy)

### 3.5 Recommended Improvements (future)

- Introduce dedicated Cubits/Blocs for **map status**, **active trip**, and **delivery flow** — move status machines out of widgets
- Standardize on **one** app shell state source for courier online/offline (currently duplicated in SharedPreferences keys across screens)
- Split oversized Cubits (`sign_up_phone_number_cubit`, `incoming_order_cubit`) into smaller units
- Remove GetX dependency long-term if only used for translations (reduce dual-framework complexity)
- Use `BlocListener` consistently for navigation side-effects instead of navigating inside build methods

---

## 4. API / Data Layer Review

### 4.1 HTTP Client Setup

- **Client:** Dio via `core/networking/dio_client.dart`
- **Base URL:** Auth API (`https://auth.gaseelexpress.sa`); courier endpoints use full URLs in `ApiConstants`
- **Interceptors:**
  - `RequestStatusInterceptor` — request/response status handling
  - `AuthTokenInterceptor` (~365 lines) — Bearer token attach, 401 refresh single-flight, force logout
- **DI:** Single shared `Dio` instance registered in GetIt

### 4.2 API Constants

Centralized in `core/networking/api_constants.dart`:

- Auth: login, register, OTP, reset password, refresh token
- Courier: orders, current order/offer, accept/reject, rider/pickup status, proof photo, checklist
- Driver availability: go online/offline, heartbeat
- Profile: `GET /api/courier/me`

**Risk:** Checklist endpoints use `/api/mobile/orders/` while others use `/api/v1/mobile/orders/` — possible versioning inconsistency.

### 4.3 Data Access Patterns

| Pattern | Features |
|---------|----------|
| **Remote data source → repository → use case → Cubit** | auth, orders, driver_availability, courier_profile, forget_password |
| **Use case called directly from UI** | map status screen, active trip page |
| **Cubit calls repository/use case** | orders list, incoming order, delivery completion |
| **Legacy/mock** | `mock_orders_repository.dart`, `mock_orders_data.dart`, `core/orders/mock_order_matcher.dart` |
| **Non-Dio HTTP** | `directions_service.dart` uses `http` package for Google Directions |

### 4.4 Cross-Cutting API Concerns

| Concern | Status |
|---------|--------|
| **Token handling** | Centralized in `AuthTokenInterceptor` with refresh + retry |
| **Error mapping** | `ApiException` exists; mapping duplicated in each data source (`_mapDioException`, `_throwIfRequestFailed`) |
| **Logging** | Verbose debug logging in data sources and interceptors — not centralized |
| **Retry** | Token retry only; no general network retry |
| **Parsing** | Model `fromJson` in data layer; some manual map unwrapping per endpoint |

### 4.5 Risks

1. **Direct use case calls from UI** bypass consistent error/loading handling
2. **Dual order model pipeline** (`MobileOrder` → mappers → `OrderMock`) increases bug surface during API changes
3. **Legacy mock repositories** may be accidentally wired back in
4. **Large data sources** (`orders_remote_data_source.dart`) hard to test and extend
5. **Secure storage + SharedPreferences** both store tokens — logout must clear both (handled in `AuthService`, but fragile if new keys added ad hoc)

---

## 5. Models / DTOs Review

### 5.1 Model Inventory

**Auth / Profile**

- `AuthUserModel`, register/OTP result models
- `CourierProfileModel` / `CourierProfile` entity
- Forget-password result models

**Orders (live API)**

- `MobileOrderModel`, `MobileOrderOfferModel`, `OrdersPageResultModel`
- `OrderChecklistQuestionModel`, `ProofPhotoUploadResultModel`
- Domain: `MobileOrder`, `MobileOrderOffer`, enums for status/rider/pickup states

**Orders (legacy/mock)**

- `Order`, `OrderMock`, `IncomingOrderMock`, `OrderItemMock`
- `mock_orders_data.dart`

**Driver availability**

- Request/result models for go online/offline, heartbeat

**Presentation models**

- `OrdersFilters`, `IncomingOrderRouteArgs`

### 5.2 Organization Assessment

| Aspect | Rating | Notes |
|--------|--------|-------|
| Feature grouping | Good for auth/orders/availability | |
| Entity vs DTO separation | Partial | Some domain models in `domain/models/` not `entities/` |
| JSON consistency | Moderate | Most use `fromJson`; wrapper `{ data: ... }` handled manually |
| Mock vs real separation | **Poor** | `OrderMock` used in production navigation and UI |

### 5.3 Key Problems

1. **`OrderMock` is a UI-era model** still used as navigation arguments and primary display model in trip/incoming flows despite live `MobileOrder` API
2. **Three parallel order representations:** `Order` (legacy repo), `MobileOrder`, `OrderMock`
3. **Duplicate enums:** `OrderStatusMock` vs `MobileOrderStatus`, etc.
4. **Validation messages** in `validator_utils.dart` are English-only constants, not localized

### 5.4 Recommended Model Organization (future)

```
features/orders/
  domain/
    entities/          # MobileOrder, MobileOrderOffer (pure domain)
    value_objects/     # OrderId, RiderStatus, etc.
  data/
    models/            # *Model DTOs with fromJson/toJson
    mappers/           # MobileOrderModel -> MobileOrder
  presentation/
    view_models/       # UI-specific formatted state (optional)
```

- Deprecate `OrderMock` gradually; use `MobileOrder` + presentation view models
- Remove unused `OrdersRepository` / `Order` when mock flow is fully retired

---

## 6. Routing / Navigation Review

### 6.1 Solution

- **go_router** (`GoRouter` in `core/router/app_router.dart`)
- Wrapped in **GetMaterialApp.router** (hybrid — unusual but functional)
- **Auth guard:** `redirect` callback + `OnboardingState.instance` as `refreshListenable`

### 6.2 Route Organization

Routes defined in a **single flat file** (~374 lines) with nested routes for:

- `/splash`, `/login`, `/signup/*`, document routes, `/permissions`, `/location-setup`
- `/home/*` (orders, stats, profile, settings)
- `/map-status` (main post-login hub)
- `/active-trip/:id` (+ full map sub-route)
- `/incoming-order` (+ map sub-route)
- Standalone: `/orders`, `/map`, `/notifications`

### 6.3 Navigation Arguments

| Route | Argument style | Risk |
|-------|----------------|------|
| Forget password OTP | `Map<String, dynamic>` | Untyped keys (`phoneNumber`, `nextRoute`) |
| Signup OTP | `Map` or raw `String` | Inconsistent |
| Active trip | `OrderMock` or `Map` | Unsafe cast |
| Incoming order | `IncomingOrderRouteArgs` or raw `OrderMock` | Partially typed |
| Incoming full map | `OrderMock?` | Null falls back to broken page |

**Positive:** `IncomingOrderRouteArgs` is a step toward typed extras.

### 6.4 Issues

- **Magic path strings** scattered (`context.go('/map-status')`, `'/orders'`, etc.) — no centralized route constants/enums
- **Duplicate entry points** to orders: `/orders` and `/home/orders`
- **Legacy redirect:** `/permission` → `/permissions`
- **`DeliveryToCustomerPage`** is **not routed** — pushed via `Navigator` from `active_trip_page.dart` (imperative, untyped)
- **Commented/dead routes** in legacy files create confusion

### 6.5 Risks

- Breaking redirect logic affects entire app access
- Unsafe `extra` casting causes runtime crashes
- Imperative `Navigator.push` for delivery bypasses go_router deep linking

---

## 7. UI / Widgets Review

### 7.1 Shared Widgets (`core/widgets/`)

- `custom_button.dart`
- `custom_text_form_field.dart`
- `custom_otp_verification_page.dart`
- `app_snack_bar.dart`
- `scaffold_auth.dart`

**Assessment:** Minimal shared library — most UI is feature-local.

### 7.2 Reusable Feature Widgets (good candidates for promotion)

- `orders_page_widgets.dart`, `order_card.dart`, `orders_drawer.dart`
- `incoming_map_controls.dart`, `earnings_card.dart`, `labeled_marker_widget.dart`
- `active_order_details_sheet.dart`, `complaint_drawer_content.dart`
- Auth: `login_header.dart`, `login_footer.dart`, `phone_number_field.dart`, document widgets

### 7.3 Screens Needing Widget Extraction

| Screen | Suggested splits |
|--------|------------------|
| `active_trip_page.dart` | Map layer, status action bar, order details sheet, route overlay, rider status controller |
| `incoming_order_page.dart` | Map canvas, offer card, countdown header, accept/reject footer |
| `courier_map_status_screen.dart` | Map view, online toggle FAB, offer banner, navigation drawer |
| `delivery_to_customer_page.dart` | Photo grid, checklist section, customer info card, action buttons |
| `customer_chat_screen.dart` | Message list, input bar, header |

### 7.4 Theme & Styling Consistency

**Centralized:** `AppTheme` (primary `#23C1B2`, background `#F6FBFB`), Material 3, `flutter_screenutil` (design size 393×851)

**Inconsistent:**

- Hardcoded `Color(0xFF23C1B2)` in delivery and many widgets (~70+ files use raw `Colors.*` or hex)
- `orders_ui_constants.dart` — feature-local colors/spacing
- Mixed use of `Theme.of(context)` vs hardcoded values
- Stats page uses `'stats'.tr` (GetX) while most use `AppLocalizations`

---

## 8. Localization / RTL-LTR Review

### 8.1 Current Approach (Triple System)

1. **Flutter gen-l10n** — `lib/l10n/app_en.arb`, `app_ar.arb` → generated `AppLocalizations` (~1,180+ keys in ARB)
2. **GetX translations** — `core/locale/core_translations_data.dart` (~1,464 lines) via `AppTranslations` + `CoreLocalizer` / `AppI18n.t()`
3. **Legacy** — `legacy_l10n_proxy.dart`, `legacy_l10n_keys.dart`

`App` configures:

- `supportedLocales: [ar, en]`
- `AppTranslations()` for GetX
- `LocaleController` for persisted locale override

### 8.2 Arabic/English Support

- **Supported** at framework level (Material/Cupertino delegates, ARB files)
- Bilingual content in order items (`nameEn` / `nameAr`) and mock models
- Manual RTL handling in map/chat widgets (`TextDirection`, `isArabic` checks)

### 8.3 Hardcoded Strings (high-risk areas)

- `delivery_to_customer_page.dart` — e.g. `'You can add up to N photos'`
- `customer_chat_screen.dart` — chat placeholders/messages
- `validator_utils.dart` — all validation messages in English
- `stats_page.dart` — `'Statistics Page'`, `'Your statistics will appear here'`
- Debug/log strings (acceptable) vs user-facing strings (not acceptable)

### 8.4 RTL/LTR Risks

- Dual localization APIs may resolve **different strings** for the same concept
- Map label offsets and marker bubbles may break in RTL if not using `Directionality.of(context)`
- Mixed `.tr`, `AppLocalizations`, and `context.t()` in same app causes inconsistent translations
- `_resolveL10n` fallback to English when context not ready — may flash wrong language

### 8.5 Screens Needing Localization Cleanup

1. `delivery_to_customer_page.dart`
2. `customer_chat_screen.dart`
3. `stats_page.dart`
4. `validator_utils.dart` (move messages to ARB)
5. Legacy onboarding pages if kept temporarily

---

## 9. Assets / Theme / Constants Review

### 9.1 Assets

Declared in `pubspec.yaml`:

- `assets/logo/`, `assets/images/`, `assets/markers/`, `assets/audio/`, `assets/sounds/`
- Launcher icon + native splash configured via `flutter_launcher_icons` and `flutter_native_splash`

### 9.2 Constants Files

| File | Contents |
|------|----------|
| `core/helpers/constants.dart` | `SharedPrefKeys` |
| `core/networking/api_constants.dart` | Base URLs, endpoints |
| `core/config/maps_config.dart` | Maps configuration |
| `features/orders/presentation/widgets/orders_ui_constants.dart` | Orders UI sizing/colors |
| Inline constants | Rider status ints, courier type IDs, SharedPreferences keys duplicated across screens |

### 9.3 Theme

- **Central theme:** `core/theme/app_theme.dart` (light + dark)
- **ThemeController** persists user preference
- **Problem:** Widespread hardcoded colors/dimensions reduce theme effectiveness

### 9.4 Hardcoded Business Constants

- Rider/pickup status integers duplicated in `active_trip_page.dart`
- `_fullTimeCourierTypeId = 3` in multiple files
- `_kCourierOnlineKey = 'courier_online'` duplicated (also in HeartbeatCubit)
- Fake offer banner timers in map status screen

---

## 10. Feature-by-Feature Map

| Feature | Main Screens | Key Widgets | Models / Services | Current Problems | Suggested Restructuring |
|---------|--------------|-------------|-------------------|------------------|-------------------------|
| **Splash** | `splash_page.dart` | — | SharedPref splash flag | Minimal | Keep thin; move timing config to core |
| **Authentication / Login** | `auth/login/.../login_page.dart` | login_header, login_footer, phone_number_field | LoginCubit, LoginRepository, AuthUserModel | Legacy commented login files remain | Delete dead code; single login entry |
| **Sign Up / Registration** | sign_up_phone_page, sign_up_page, welcome_page | Many sign_up widgets | SignUpPhoneNumberCubit (558 lines), SignUpCubit | Oversized Cubit; typo filenames | Split Cubit; consolidate widgets under `presentation/` |
| **OTP** | auth/otp/otp_verification_page | otp_phone_hint_card | OtpCubit | Duplicate onboarding OTP page | Remove onboarding duplicate |
| **Forget Password** | forget_password, OTP, create_new_password | — | 3 Cubits, ForgetPasswordRepository | Typo in OTP filename | Fix naming; keep clean layers |
| **Documents / KYC** | iqama, license, selfie, driver_card, vehicle_registration, document_upload | custom_document_item | Mostly local state + ProfileService | Typo folder `presentaion`; no API layer visible | Standardize paths; add upload repository if API exists |
| **Onboarding (legacy)** | permissions_page, location_setup, sign_up, document_upload, otp, awaiting_review | — | OnboardingState | **Duplicates auth**; 7 legacy pages | Merge into auth/onboarding feature or delete |
| **Permissions** | onboarding/permissions_page (active), permission/permission_page (legacy) | — | OnboardingState, PermissionHandler | Two implementations | Delete `features/permission/` |
| **Driver Availability** | Used from map status | — | GoOnline/GoOffline/Heartbeat Cubits, repositories | Online state also stored ad hoc in UI | Single source of truth for online status |
| **Map Status (Hub)** | `screens/courier_map_status_screen.dart` | — | Use cases, heartbeat, mappers | **1,270-line screen outside features/**; direct API | Move to `features/map_status/`; MapStatusCubit |
| **Incoming Orders** | incoming_order_page, incoming_order_full_map_page | earnings_card, countdown, map controls | IncomingOrderCubit, mappers | Mega page; OrderMock dependency | Split widgets; ActiveOfferCubit; use MobileOrder |
| **Active Trip** | active_trip_page, active_trip_full_map_page | active_order_details_sheet, complaint_drawer | PickupStatusCubit, use cases | **2,066 lines**; status machine in UI | TripCubit + MapWidget + StatusActionPanel |
| **Delivery Completion** | delivery_to_customer_page | — | DeliveryCompletionCubit, AttemptedDeliveryChecklistCubit | Not in presentation/pages; not in router | `features/delivery/presentation/pages/` + route |
| **Orders Dashboard** | orders_page | order_card, filters, drawer, mock_order_card | OrdersCubit, MobileOrdersRepository | Mock naming; local online state | Rename widgets; extract OnlineStatusCubit |
| **Order Details / History** | order_history_bottom_sheet, active_order_details_sheet | — | OrderMock | Mock-oriented | Bind to MobileOrder view models |
| **Customer Chat** | customer_chat_screen.dart | — | Likely local/mock | 1,034 lines at feature root | `presentation/pages/` + ChatCubit if API added |
| **Profile** | profile_page | — | ProfileService, CourierProfileLocalDataSource | No dedicated Cubit | Add ProfileCubit using GetCourierProfileUseCase |
| **Courier Profile (API)** | Used in permissions | — | CourierProfileCubit, repository | Split from UI profile feature | Merge profile features |
| **Settings / Logout** | settings_page, settings_bottom_sheet | settings widgets | AuthService.logout | GetX `.tr` mixed with l10n | Single l10n approach |
| **Notifications** | notifications_page | — | PushNotificationService | Mostly UI shell | Connect to API when available |
| **Stats / Reports** | stats_page | — | — | Placeholder hardcoded English | Implement or hide tab until ready |
| **Home Shell** | home_shell_page → home_page | Bottom nav | — | Thin wrapper | OK as app shell |
| **Map (standalone)** | map_page.dart | — | DirectionsService | Overlaps with trip/incoming maps | Consolidate map components in `core/maps/` or shared feature |
| **Wallet** | — | — | — | **Not present** | N/A |
| **Add Products / Invoice** | — | — | — | **Not present** in courier app | N/A |

---

## 11. Recommended Target Architecture

### 11.1 Recommended Pattern

**Feature-first Clean Architecture with a shared core** — matching what auth/orders already started, extended to operational features.

### 11.2 Proposed Folder Structure

```
lib/
├── app/
│   ├── app.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   ├── route_paths.dart          # Typed route constants
│   │   └── route_extra_models.dart   # Typed navigation args
│   └── di/
│       ├── injection.dart
│       └── injection.config.dart     # optional: injectable/codegen later
│
├── core/
│   ├── constants/
│   │   ├── api_constants.dart
│   │   ├── storage_keys.dart
│   │   └── business_constants.dart   # rider statuses, courier types
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   ├── network/
│   │   ├── dio_client.dart
│   │   ├── interceptors/
│   │   ├── api_exception.dart
│   │   └── network_logger.dart
│   ├── errors/
│   │   ├── failures.dart
│   │   └── error_mapper.dart
│   ├── session/
│   │   ├── auth_service.dart
│   │   └── onboarding_state.dart
│   ├── maps/
│   ├── firebase/
│   ├── utils/
│   ├── extensions/
│   ├── l10n/                         # Single localization strategy
│   └── widgets/                      # Truly shared UI only
│
├── features/
│   ├── auth/
│   │   ├── login/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── sign_up/
│   │   ├── forget_password/
│   │   └── documents/
│   │
│   ├── onboarding/                   # Permissions + location setup ONLY
│   │   └── presentation/
│   │
│   ├── map_status/                   # Former courier_map_status_screen
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │       ├── cubit/
│   │       ├── pages/
│   │       └── widgets/
│   │
│   ├── incoming/
│   ├── trip/
│   ├── delivery/
│   ├── orders/
│   ├── driver_availability/
│   ├── courier_profile/
│   ├── chat/
│   ├── notifications/
│   ├── settings/
│   └── profile/
│
└── l10n/                             # ARB + generated (primary i18n)
```

### 11.3 Layer Responsibilities

| Layer | Responsibility |
|-------|----------------|
| **presentation** | Pages, widgets, Cubits/Blocs, UI state, navigation triggers |
| **domain** | Entities, repository interfaces, use cases, failures (Either/dartz optional) |
| **data** | DTOs, mappers, remote/local data sources, repository implementations |

### 11.4 Key Conventions

- **Naming:** `snake_case.dart`; pages end with `_page.dart`; Cubits end with `_cubit.dart`
- **Routes:** All paths in `route_paths.dart`; extras as typed classes
- **API:** UI never imports `Dio`; only data sources call HTTP
- **Errors:** Map to user messages in Cubit via shared `ErrorMapper`
- **Loading:** Standard `UiState<T>` or sealed state classes (initial/loading/success/failure)
- **Localization:** **ARB only** — migrate off `core_translations_data.dart` incrementally
- **Shared UI:** Map widgets, order cards, photo picker → `core/widgets/` or `features/shared/`

### 11.5 Operational Flow Target

```
MapStatusCubit → polls offer/order
IncomingOrderCubit → accept/reject
TripCubit → rider/pickup status machine
DeliveryCubit → photos + checklist + completion
```

Each with small widgets bound via `BlocBuilder`.

---

## 12. Migration / Refactoring Roadmap

### Phase 1: Documentation and File Map (Low risk)

| Item | Detail |
|------|--------|
| **Move/refactor** | Document feature ownership, mark legacy files (@Deprecated), create ARCHITECTURE.md |
| **Files affected** | None functionally — docs only (this report is the first deliverable) |
| **Must not break** | Nothing |
| **Test** | N/A |
| **Benefit** | Shared mental model for team |

### Phase 2: Extract Shared Constants / Theme / Widgets

| Item | Detail |
|------|--------|
| **Move/refactor** | `app_colors.dart`, `business_constants.dart` (rider statuses), shared `_resolveL10n` → extension on BuildContext, dedupe text fields |
| **Files affected** | delivery, trip, incoming, auth widgets, orders UI constants |
| **Must not break** | Visual appearance, primary color `#23C1B2` |
| **Test** | Smoke test all primary screens in EN + AR |
| **Benefit** | Less duplication; easier theming |

### Phase 3: Split Large Screens into Widgets

| Item | Detail |
|------|--------|
| **Move/refactor** | Extract map canvas, drawers, sheets from active_trip, incoming, map_status, delivery — **no logic changes first** |
| **Files affected** | 4 mega files → ~15–20 widget files |
| **Must not break** | Trip flow, offer accept, delivery photos, map markers |
| **Test** | Manual E2E: login → go online → accept offer → complete trip → delivery |
| **Benefit** | Readable files (<300 lines each) |

### Phase 4: Centralize API / Network Layer

| Item | Detail |
|------|--------|
| **Move/refactor** | Shared response unwrapping, error mapper, optional logging interceptor; split `orders_remote_data_source.dart` by endpoint group |
| **Files affected** | All `*_remote_data_source.dart`, `api_exception.dart` |
| **Must not break** | Token refresh, 401 logout, order/offer endpoints |
| **Test** | API integration tests against staging; login + fetch orders + heartbeat |
| **Benefit** | Consistent errors; easier endpoint changes |

### Phase 5: Create Repositories / Data Sources for Trip & Incoming

| Item | Detail |
|------|--------|
| **Move/refactor** | Move direct use case calls from UI into Cubits; optional `TripRepository` facade over order use cases |
| **Files affected** | `courier_map_status_screen`, `active_trip_page`, `incoming_order_page` |
| **Must not break** | Status transitions, current order refresh |
| **Test** | Full courier shift simulation |
| **Benefit** | Testable business logic |

### Phase 6: Clean State Management

| Item | Detail |
|------|--------|
| **Move/refactor** | Introduce MapStatusCubit, TripCubit; unify courier online flag; shrink setState usage |
| **Files affected** | map status, trip, incoming, orders pages |
| **Must not break** | Online/offline persistence, heartbeat lifecycle |
| **Test** | Toggle online/offline; kill app and resume |
| **Benefit** | Predictable state; easier debugging |

### Phase 7: Clean Routing / Navigation

| Item | Detail |
|------|--------|
| **Move/refactor** | `route_paths.dart`, typed extras, register DeliveryToCustomer route, remove duplicate `/orders` paths |
| **Files affected** | `app_router.dart`, all `context.go/push` call sites |
| **Must not break** | Onboarding redirects, deep links to active trip |
| **Test** | Navigation matrix (logged out/in, permissions pending, active trip) |
| **Benefit** | Type-safe navigation; fewer runtime casts |

### Phase 8: Localization Cleanup

| Item | Detail |
|------|--------|
| **Move/refactor** | Migrate `core_translations_data.dart` keys into ARB; remove GetX `.tr` usage; localize validators |
| **Files affected** | core/locale/*, stats, delivery, chat, validators |
| **Must not break** | Arabic RTL layouts on map/chat/orders |
| **Test** | Locale switch EN↔AR on every major screen |
| **Benefit** | Single i18n pipeline |

### Phase 9: Final Quality Pass

| Item | Detail |
|------|--------|
| **Move/refactor** | Delete legacy onboarding/auth duplicates, mock repositories, commented files; fix folder typos; add tests |
| **Files affected** | onboarding/* duplicates, permission/, mock_*, commented login files |
| **Must not break** | Signup and document upload production path |
| **Test** | Regression suite + widget tests for critical Cubits |
| **Benefit** | Production-ready maintainable codebase |

---

## 13. Risk Assessment

| Risk | Severity | Description |
|------|----------|-------------|
| **Breaking navigation** | High | `OnboardingState` redirect logic is complex; route path changes affect all flows |
| **Breaking API integration** | High | OrderMock ↔ MobileOrder mappers are fragile; checklist URL version mismatch |
| **Losing session/token behavior** | High | AuthTokenInterceptor + SecureStorage + SharedPreferences must stay in sync on logout |
| **Breaking order/invoice flow** | High | Active trip status integers and pickup/delivery branching are embedded in UI |
| **Breaking localization** | Medium | Removing GetX translations before ARB migration may missing strings |
| **Breaking permissions/onboarding** | Medium | Two permission pages; conflating them may break first-run UX |
| **Breaking platform-specific behavior** | Medium | Location, camera, notifications, Firebase push, Google Maps markers |
| **Regression in heartbeat/online** | High | HeartbeatCubit tied to logout and online keys — changes need careful testing |
| **Map/GPS regressions** | Medium | Large map code with custom label positioning and polylines |
| **Minimal automated test coverage** | High | Only default `test/widget_test.dart` — refactors rely on manual QA |

---

## 14. Final Deliverables

### 14.1 Current Problems Summary

1. **Mega-files** (2,000+ lines) in trip, delivery, incoming, map status
2. **Inconsistent architecture** — clean layers in auth/orders, monoliths in operations
3. **Dual/triple localization** systems
4. **Legacy duplicates** — onboarding vs auth, permission pages, mock order pipeline
5. **Legacy folder** `lib/screens/` outside features
6. **Typed routing gaps** — raw maps and `OrderMock` as nav args
7. **Shared constants/state duplicated** — online flag, courier type, rider statuses
8. **Minimal tests** and large DI file
9. **Naming typos** in paths/files
10. **GetMaterialApp + go_router + GetX translations** — unnecessary framework overlap

### 14.2 Recommended Architecture Summary

Adopt **feature-first Clean Architecture** consistently: presentation → domain → data, with shared `core/` for network, session, theme, and truly generic widgets. Consolidate operational flows under dedicated features (`map_status`, `trip`, `incoming`, `delivery`) each with Cubits owning business logic. Use **ARB-only localization** and **typed go_router** navigation.

### 14.3 Top 10 Files to Refactor First

| Priority | File | Reason |
|----------|------|--------|
| 1 | `active_trip_page.dart` | Largest file; core business flow |
| 2 | `delivery_to_customer_page.dart` | Delivery completion; not routed |
| 3 | `courier_map_status_screen.dart` | App hub; wrong location; direct API |
| 4 | `incoming_order_page.dart` | Offer acceptance flow |
| 5 | `incoming_order_cubit.dart` | Central offer logic — oversized |
| 6 | `orders_remote_data_source.dart` | All order APIs in one class |
| 7 | `app_router.dart` | Navigation + auth guard complexity |
| 8 | `core_translations_data.dart` | Duplicate i18n maintenance burden |
| 9 | `sign_up_phone_number_cubit.dart` | Auth registration orchestration too large |
| 10 | `mobile_order_to_order_mock_mapper.dart` | Critical mapping layer to replace |

### 14.4 Top 10 Quick Wins

1. **Delete commented-out** `login_page.dart`, `login_screen.dart` after confirming unused
2. **Extract `app_colors.dart`** and replace hardcoded `#23C1B2`
3. **Create `route_paths.dart`** — single source for path strings
4. **Extract shared `l10n extension`** — remove 11 duplicate `_resolveL10n` functions
5. **Rename** `mock_order_card.dart` → `order_card_legacy.dart` or merge with `order_card.dart`
6. **Move** `courier_map_status_screen.dart` → `features/map_status/presentation/pages/`
7. **Move** `delivery_to_customer_page.dart` → `features/delivery/presentation/pages/`
8. **Centralize** `_kCourierOnlineKey` and `_fullTimeCourierTypeId` in constants
9. **Mark deprecated** `features/onboarding/sign_up_page.dart` and legacy `permission_page.dart`
10. **Split `dependency_injection.dart`** into per-feature modules (`injection_auth.dart`, etc.)

### 14.5 Full Proposed Folder Structure

See **Section 11.2** for the complete recommended tree. Highlights:

- Eliminate `lib/screens/`
- No page files directly under `features/<name>/`
- Every feature follows `data/ domain/ presentation/` where API exists
- Single `l10n/` ARB pipeline
- `core/network/` replaces `core/networking/` (optional rename during migration)

### 14.6 Safe Refactoring Roadmap

See **Section 12** for the 9-phase incremental plan. Recommended order:

**Document → Shared constants/widgets → Split UI → Network → Repositories → Cubits → Routing → i18n → Delete legacy**

Each phase is independently shippable with manual QA focused on:

1. Login/logout + token refresh  
2. Permissions + location setup  
3. Go online → receive offer → accept  
4. Active trip status transitions (pickup + delivery paths)  
5. Delivery with photos + checklist  
6. Orders list + filters  
7. EN/AR locale switching  

---

## Appendix A: Technology Dependencies (from `pubspec.yaml`)

| Category | Packages |
|----------|----------|
| Navigation | go_router |
| State | flutter_bloc, get, get_it |
| Network | dio, http, dartz |
| Storage | shared_preferences, flutter_secure_storage |
| Maps/Location | google_maps_flutter, flutter_map, geolocator, geocoding |
| Firebase | firebase_core, firebase_messaging, flutter_local_notifications |
| UI | flutter_screenutil, flutter_svg, intl_phone_number_input |
| Media | image_picker, audioplayers |

---

## Appendix B: Test Coverage Status

- **Unit tests:** Essentially none beyond template
- **Widget tests:** `test/widget_test.dart` only
- **Integration tests:** Not found

**Recommendation:** Before large refactors, add characterization tests for mappers (`MobileOrder` → UI models) and Cubits (login, incoming offer accept/reject, go online/offline).

---

*End of report. No application source files were modified during this audit.*
