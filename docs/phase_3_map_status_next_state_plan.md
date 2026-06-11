# Phase 3 Map Status Next State Plan

**Branch (documentation):** `docs/phase-3-map-status-next-state-plan`  
**Document date:** June 2026  
**Scope:** Planning only — remaining `setState` in `lib/screens/courier_map_status_screen.dart`

**Related documents:**

- [phase_3_map_status_milestone.md](./phase_3_map_status_milestone.md)
- [phase_3_next_target_after_incoming.md](./phase_3_next_target_after_incoming.md)
- [phase_3_incoming_next_state_plan.md](./phase_3_incoming_next_state_plan.md)
- [phase_3_planning_report.md](./phase_3_planning_report.md)

---

## 1. Executive Summary

### Current map-status state after Phase 3A / 3B

| Item | Status |
|------|--------|
| **GoOnlineCubit tests** | 6/6 passing (Phase 3A Part 1) |
| **GoOfflineCubit tests** | 7/7 passing (Phase 3A Part 1) |
| **HeartbeatCubit tests** | 15/15 passing (Phase 3A Part 2) |
| **Driver availability total** | **28/28 passing** |
| **Profile name display** | `_profileNameNotifier` + drawer `ValueListenableBuilder<String>` (Phase 3B) |
| **`setState` count** | **20** (down from 21) |
| **Cubit / API / navigation / timers / GPS / map / SharedPreferences** | Unchanged intentionally |

### Already moved (Phase 3B)

| Field | Replacement |
|-------|-------------|
| `_profileName` | `ValueNotifier<String> _profileNameNotifier` (default `'Courier'`) |

Drawer profile name `Text` rebuilds via `ValueListenableBuilder<String>` only. Main map body no longer rebuilds when the name loads.

### Still on `setState` (20 calls)

| Category | Calls |
|----------|-------|
| `_courierOnline` load / persist | 2 |
| `_cachedCourierTypeId` | 1 |
| `_locationLoading` | 8 |
| `_currentPosition` | 2 (one combined with `_locationLoading`) |
| `_fakeOfferBannerVisible` | 2 |
| `_courierMarkerIcon` | 1 |
| `_courierMarkerIconLoading` | 1 |
| `_offerLookupInFlight` | 2 |

**Note:** `_courierMarkerIconLoading = true` is assigned **without** `setState` in `_loadCourierMarkerIcon` (line ~193). Only the error path and icon success path use `setState` for marker state.

### Recommendation

**Continue map-status Phase 3 with exactly one more safe production PR:** move **`_courierMarkerIcon` / `_courierMarkerIconLoading`** to `ValueNotifier` (Map Status **Phase 3C**).

**Then pause map-status production refactoring.** All remaining **18** `setState` calls are GPS, location, banner timers, offer lookup, courier online persistence, or courier-type gating — none are safe for ad-hoc ValueNotifier extraction without integration tests and a dedicated plan.

**Do not** attempt `_locationLoading`, `_currentPosition`, `_fakeOfferBannerVisible`, `_offerLookupInFlight`, `_courierOnline`, or `_cachedCourierTypeId` in the next PR.

**Prerequisite:** Complete manual QA from [phase_3_map_status_milestone.md §7](./phase_3_map_status_milestone.md) before merging Phase 3C.

**After Phase 3C:** switch Phase 3 implementation target to **active-trip Cubit characterization tests** (test-only PR; `active_trip_page.dart` has **15** `setState`, **0** Phase 3 tests today).

---

## 2. Remaining setState Inventory

Verified against `courier_map_status_screen.dart` (June 2026). **20** `setState` occurrences.

| # | Location / method | State changed | Category | Risk | Notes |
|---|-------------------|---------------|----------|------|-------|
| 1 | `_loadCourierOnline()` (~L143) | `_courierOnline` | Courier online load | **Very high** | Reads `SharedPreferences` key `courier_online`; drives drawer switch initial value |
| 2 | `_loadCachedCourierTypeId()` (~L158) | `_cachedCourierTypeId` | Cached courier type | **High** | Immediately starts/stops fake offer banner loop via `_shouldShowFreelancerOfferPolling` (`courierTypeId == 1`) |
| 3 | `_persistCourierOnline()` (~L186) | `_courierOnline` | Courier online persist | **Very high** | Called from GoOnline success, GoOffline success, Heartbeat forced-offline listener; writes prefs then updates UI |
| 4 | `_loadCourierMarkerIcon()` success (~L200) | `_courierMarkerIcon` | Marker icon | **Low** | Async asset load; adds van marker to `GoogleMap.markers` |
| 5 | `_loadCourierMarkerIcon()` catch (~L202) | `_courierMarkerIconLoading = false` | Marker icon loading | **Low** | Error path only; loading set `true` without `setState` at ~L193 |
| 6 | `_initializeLocation()` start (~L229) | `_locationLoading = true` | Location loading | **High** | Called from `initState`; gates My Location button spinner |
| 7 | `_initializeLocation()` service disabled (~L234) | `_locationLoading = false` | Location loading | **High** | Shows SnackBar; map stays at fallback center |
| 8 | `_initializeLocation()` permission denied (~L254) | `_locationLoading = false` | Location loading | **High** | Shows SnackBar |
| 9 | `_initializeLocation()` permission granted (~L270) | `_locationLoading = false` | Location loading | **High** | Clears loading before `getCurrentPosition` completes |
| 10 | `_initializeLocation()` position success (~L278) | `_currentPosition` | Current GPS position | **High** | Triggers `_animateToCurrentLocation()` |
| 11 | `_initializeLocation()` catch (~L286) | `_locationLoading = false` | Location loading | **High** | Geolocator error path |
| 12 | `_moveToMyLocation()` start (~L294) | `_locationLoading = true` | Location loading | **High** | Guarded by `if (_locationLoading) return` |
| 13 | `_moveToMyLocation()` service disabled (~L299) | `_locationLoading = false` | Location loading | **High** | SnackBar |
| 14 | `_moveToMyLocation()` permission denied (~L316) | `_locationLoading = false` | Location loading | **High** | SnackBar |
| 15 | `_moveToMyLocation()` success (~L334) | `_currentPosition`, `_locationLoading = false` | Position + loading | **High** | Single `setState` updates both; calls `_animateToCurrentLocation()` |
| 16 | `_moveToMyLocation()` catch (~L342) | `_locationLoading = false` | Location loading | **High** | Error SnackBar |
| 17 | `_showFakeOfferBanner()` (~L544) | `_fakeOfferBannerVisible = true` | Fake offer banner | **Very high** | Called from periodic/hide timers; starts hide timer |
| 18 | `_dismissOfferBanner()` (~L561) | `_fakeOfferBannerVisible = false` | Fake offer banner | **Very high** | Timer callback + manual dismiss; unmounted path assigns without `setState` |
| 19 | `_handleFakeOfferBannerViewTap()` start (~L575) | `_offerLookupInFlight = true` | Offer lookup in-flight | **High** | Disables View/Close buttons; before `_getCurrentOfferUseCase()` |
| 20 | `_handleFakeOfferBannerViewTap()` end (~L578) | `_offerLookupInFlight = false` | Offer lookup in-flight | **High** | After API; may navigate to `/incoming-order` or open offer flow |

**Owner:** all 20 calls are in `_CourierMapStatusScreenState`.

**Load trigger for marker icon:** `build()` calls `_loadCourierMarkerIcon(context)` when `_courierMarkerIcon == null && !_courierMarkerIconLoading` (~L682–684). Marker `Set` is built synchronously in `build()` from `_courierMarkerIcon` and `_currentPosition`.

---

## 3. Candidate Analysis

### A. Courier marker icon state (`_courierMarkerIcon`, `_courierMarkerIconLoading`)

| Aspect | Detail |
|--------|--------|
| **setState involved** | **2** (icon success, loading false on error) |
| **Non-setState assignment** | `_courierMarkerIconLoading = true` before async load (~L193) |
| **Where used** | `build()` marker `Set` for `GoogleMap`; load kickoff in `build()` |
| **Map coupling** | Marker display only — does **not** move camera or touch `_mapController` |
| **ValueNotifier safe?** | **Yes** — display-only; mirrors incoming nested map icon pattern and delivery/incoming profile photo pattern |
| **QA needed** | Van marker appears on map after load; map without marker before load; no duplicate load; EN/AR map key unchanged |
| **Risks** | Must preserve `build()`-triggered load guard; dispose notifiers; wrap only marker-bearing subtree (e.g. `GoogleMap` or a small `ListenableBuilder` for `markers`); do not change asset path or `BitmapDescriptor.fromAssetImage` call |

| Verdict | |
|---------|---|
| **Safe now?** | **Yes** |
| **Recommended phase** | **Phase 3C** (next and last safe map-status production PR) |
| **Why** | Smallest reversible win; zero Cubit/API/navigation/timer/GPS/prefs coupling |

---

### B. `_locationLoading`

| Aspect | Detail |
|--------|--------|
| **setState involved** | **8** across `_initializeLocation` and `_moveToMyLocation` |
| **GPS / Geolocator coupling** | Direct — permission checks, service enabled, `getCurrentPosition`, SnackBars |
| **UI coupling** | My Location FAB spinner and `onTap: _locationLoading ? null : _moveToMyLocation` |
| **ValueNotifier worth it?** | **No** — 8 call sites, high regression surface, no test coverage for page-level GPS flow |
| **Risks** | Splitting loading from position updates could desync spinner vs map; init and retry paths must stay identical |

| Verdict | |
|---------|---|
| **Safe now?** | **No** |
| **Recommended phase** | **Later** — dedicated GPS/map Phase 3 sub-plan with widget or integration tests |
| **Why** | Highest `setState` density after marker icon; core map UX |

---

### C. `_currentPosition`

| Aspect | Detail |
|--------|--------|
| **setState involved** | **2** (init success ~L278; move success ~L334 combined with loading) |
| **Coupling** | Drives `initialTarget` / marker position, `onMapCreated` camera animation, `_animateToCurrentLocation()` |
| **ValueNotifier worth it?** | **No** — tightly coupled to `_locationLoading` and map controller |
| **Risks** | Camera animation timing; marker position vs `GoogleMap.initialCameraPosition`; fallback center `_mapCenterLat/Lng` |

| Verdict | |
|---------|---|
| **Safe now?** | **No** |
| **Recommended phase** | **Later** — only with `_locationLoading` in a coordinated GPS refactor |
| **Why** | Map camera + marker + GPS trinity |

---

### D. `_offerLookupInFlight`

| Aspect | Detail |
|--------|--------|
| **setState involved** | **2** (true before API, false after) |
| **Where used** | Fake offer banner View/Close buttons disabled state and inline spinner |
| **Coupling** | `_getCurrentOfferUseCase()`, `_openFreelancerOffer()`, navigation to `/incoming-order` |
| **ValueNotifier safe?** | **Maybe later** — mechanically similar to incoming `_isRejectSubmitting`, but no page-level tests for banner tap flow |
| **Risks** | Race with `_openingOfferFlow` guard; banner dismiss + navigation side effects |

| Verdict | |
|---------|---|
| **Safe now?** | **Later** |
| **Recommended phase** | **Phase 3E+** after banner/offer integration characterization |
| **Why** | API + navigation coupling; freelancer-only path |

---

### E. `_fakeOfferBannerVisible`

| Aspect | Detail |
|--------|--------|
| **setState involved** | **2** (show, dismiss) |
| **Timer coupling** | `_fakeOfferBannerTimer` (periodic), `_fakeOfferBannerHideTimer` (show/hide duration) |
| **Flow** | Freelancer only (`_cachedCourierTypeId == 1`); started from `_loadCachedCourierTypeId` and post-offer navigation |
| **ValueNotifier safe?** | **No** without timer test harness |
| **Risks** | Timer callbacks, mounted checks, interaction with `_stopFakeOfferBannerLoop` / `_dismissOfferBanner` |

| Verdict | |
|---------|---|
| **Safe now?** | **No** |
| **Recommended phase** | **Much later** — fake-offer integration tests first |
| **Why** | Timer-driven visibility; very high business impact for freelancer couriers |

---

### F. `_courierOnline`

| Aspect | Detail |
|--------|--------|
| **setState involved** | **2** (load from prefs, persist after Cubit/heartbeat events) |
| **Coupling** | `SharedPreferences`, drawer `Switch`, GoOnline/GoOffline Cubits, Heartbeat forced-offline, `_setCourierOnline` |
| **Incoming precedent** | Incoming page moved `_courierOnline` to `ValueNotifier` in Phase 3B — **different** page; map-status has heartbeat + prefs + post-go-online navigation |
| **Risks** | Switch out of sync with prefs; heartbeat stop/start; navigation after go-online |

| Verdict | |
|---------|---|
| **Safe now?** | **No** |
| **Recommended phase** | **Much later** — page-level integration tests for go-online/offline + heartbeat + drawer |
| **Why** | Very high risk; core availability state machine on this screen |

---

### G. `_cachedCourierTypeId`

| Aspect | Detail |
|--------|--------|
| **setState involved** | **1** |
| **Coupling** | Gates `_shouldShowFreelancerOfferPolling`; immediately starts/stops fake offer timers |
| **Side effects in same method** | `_startFakeOfferBannerLoop()` / `_stopFakeOfferBannerLoop()` / `_dismissOfferBanner()` |
| **Risks** | Moving to ValueNotifier without changing timer side effects is possible but **misleading** — the real complexity is timer start/stop, not the int field |

| Verdict | |
|---------|---|
| **Safe now?** | **No** |
| **Recommended phase** | **Later** — with fake offer banner plan, not standalone |
| **Why** | Single `setState` but controls freelancer offer polling lifecycle |

---

## 4. Risk Comparison Table

Conservative assessment. **Test coverage** = existing automated tests relevant to the candidate on map-status page.

| Candidate | setState removed | Risk | Business impact | Test coverage | Recommendation |
|-----------|------------------|------|-----------------|----------------|---------------|
| **A. Marker icon** | 2 → **18 remain** | **Low** | Low — cosmetic map marker | None (page-level); Cubits unrelated | **Do next (Phase 3C)** |
| **B. Location loading** | 8 | **High** | High — My Location UX | None | **Defer** |
| **C. Current position** | 2 | **High** | High — map center + marker | None | **Defer** |
| **D. Offer lookup in-flight** | 2 | **Med–High** | Med — freelancer banner actions | None | **Defer** |
| **E. Fake offer banner visible** | 2 | **Very high** | High — freelancer notifications | None | **Do not touch** |
| **F. Courier online** | 2 | **Very high** | Critical — availability | 28 Cubit tests; no page integration | **Do not touch** |
| **G. Cached courier type id** | 1 | **High** | High — gates offer polling | None | **Do not touch** |
| **Pause → active-trip tests** | 0 | **Low** | None (test-only) | 0 active-trip tests today | **Do after Phase 3C** |
| **Add map-status page tests first** | 0 | **Low** | None | Would help GPS/banner later | **Optional parallel track** |
| **No production changes** | 0 | **None** | None | — | **If manual QA not done yet** |

---

## 5. Recommended Next PR

**Chosen:** **Implement courier marker icon ValueNotifier** (Map Status Phase 3C).

| Criterion | Met? |
|-----------|------|
| Small | Yes — 1 file, ~2 `setState` removed, 20 → **18** |
| Reversible | Yes — revert single PR |
| No Cubit behavior changes | Yes |
| No API changes | Yes |
| No navigation changes | Yes |
| No timer behavior changes | Yes |
| No GPS/location behavior changes | Yes |
| No map controller movement | Yes |
| No SharedPreferences behavior changes | Yes |

**Not chosen (and why):**

| Alternative | Why not now |
|-------------|-------------|
| Pause → active-trip tests | Valid **immediately after** Phase 3C; marker icon is the last zero-risk production win on this screen |
| Add more tests first | Heartbeat/GoOnline/GoOffline already characterized; page-level tests are valuable but **not required** for marker icon |
| No production changes | Only if milestone manual QA (§7) has **not** been run yet |

**Stop line after Phase 3C:** Do not continue map-status production refactors until active-trip tests exist and a new planning pass approves GPS/banner/online targets.

---

## 6. Exact Prompt Draft for Next PR

### Phase 3C — Courier marker icon ValueNotifier

```
You are a Senior Flutter Developer working on a production courier Flutter app.

We completed Map Status Phase 3A (28 driver availability tests) and Phase 3B
(profile name ValueNotifier; setState 21 → 20).

Planning report: docs/phase_3_map_status_next_state_plan.md

Implement **Map Status Phase 3C only** — one small production refactor.

**Branch:** `refactor/phase-3-map-status-marker-icon-value-notifier`

**VERY IMPORTANT — DO NOT CHANGE:**

- GoOnlineCubit, GoOfflineCubit, HeartbeatCubit implementations or wiring
- APIs, use cases, repositories, DTOs
- Navigation, route paths, or `_handlePostGoOnlineNavigation` / offer routing
- Fake offer banner timers, visibility logic, or `_startFakeOfferBannerLoop` / `_stopFakeOfferBannerLoop`
- GPS / Geolocator / `_initializeLocation` / `_moveToMyLocation` / `_animateToCurrentLocation`
- GoogleMapController lifecycle or camera animation
- SharedPreferences `courier_online` read/write
- `_courierOnline`, `_cachedCourierTypeId`, `_locationLoading`, `_currentPosition`,
  `_fakeOfferBannerVisible`, `_offerLookupInFlight`
- delivery_to_customer_page.dart, incoming_order_page.dart, active_trip_page.dart
- Do NOT fix analyzer warnings (deprecated BitmapDescriptor, Geolocator settings)

**Goal:** Move courier map marker icon display state to ValueNotifier.

**File:** `lib/screens/courier_map_status_screen.dart` only

**Scope:**

1. Replace `BitmapDescriptor? _courierMarkerIcon` with
   `ValueNotifier<BitmapDescriptor?> _courierMarkerIconNotifier` (initial null).
2. Replace `bool _courierMarkerIconLoading` with
   `ValueNotifier<bool> _courierMarkerIconLoadingNotifier` (initial false).
3. Update `_loadCourierMarkerIcon`:
   - Set loading notifier to true (instead of direct field assign)
   - On success: assign icon to icon notifier (no setState)
   - On error: set loading notifier to false (no setState)
   - Preserve existing guard: skip if icon non-null or loading true
4. Dispose both notifiers in `dispose()`.
5. Remove the 2 marker-related setState calls (~L200, ~L202).
6. Rebuild marker display only:
   - Use `ValueListenableBuilder` / `ListenableBuilder` (or combine both notifiers)
     so `GoogleMap.markers` updates when icon loads
   - Preserve `build()` kickoff: call `_loadCourierMarkerIcon` when icon null and not loading
   - Do NOT wrap unrelated drawer/banner/location widgets

**Expected setState count:** 20 → 18

**Validation:**

```bash
flutter pub get
dart format lib/screens/courier_map_status_screen.dart
flutter analyze lib/screens/courier_map_status_screen.dart
flutter test test/features/driver_availability/
flutter test test/features/incoming/
flutter test test/features/delivery/
```

**Manual QA:**

- [ ] Login → map-status screen
- [ ] Van marker appears on map (may brief delay on first load)
- [ ] Map center / My Location unchanged
- [ ] Drawer, online switch, Go Online/Offline unchanged
- [ ] Fake offer banner unchanged (freelancer account)
- [ ] EN/AR layout unchanged

**Rollback:** Revert branch; setState returns to 20; no data migration.

**Final response:** setState before/after, files changed, confirmation no forbidden areas touched,
recommended next step (pause map-status production; start active-trip Cubit tests).
```

---

### If pausing instead (after Phase 3C or if QA blocks 3C)

Use this prompt for the **next** work item — active-trip tests:

```
You are a Senior Flutter Architect working on a production courier Flutter app.

Map Status Phase 3C (marker icon) is complete OR map-status production is paused.

Implement **Active Trip Phase 3A only** — test-only PR.

**Branch:** `test/phase-3-active-trip-cubit-characterization`

**DO NOT modify any file under lib/.**

**Inspect:** active_trip_page.dart and its Cubit(s) / use cases.

**Goal:** Characterization unit tests for current Cubit behavior (mirror delivery/incoming/map-status 3A pattern).

**Validation:**
flutter test test/features/trip/
flutter test test/features/driver_availability/
flutter test test/features/incoming/
flutter test test/features/delivery/
```

---

## 7. Open Questions

| Question | Guidance |
|----------|----------|
| Should marker icon ValueNotifier be done before moving to active trip? | **Yes** — it is the only remaining low-risk map-status production change (2 `setState`). Active-trip tests can start immediately after Phase 3C merges. |
| Should fake offer banner state ever move without integration tests? | **No** — timer callbacks + freelancer flow + navigation side effects require characterization or integration tests first. |
| Should location loading remain `setState` until a GPS/map phase? | **Yes** — treat `_locationLoading` + `_currentPosition` as one deferred GPS/map bundle (10 `setState` combined). |
| Should `_courierOnline` move only after heartbeat/page integration tests? | **Yes** — Cubit unit tests (28) do not cover drawer switch sync, prefs persistence timing, or post-go-online navigation on the page. |
| Should the direct `fake_async` import warning be fixed in a separate test-infra PR? | **Optional yes** — add `fake_async` to `dev_dependencies` in a tiny test-only PR; not blocking Phase 3C. Do not bundle with production refactors. |
| After Phase 3C, continue map-status or switch target? | **Switch target** — 18 high-risk `setState` remain; next implementation track should be **active-trip Phase 3A tests**, not more map-status production edits. |
| Has milestone manual QA (§7) been completed? | **Track explicitly** — Phase 3C should not merge until QA checklist passes or is waived by team. |

---

## Appendix — setState Distribution Summary

```
Total: 20
├── Marker icon (LOW)           2  ← Phase 3C target
├── Offer lookup in-flight      2  ← defer
├── Fake offer banner           2  ← do not touch
├── Courier online              2  ← do not touch
├── Cached courier type         1  ← do not touch
├── Current position            2  ← defer (GPS phase)
└── Location loading            8  ← defer (GPS phase)
                                --
After Phase 3C:                18
```

---

*End of Phase 3 Map Status Next State Plan. No Dart production files were modified to produce this document.*
