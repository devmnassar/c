# Phase 3 Delivery Milestone — setState Removed Safely

**Branch (documentation):** `docs/phase-3-delivery-milestone`  
**Document date:** June 2026  
**Scope:** Delivery page state ownership only — `lib/features/delivery/delivery_to_customer_page.dart`

**Related documents:**

- [phase_3_planning_report.md](./phase_3_planning_report.md)
- [phase_2_ui_extraction_summary.md](./phase_2_ui_extraction_summary.md)

---

## 1. Executive Summary

Phase 3 on the delivery page was executed in three small, reversible steps:

| Step | Focus |
|------|--------|
| **Phase 3A** | Added **delivery Cubit characterization tests** (21 tests) to lock current behavior before state refactors. |
| **Phase 3B** | Moved **`_buildingPhotos` / `_orderPhotos`** to `ValueNotifier<List<XFile>>` and removed photo-related `setState`. |
| **Phase 3C** | Moved **`_isPickupSubmitting`** to `ValueNotifier<bool>` and removed the last `setState` calls. |

**Result:** `delivery_to_customer_page.dart` now has **0 `setState` calls**.

**Confirmation:** No Cubit implementation, API, navigation, route path, validation rule, photo capture/upload sequence, checklist load/submit flow, or delivery/attempted-delivery submit logic was **intentionally changed** during Phase 3A–3C.

This milestone is **limited to delivery page local state ownership** — not Cubit extraction, not file moves, not changes to map-status, incoming-order, or active-trip screens.

---

## 2. Changes Completed

| Phase | Branch | Change | Production behavior impact |
| ----- | ------ | ------ | -------------------------- |
| **3A** | `test/phase-3-delivery-cubit-characterization` | Added unit tests for `DeliveryCompletionCubit` and `AttemptedDeliveryChecklistCubit` under `test/features/delivery/presentation/cubit/`. Added dev deps: `bloc_test`, `mocktail`. | **None** — test-only PR |
| **3B** | `refactor/phase-3-delivery-photo-value-notifier` | Photo lists → `_buildingPhotosNotifier` / `_orderPhotosNotifier`; `ValueListenableBuilder` on step 2, step 3, and bottom bar (photos); 2 `setState` removed | **None intentional** — same capture/remove, `_canDeliver`, submit proof path (`_buildingPhotos.last.path`) |
| **3C** | `refactor/phase-3-delivery-pickup-submitting-value-notifier` | Pickup flag → `_isPickupSubmittingNotifier`; nested `ValueListenableBuilder` on bottom bar; 2 `setState` removed | **None intentional** — same pickup `onPickupConfirm` try/finally, same derived `_isAnySubmitting` |

**Current file size (approx.):** ~1,568 lines (`delivery_to_customer_page.dart`, verified June 2026).

---

## 3. Current Delivery Page State Ownership

### Photo state (local — ValueNotifier)

| Field | Type | UI rebuild |
|-------|------|------------|
| `_buildingPhotosNotifier` | `ValueNotifier<List<XFile>>` | `_buildStep2`, bottom bar (via nested builder) |
| `_orderPhotosNotifier` | `ValueNotifier<List<XFile>>` | `_buildStep3` |

**Private getters** (readability, minimal call-site churn):

- `List<XFile> get _buildingPhotos => _buildingPhotosNotifier.value`
- `List<XFile> get _orderPhotos => _orderPhotosNotifier.value`

**Parent still owns:** `ImagePicker`, `_capturePhoto`, `_removePhoto`, max photo count, file validation before Cubit upload.

### Pickup submitting state (local — ValueNotifier)

| Field | Type | UI rebuild |
|-------|------|------------|
| `_isPickupSubmittingNotifier` | `ValueNotifier<bool>` | Bottom bar (nested builder) |

**Private getter:**

- `bool get _isPickupSubmitting => _isPickupSubmittingNotifier.value`

**Derived getters (unchanged logic):**

- `_isAnySubmitting` → Cubit `isSubmitting` **or** `_isPickupSubmitting`
- `_isDelivering` → Cubit `isDelivering` **or** `_isPickupSubmitting` *(getter currently **unused** after 3C — see §7)*

### Cubit state (unchanged ownership)

| Cubit | Role |
|-------|------|
| `DeliveryCompletionCubit` | Deliver + attempt delivery (upload + rider status) |
| `AttemptedDeliveryChecklistCubit` | Load/submit checklist; question answers in Cubit state |

Page still creates, closes, and listens via `BlocConsumer` / dialog `BlocBuilder` — **not moved**.

### Parent still owns (not extracted)

- `ImagePicker` instance
- Photo capture and remove handlers
- Validation getters (`_canDeliver`, `_isProofPhotoRequired`)
- Submit handlers (`_onDeliveredTap`, `_onAttemptedDeliveryTap`, pickup callback path)
- Checklist dialog orchestration (`_showCantReachDialog`, `_submitChecklistAnswers`)
- Navigation (`context.go('/map-status')`, chat push, dialog pop)
- Widget constructor props (customer, building, hanger, etc.)

---

## 4. setState Status

| Milestone | `setState` count in `delivery_to_customer_page.dart` |
|-----------|------------------------------------------------------|
| Before Phase 3B | **4** |
| After Phase 3B | **2** |
| After Phase 3C | **0** |
| **Current (verified)** | **0** |

### What was removed

| Removed `setState` | Replaced with |
|--------------------|---------------|
| Photo add (`_capturePhoto`) | `_buildingPhotosNotifier.value = [...]` or `_orderPhotosNotifier.value = [...]` |
| Photo remove (`_removePhoto`) | New list copy assigned to notifier |
| Pickup submitting `true` | `_isPickupSubmittingNotifier.value = true` |
| Pickup submitting `false` (in `finally`) | `_isPickupSubmittingNotifier.value = false` |

### What still triggers rebuilds

- **Photos / pickup flag:** `ValueListenableBuilder` on affected UI sections
- **Delivery completion / checklist:** `BlocConsumer` / `BlocBuilder` on Cubits (unchanged)

---

## 5. Tests and Validation

### Automated

| Command | Result |
|---------|--------|
| `flutter test test/features/delivery/presentation/cubit/` | **21/21 passing** |
| `flutter test test/features/delivery/` | **21/21 passing** |
| `flutter analyze lib/features/delivery/delivery_to_customer_page.dart` | Pre-existing issues remain; **`_isDelivering` unused** after Phase 3C |

### Analyzer notes (intentionally not fixed in Phase 3)

- Unused `_isAttemptingDelivery` (pre-existing)
- Unused `_isDelivering` (new after Phase 3C — bottom bar computes `isSubmitting` inline)
- `use_build_context_synchronously` infos (pre-existing)
- **`_isDelivering` cleanup deferred** to optional separate cleanup PR (see §9)

### Phase 3 validation pattern (per PR)

```bash
flutter pub get
dart format lib/features/delivery/delivery_to_customer_page.dart   # or test/ only for 3A
flutter analyze lib/features/delivery/delivery_to_customer_page.dart
flutter test test/features/delivery/presentation/cubit/
flutter test test/features/delivery/
```

**Full suite:** `flutter test` may still fail on pre-existing `test/widget_test.dart` (App/DI setup) — not in Phase 3 scope.

---

## 6. Manual QA Checklist

Run on device/emulator before treating this milestone as production-ready:

- [ ] Add building photo(s) — preview and count update
- [ ] Remove building photo — preview disappears
- [ ] Add/remove optional order photo(s)
- [ ] Tap photo thumbnail — fullscreen viewer opens and closes
- [ ] Deliver button **disabled** when proof required and no building photo
- [ ] Deliver button **enabled** when `_canDeliver` conditions met
- [ ] Proof-photo-required behavior unchanged (delivery and pickup variants)
- [ ] Normal delivery flow completes (Cubit upload + map-status navigation)
- [ ] **Pickup confirmation** — loading spinner on button during `onPickupConfirm`
- [ ] Attempted delivery / checklist dialog (load, answer, submit, attempt delivery)
- [ ] Navigation back to map-status unchanged
- [ ] EN/AR layout unchanged on delivery steps and dialogs

---

## 7. Known Notes / Risks

| Note | Detail |
|------|--------|
| Nested `ValueListenableBuilder`s | Bottom bar listens to building photos **and** pickup submitting. Acceptable for this small, isolated screen state. |
| `_isDelivering` unused | After Phase 3C, bottom bar computes `isSubmitting` locally. Getter remains in file; **remove only in separate cleanup PR**. |
| Proof photo path | Submit still uses **`_buildingPhotos.last.path`** (last captured building photo) — preserved from pre–Phase 3 behavior. |
| Cubit flows | Deliver, attempt delivery, and checklist load/submit **not modified** in Phase 3B/3C. |
| No widget extraction | Phase 2 UI widgets unchanged; Phase 3 did not extract new widgets. |
| Other mega-screens | map-status, incoming-order, active-trip **not touched** — still have local `setState` per Phase 3 planning report. |

---

## 8. Recommended Next Step

1. **Stop production refactoring temporarily** — delivery Phase 3 milestone is complete.
2. **Run manual QA** on the delivery page (§6).
3. **Optional:** Tiny cleanup PR for unused `_isDelivering` getter **only if QA passes** (§9).
4. **After cleanup (or if skipped):** Create a **planning pass** for the next Phase 3 target screen (do not implement until approved).
5. **Do not** touch map-status / incoming / active-trip state until a dedicated Phase 3 planning pass is reviewed and approved.

**Do not start:**

- Cubit rewrites on delivery page
- Map/GPS lifecycle extraction
- OrderMock migration
- RoutePaths / AppColors wiring

---

## 9. Suggested Next PR — Optional Cleanup

### Branch

`cleanup/delivery-remove-unused-is-delivering-getter`

### Scope

- Remove unused `_isDelivering` getter **only** if analyzer confirms it is unused and no references remain.
- **Do not** change `_isAnySubmitting`.
- **Do not** change bottom bar logic (keep inline `isSubmitting` computation).
- **Do not** change Cubits, API, navigation, validation, photo notifiers, or checklist logic.

### Validation

```bash
flutter pub get
dart format lib/features/delivery/delivery_to_customer_page.dart
flutter analyze lib/features/delivery/delivery_to_customer_page.dart
flutter test test/features/delivery/
```

### Rollback

Single-line getter removal — trivial revert.

---

## Appendix — Phase 3 Delivery Branch Index

| Branch | Type |
|--------|------|
| `test/phase-3-delivery-cubit-characterization` | Tests |
| `refactor/phase-3-delivery-photo-value-notifier` | Production (3B) |
| `refactor/phase-3-delivery-pickup-submitting-value-notifier` | Production (3C) |
| `docs/phase-3-delivery-milestone` | Documentation (this file) |

---

*End of Phase 3 Delivery Milestone summary. No Dart production files were modified to produce this document.*
