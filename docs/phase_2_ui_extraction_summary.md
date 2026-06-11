# Phase 2 UI Extraction Summary & Review

**Branch (documentation):** `docs/phase-2-ui-extraction-summary`  
**Document date:** June 2026  
**Scope:** UI-only widget extraction from four mega-screens — no business logic changes.

---

## 1. Executive Summary

Phase 2 extracted **16 small, stateless UI widgets** from four large screen files in the Gassel Courier Flutter app. Each extraction was delivered as a separate, reversible PR that moved layout and styling into dedicated widget files while leaving all state, Cubits, API flows, navigation, timers, streams, and SharedPreferences behavior in the parent screen.

Phase 2 was intentionally limited to **UI-only extraction** because these screens are production-critical orchestration points: they combine map lifecycle, rider status integers, photo capture/upload, offer acceptance, heartbeat, and delivery completion in single `State` classes. Splitting business logic prematurely would have increased regression risk without reducing architectural debt in a controlled way.

**Confirmation:** No business logic, API/use-case calls, Cubit behavior, navigation paths, timer/stream subscriptions, or SharedPreferences reads/writes were intentionally changed during Phase 2. Extracted widgets receive data and callbacks from parents; they do not import Cubits, use cases, or route constants.

| Metric | Value |
|--------|-------|
| **Widgets extracted** | 16 |
| **Screens touched** | 4 |
| **Screens paused** | 4 (all touched screens) |
| **Approximate total line reduction (parent files)** | ~602 lines across four parents |

**Recommendation:** Pause broad Phase 2 UI-only extraction. Do not start Phase 3 implementation without approval. The team should review this summary, then produce a **Phase 3 Planning Report** focused on state ownership and `setState` reduction — not logic rewrites, file moves to final architecture, or foundation wiring (`RoutePaths`, `AppColors`, `BusinessConstants`).

---

## 2. Phase 2 Safety Rules Followed

The following rules were applied consistently across every Phase 2 PR:

- **Parent keeps state** — photo lists, loading flags, map positions, and local guards remain in `_…State`.
- **Parent keeps Cubits and BlocListeners** — `BlocConsumer`, `BlocListener`, and `BlocBuilder` wiring stay in the screen.
- **Parent keeps navigation callbacks** — `context.go`, `context.push`, `Navigator.push/pop`, and dialog orchestration stay in the screen.
- **Parent keeps API/use case calls** — all network access continues through Cubits or existing screen-level calls; extracted widgets never call APIs.
- **Parent keeps timers/streams** — countdown timers, heartbeat, fake-offer timers, and GPS streams were not moved.
- **Parent keeps SharedPreferences** — e.g. `courier_online` persistence on map-status screen unchanged.
- **Parent keeps map controller lifecycle** — `GoogleMapController` creation, disposal, and camera moves stay in parent.
- **Extracted widgets own only layout/styling** — `StatelessWidget` (or purely presentational builders) with constructor parameters.
- **Each PR was small and reversible** — typically one widget per branch; easy to revert independently.
- **Analyzer was run per PR** — `flutter pub get`, `dart format` (touched files only), `flutter analyze` (touched files).
- **Manual QA was defined per PR** — EN/AR layout, navigation regression, and core actions verified per screen.

**Explicitly not done in Phase 2:**

- Wiring `RoutePaths`, `BusinessConstants`, `AppColors`, or `l10n_context_extension`
- Fixing pre-existing analyzer warnings unrelated to extraction
- Deleting dead code (e.g. unused `_buildServiceChips` on incoming page)
- OrderMock / MobileOrder mapping changes
- Cubit extraction or use-case boundary changes

---

## 3. Per-Screen Summary

### 3.1 Delivery Page

**Screen:** `lib/features/delivery/delivery_to_customer_page.dart`

| | |
|--|--|
| **Before (approx.)** | ~1,715 lines |
| **Current (verified)** | **1,526 lines** |
| **Approximate reduction** | ~189 lines |

**Widgets extracted (Phase 2):**

| Widget | File |
|--------|------|
| `DeliveryStepHeader` | `lib/features/delivery/presentation/widgets/delivery_step_header.dart` |
| `DeliverySectionCard` | `lib/features/delivery/presentation/widgets/delivery_section_card.dart` |
| `DeliveryInfoRow` | `lib/features/delivery/presentation/widgets/delivery_info_row.dart` |
| `DeliveryChecklistAnswerChoice` | `lib/features/delivery/presentation/widgets/delivery_checklist_answer_choice.dart` |
| `DeliveryChecklistQuestionCard` | `lib/features/delivery/presentation/widgets/delivery_checklist_question_card.dart` |
| `DeliveryChecklistErrorBanner` | `lib/features/delivery/presentation/widgets/delivery_checklist_error_banner.dart` |
| `DeliveryChecklistSuccessBanner` | `lib/features/delivery/presentation/widgets/delivery_checklist_success_banner.dart` |

**What remains in parent:**

- Photo lists (`_buildingPhotos`, `_orderPhotos`) and `ImagePicker`
- `DeliveryCompletionCubit` and `AttemptedDeliveryChecklistCubit` (create/close/listen)
- Photo capture and remove logic
- Delivery submit and attempted-delivery submit flows
- Checklist load/submit orchestration (`_showCantReachDialog`, etc.)
- Dialogs (`_showSelectedPhotos`, `_showImageViewer`)
- Navigation to map-status (`context.go('/map-status')`) and customer chat
- Validation (`_canDeliver`, proof-required rules)
- Pickup vs delivery branching

**Why paused:**

Remaining sections mix UI with photo state, Cubit flow, validation, and navigation. Step builders (`_buildStep1`–`_buildStep3`), photo slider, bottom bar, and dialog orchestration cannot be split safely without moving state or callbacks in ways that violate Phase 2 boundaries.

**Safe optional future UI extraction:**

- `DeliveryClothesRelationshipCard` from `_buildClothesCard` (~60 lines, zero callbacks, display-only from `widget.customerHasHanger`)

**Do not extract yet:**

- `_buildPhotoSlider` — photo state + remove + viewer callbacks
- `_buildBottomBar` — `_canDeliver`, `_onDeliveredTap`, submitting state
- `_buildStep1` / `_buildStep2` / `_buildStep3` — Cubit, capture, validation
- `_showCantReachDialog` — full checklist orchestration
- `_showSelectedPhotos` / `_showImageViewer` — modal navigation

---

### 3.2 Map Status Screen

**Screen:** `lib/screens/courier_map_status_screen.dart`

| | |
|--|--|
| **Before (approx.)** | ~1,348 lines |
| **Current (verified)** | **1,214 lines** |
| **Approximate reduction** | ~134 lines |

**Widgets extracted (Phase 2):**

| Widget | File |
|--------|------|
| `CourierMapDrawerStatsRow` | `lib/screens/widgets/courier_map_drawer_stats_row.dart` |
| `CourierMapDrawerTile` | `lib/screens/widgets/courier_map_drawer_tile.dart` |
| `CourierMapSearchingIndicator` | `lib/screens/widgets/courier_map_searching_indicator.dart` |
| `CourierMapDrawerNotificationButton` | `lib/screens/widgets/courier_map_drawer_notification_button.dart` |

**What remains in parent:**

- `GoOnlineCubit` / `GoOfflineCubit` / `HeartbeatCubit` listeners
- `GoogleMap` and map styling
- Geolocator location logic
- Fake offer banner timers
- `GetCurrentOfferUseCase` / `GetCurrentOrderUseCase`
- SharedPreferences `courier_online`
- Post-go-online navigation
- Drawer header and online switch
- Logout flow

**Why paused:**

Remaining sections are connected to availability state, heartbeat, timers, offer routing, and map lifecycle. Extracting them as “UI only” would either be cosmetic (tiny gain) or require moving sensitive callbacks.

**Safe optional future UI extraction:**

- Hamburger menu button (pure tap → callback, if bounded with explicit `onPressed`)

**Do not extract yet:**

- Fake offer banner — timers + use case + navigation
- Go To Online button — Cubit + SharedPreferences
- My Location FAB — map controller + Geolocator
- Drawer header / online switch — availability Cubits
- `GoogleMap` block — controller lifecycle

---

### 3.3 Incoming Order Page

**Screen:** `lib/features/incoming/presentation/pages/incoming_order_page.dart`

| | |
|--|--|
| **Before (approx.)** | ~1,649 lines |
| **Current (verified)** | **1,451 lines** |
| **Approximate reduction** | ~198 lines |

**Widgets extracted (Phase 2):**

| Widget | File |
|--------|------|
| `IncomingStopConnector` | `lib/features/incoming/presentation/widgets/incoming_stop_connector.dart` |
| `IncomingInfoField` | `lib/features/incoming/presentation/widgets/incoming_info_field.dart` |
| `OrderHeaderLabelRow` | `lib/features/incoming/presentation/widgets/incoming_order_header_label_row.dart` |

**Existing widgets already used before this round:**

| Widget | Location |
|--------|----------|
| `AcceptCountdownTimer` | `lib/features/incoming/presentation/widgets/accept_countdown_timer.dart` |
| `EarningsCard` | `lib/features/incoming/presentation/widgets/earnings_card.dart` |
| `IncomingMapControls` | `lib/features/incoming/presentation/widgets/incoming_map_controls.dart` |
| `LabeledMarkerWidget` | `lib/features/incoming/presentation/widgets/labeled_marker_widget.dart` |
| `OrdersDrawer` | `lib/features/orders/presentation/widgets/orders_drawer.dart` |

**What remains in parent:**

- `IncomingOrderCubit` / `BlocConsumer`
- Countdown timer lifecycle
- Accept/reject handlers and timeout behavior
- Map controller and label overlay math
- OrderMock / offer mapping
- Drawer callbacks

**Why paused:**

Remaining sections touch accept/reject/countdown/map or are not very small. `_StopCard`, reject dialog, and map block need dedicated mini-plans.

**Safe optional future UI extraction:**

- `_StopCard` — after a dedicated mini-plan (display strings + callbacks, no Cubit import)

**Do not extract yet:**

- Accept/reject row — Cubit + API + timeout
- Reject dialog — Cubit side effects
- `_IncomingOrderMap` — controller + overlays
- Empty state with navigation
- Countdown lifecycle

**Note:** `_buildServiceChips` exists in parent (~line 989) and appears unused — deferred to separate cleanup PR, not Phase 2.

---

### 3.4 Active Trip Page

**Screen:** `lib/features/trip/presentation/pages/active_trip_page.dart`

| | |
|--|--|
| **Before (approx.)** | ~2,221 lines |
| **Current (verified)** | **2,140 lines** |
| **Approximate reduction** | ~81 lines |

**Widgets extracted (Phase 2):**

| Widget | File |
|--------|------|
| `ActiveTripMapControlButton` | `lib/features/trip/presentation/widgets/active_trip_map_control_button.dart` |
| `ActiveTripCompactActionButton` | `lib/features/trip/presentation/widgets/active_trip_compact_action_button.dart` |

**Existing widgets already used before this round:**

| Widget | Location |
|--------|----------|
| `ComplaintDrawerContent` | trip feature widgets |
| `ActiveOrderDetailsSheet` | trip feature widgets |
| `LabeledMarkerWidget` | incoming feature widgets (shared) |

**What remains in parent:**

- Live GPS stream
- `GoogleMapController`
- Route polyline and map labels
- `GetCurrentOrderUseCase` / `UpdateRiderStatusUseCase`
- `PickupStatusCubit`
- Rider/pickup status integers and progression handlers
- `DeliveryToCustomerPage` navigation
- Order details / chat / call / directions handlers

**Why paused:**

Remaining sections are tied to the status machine, GPS, map, or delivery transition. The primary CTA alone encodes multi-step rider status logic.

**Safe optional future UI extraction:**

- `ActiveTripOrderTypeChip` — small display chip if inputs are plain strings/colors

**Do not extract yet:**

- Primary status button — status machine + use cases
- `GoogleMap` block — controller lifecycle
- Next destination pill — without separate mini-plan (Positioned + status-derived text)
- Order header as one large block
- Customer notes cards — without dedicated plan

---

## 4. Extracted Widgets Index

| Screen | Widget class | File path | Extracted from | Risk level | Notes |
|--------|--------------|-----------|----------------|------------|-------|
| Delivery | `DeliveryStepHeader` | `lib/features/delivery/presentation/widgets/delivery_step_header.dart` | Step headers in `_buildStep*` | Low | Number + title display |
| Delivery | `DeliverySectionCard` | `lib/features/delivery/presentation/widgets/delivery_section_card.dart` | Repeated card wrapper | Low | Shared section container |
| Delivery | `DeliveryInfoRow` | `lib/features/delivery/presentation/widgets/delivery_info_row.dart` | `_buildBuildingCard` rows | Low | Label + value row |
| Delivery | `DeliveryChecklistAnswerChoice` | `lib/features/delivery/presentation/widgets/delivery_checklist_answer_choice.dart` | Checklist dialog | Low | Yes/No choice chip |
| Delivery | `DeliveryChecklistQuestionCard` | `lib/features/delivery/presentation/widgets/delivery_checklist_question_card.dart` | Checklist dialog | Low | Question + choices; callbacks from parent |
| Delivery | `DeliveryChecklistErrorBanner` | `lib/features/delivery/presentation/widgets/delivery_checklist_error_banner.dart` | Checklist dialog | Low | Error message display |
| Delivery | `DeliveryChecklistSuccessBanner` | `lib/features/delivery/presentation/widgets/delivery_checklist_success_banner.dart` | Checklist dialog | Low | Success message display |
| Map status | `CourierMapDrawerStatsRow` | `lib/screens/widgets/courier_map_drawer_stats_row.dart` | Drawer stats section | Low | Stats display row |
| Map status | `CourierMapDrawerTile` | `lib/screens/widgets/courier_map_drawer_tile.dart` | Drawer menu tiles | Low | Icon + label tile |
| Map status | `CourierMapSearchingIndicator` | `lib/screens/widgets/courier_map_searching_indicator.dart` | Searching UI | Low | Animated/searching indicator |
| Map status | `CourierMapDrawerNotificationButton` | `lib/screens/widgets/courier_map_drawer_notification_button.dart` | Drawer notification | Low | Badge/button display |
| Incoming | `IncomingStopConnector` | `lib/features/incoming/presentation/widgets/incoming_stop_connector.dart` | Stop list UI | Low | Vertical connector line |
| Incoming | `IncomingInfoField` | `lib/features/incoming/presentation/widgets/incoming_info_field.dart` | Order info fields | Low | Label + value field |
| Incoming | `OrderHeaderLabelRow` | `lib/features/incoming/presentation/widgets/incoming_order_header_label_row.dart` | Order header | Low | Moved from private inline widget |
| Active trip | `ActiveTripMapControlButton` | `lib/features/trip/presentation/widgets/active_trip_map_control_button.dart` | Map overlay controls | Low | Icon button + callback |
| Active trip | `ActiveTripCompactActionButton` | `lib/features/trip/presentation/widgets/active_trip_compact_action_button.dart` | Compact actions | Low | Label + icon + callback |

**Total Phase 2 extractions:** 16 widgets across 4 screens.

---

## 5. Approximate Line Count Summary

Line counts verified from workspace files (June 2026).

| Screen | File path | Before | Current | Reduction | Notes |
|--------|-----------|--------|---------|-----------|-------|
| Delivery | `lib/features/delivery/delivery_to_customer_page.dart` | ~1,715 | **1,526** | ~189 | 7 widgets extracted; largest Phase 2 gain |
| Map status | `lib/screens/courier_map_status_screen.dart` | ~1,348 | **1,214** | ~134 | 4 drawer/search widgets |
| Incoming | `lib/features/incoming/presentation/pages/incoming_order_page.dart` | ~1,649 | **1,451** | ~198 | Includes header row file move |
| Active trip | `lib/features/trip/presentation/pages/active_trip_page.dart` | ~2,221 | **2,140** | ~81 | Smallest reduction; screen still largest |
| **Total (parents)** | — | ~6,933 | **6,331** | **~602** | New widget files add lines elsewhere |

**Interpretation:** Phase 2 reduced parent file size modestly (~9% combined). The primary value is **separation of reusable presentation pieces** and **establishing safe extraction boundaries**, not dramatically smaller screen files. All four parents remain mega-screens requiring Phase 3+ planning.

---

## 6. Patterns Established

### Folder conventions

- **Feature screens:** new UI widgets go under `lib/features/<feature>/presentation/widgets/`.
- **Legacy map screen:** Phase 2 used `lib/screens/widgets/` for `courier_map_status_screen.dart` only. This is a temporary exception until map-status is moved under a feature module.

### Naming

- Public widget classes use a **feature or screen prefix**: `Delivery*`, `CourierMap*`, `Incoming*`, `ActiveTrip*`.
- File names are `snake_case` matching the widget: `delivery_step_header.dart` → `DeliveryStepHeader`.

### Parent vs widget responsibilities

| Parent (screen State) | Widget (extracted) |
|-----------------------|-------------------|
| Owns `setState`, lists, flags | Receives immutable inputs |
| Provides Cubit via `BlocProvider` / listens | Does not import Cubits |
| Passes `VoidCallback` / typed callbacks | Invokes callbacks only |
| Calls use cases (via Cubits) | Does not import use cases |
| Performs navigation | Does not call `context.go` / `Navigator` |
| Owns timers, streams, map controllers | No timers, streams, or controllers |
| Reads/writes SharedPreferences | No SharedPreferences |
| Knows route paths and business rules | Receives display strings and enabled flags |

### PR discipline

- One widget (or one tightly related move) per branch.
- Format and analyze only touched files.
- Do not fix unrelated analyzer warnings in the same PR.

---

## 7. Validation Pattern Used

Each Phase 2 implementation PR followed:

```bash
flutter pub get
dart format <touched-dart-files>
flutter analyze <touched-dart-files-or-directory>
```

**Policy:**

- Pre-existing analyzer warnings were **not** fixed unless directly caused by the extraction.
- No repo-wide format or analyze runs required for Phase 2 scope.

**Manual QA checklist (per screen):**

| Check | Delivery | Map status | Incoming | Active trip |
|-------|----------|------------|----------|-------------|
| EN/AR layout | ✓ | ✓ | ✓ | ✓ |
| Main navigation unchanged | ✓ (map-status, chat) | ✓ (go online, offers) | ✓ (accept path) | ✓ (delivery page push) |
| Core actions unchanged | ✓ (deliver, photos) | ✓ (online/offline) | ✓ (accept/reject) | ✓ (status progression) |
| Map behavior unchanged | N/A | ✓ | ✓ | ✓ |
| Cubit/API flow unchanged | ✓ | ✓ | ✓ | ✓ |

---

## 8. Paused Areas — Do Not Touch Yet

| Screen | Section | Why risky | Earliest safe phase |
|--------|---------|-----------|---------------------|
| Delivery | `_buildPhotoSlider` | Photo list mutation, remove, viewer; tied to deliver validation | Phase 3/4 planning |
| Delivery | `_buildBottomBar` | Submit entry point, `_canDeliver`, Cubit submitting state | Phase 4 |
| Delivery | `_buildStep1`–`_buildStep3` | Cubit, capture, proof rules mixed in step builders | Phase 3 mini-plan per step |
| Delivery | `_showCantReachDialog` | Checklist load/submit orchestration | Phase 4 |
| Delivery | Photo bottom sheet / viewer | Modal navigation + file paths | Phase 3 (callback-only widget) |
| Map status | Fake offer banner | Timers + use case + navigation | Dedicated mini-plan |
| Map status | Go To Online button | Cubits + SharedPreferences | Phase 4 |
| Map status | My Location FAB | Map controller + Geolocator | Map refactor phase |
| Map status | Drawer header / online switch | Availability Cubits | Phase 4 |
| Map status | `GoogleMap` block | Controller lifecycle | Map refactor phase |
| Incoming | Accept/reject row | Cubit + API + countdown timeout | Phase 4 |
| Incoming | Reject dialog | Side effects on reject | Phase 4 |
| Incoming | `_IncomingOrderMap` | Controller + label overlay math | Map refactor phase |
| Incoming | Empty state + navigation | Route decisions | Phase 3 |
| Incoming | Countdown lifecycle | Timer + timeout handler | Phase 4 |
| Active trip | Primary status button | Status machine + use cases | Phase 4 |
| Active trip | `GoogleMap` block | GPS stream + controller | Map refactor phase |
| Active trip | Next destination pill | Status-derived positioning | Dedicated mini-plan |
| Active trip | Order header / notes blocks | Large mixed sections | Dedicated mini-plan |
| All | OrderMock / MobileOrder migration | Data layer, not UI | Separate larger phase |
| All | `RoutePaths` / `AppColors` wiring | Foundation adoption | Separate approved PR |

---

## 9. Recommended Next Direction

### Stop Phase 2 broad extraction

All four mega-screens are paused. Further blind UI splitting on step builders, map blocks, or primary CTAs will either yield tiny gains or blur the Phase 2 safety boundary.

### Do not start Phase 3 implementation immediately

Phase 3 requires explicit approval and a planning document before any code changes.

### Recommended next task: Phase 3 Planning Report

Create `docs/phase_3_planning_report.md` (or equivalent) covering:

1. **State ownership per screen** — what `_…State` owns today vs what Cubits already own.
2. **`setState` inventory** — count and categorize by screen (UI-only vs business).
3. **Cubit candidates** — which local state could move to existing or new Cubits without API changes.
4. **Risks** — regression hotspots (delivery photos, rider status ints, incoming timeout).
5. **Safest first Phase 3 candidate** — one screen + one bounded state concern.

### Phase 3 scope guardrails (when approved)

- Focus on **state ownership and `setState` reduction** only.
- No logic rewrites, no API contract changes.
- Do **not** move files to final clean-architecture folders yet.
- Do **not** wire `RoutePaths` / `AppColors` / `BusinessConstants` unless approved as a separate adoption PR.
- Do **not** remove legacy files yet.

### Optional before Phase 3 (micro-PRs only)

If the team wants a clean Phase 2 closure, at most **one optional micro-PR per paused screen**, UI-only, zero state movement:

| Screen | Candidate |
|--------|-----------|
| Delivery | `DeliveryClothesRelationshipCard` |
| Map status | Hamburger menu button |
| Incoming | `_StopCard` (after mini-plan) |
| Active trip | `ActiveTripOrderTypeChip` |

These are **optional**, not required to proceed to Phase 3 planning.

---

## 10. Open Questions / Decisions Needed

1. **`lib/screens/widgets/` vs feature folders:** Should map-status widgets stay in `lib/screens/widgets/` temporarily, or move when map-status becomes a feature module?
2. **Dead code cleanup:** Should unused `_buildServiceChips` on `incoming_order_page.dart` be removed in a separate cleanup PR (not Phase 2/3)?
3. **Phase 1 foundation wiring:** When should `RoutePaths`, `AppColors`, `BusinessConstants`, and `l10n_context_extension` be adopted — before or after Phase 3?
4. **Optional micro-PRs:** Should the team do one last UI-only extraction per paused screen, or go straight to Phase 3 planning?
5. **Phase 3 screen priority:** Which screen should be first — delivery (completion flow), incoming (accept timeout), active trip (status machine), or map-status (online/heartbeat)?
6. **Characterization tests:** Should lightweight widget/golden or integration tests be added before moving Cubit logic or splitting steps?
7. **OrderMock migration:** Defer to a separate data-layer phase, or schedule after Phase 3 state cleanup?

---

## 11. Appendix — Branch / PR Index

Phase 2 branches and widgets (one widget per branch unless noted).

| Branch | Screen | Widget(s) extracted |
|--------|--------|---------------------|
| `refactor/safe-phase-2-ui-delivery-step-header` | Delivery | `DeliveryStepHeader` |
| `refactor/safe-phase-2-ui-delivery-section-card` | Delivery | `DeliverySectionCard` |
| `refactor/safe-phase-2-ui-delivery-info-row` | Delivery | `DeliveryInfoRow` |
| `refactor/safe-phase-2-ui-delivery-checklist-answer-choice` | Delivery | `DeliveryChecklistAnswerChoice` |
| `refactor/safe-phase-2-ui-delivery-checklist-question-card` | Delivery | `DeliveryChecklistQuestionCard` |
| `refactor/safe-phase-2-ui-delivery-checklist-error-banner` | Delivery | `DeliveryChecklistErrorBanner` |
| `refactor/safe-phase-2-ui-delivery-checklist-success-banner` | Delivery | `DeliveryChecklistSuccessBanner` |
| `refactor/safe-phase-2-ui-courier-map-drawer-stats-row` | Map status | `CourierMapDrawerStatsRow` |
| `refactor/safe-phase-2-ui-courier-map-drawer-tile` | Map status | `CourierMapDrawerTile` |
| `refactor/safe-phase-2-ui-courier-map-searching-indicator` | Map status | `CourierMapSearchingIndicator` |
| `refactor/safe-phase-2-ui-courier-map-drawer-notification-button` | Map status | `CourierMapDrawerNotificationButton` |
| `refactor/safe-phase-2-ui-incoming-stop-connector` | Incoming | `IncomingStopConnector` |
| `refactor/safe-phase-2-ui-incoming-info-field` | Incoming | `IncomingInfoField` |
| `refactor/safe-phase-2-ui-incoming-order-header-label-row` | Incoming | `OrderHeaderLabelRow` |
| `refactor/safe-phase-2-ui-active-trip-map-control-button` | Active trip | `ActiveTripMapControlButton` |
| `refactor/safe-phase-2-ui-active-trip-compact-action-button` | Active trip | `ActiveTripCompactActionButton` |

**Documentation branch (this file):** `docs/phase-2-ui-extraction-summary`

---

## Related documents

- `docs/file_ownership_map.md` — screen ownership and risk areas (pre–Phase 2 line counts; update separately if needed)
- `docs/flutter_safe_refactoring_execution_plan.md` — overall refactoring phases
- `docs/flutter_codebase_audit_report.md` — initial audit findings

---

*End of Phase 2 UI Extraction Summary & Review.*
