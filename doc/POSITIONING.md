# Positioning: j_navigation in the Flutter navigation landscape

*Candid comparison, mid-2026. Numbers verified against pub.dev and GitHub
primary sources on 2026-07-20. Honest about where j_navigation is strong and
where it is not yet — so adopters can judge fit without marketing.*

## The field

| Package | Version | Published | 30-day downloads | Likes | Maintainer | Status |
|---|---|---|---|---|---|---|
| **go_router** | 17.3.0 | ~2026-06-02 | ~3.5M | 5.75k | Flutter team (first-party, `flutter/packages`) | Active, **maintenance mode** (bug fixes, stability) |
| **auto_route** | 11.1.0 | ~2025-12 | (lower) | — | Community (Milad Firoozian) | Active, past v8/9/10/11. Codegen-required. |
| **Flutter Router (Navigator 2.0)** | built-in | — | — | — | Flutter team | Deep-link native; verbose; **no restoration**. |
| `nested_navigation` / `flex_router` | — | — | — | — | — | Do not exist as pub.dev packages. The field is go_router + auto_route + built-in. |

### go_router's maintenance posture

go_router is first-party, Flutter-team-maintained, with recent commits (last
commit 2026-07-14, 3 PRs in mid-July) and a small, actively-triaged open-issue
backlog (8–12 issues labeled `p: go_router`). It is in **maintenance mode**:
bug fixes and stability, not new features. That is a sign of maturity, not
abandonment — it remains the ecosystem default and the package most Flutter
apps should reach for first. j_navigation is not a go_router replacement; it
is an alternative for teams whose architecture leans the way j_navigation
leans.

## Feature matrix

| Feature | go_router | auto_route | built-in Router | j_navigation |
|---|---|---|---|---|
| Shell / tabs | ✅ `StatefulShellRoute` | ✅ `AutoTabsRouter` | ❌ DIY | ✅ `SwitchTab` + `IndexedStack` |
| Deep-linking | ✅ | ✅ (codegen) | ✅ native | ✅ `FeatureProvider` |
| **State restoration (process death, per-branch)** | ⚠️ broken (open) | ⚠️ broken (open) | ❌ | ❌ not implemented |
| Typed routes | ✅ (optional codegen) | ✅ (codegen) | ❌ | ✅ typed pages + actions; no serializable route object |
| Codegen | optional | **required** (`build_runner`) | none | none |
| Route registry required | ✅ (`GoRoute` tree) | ✅ (generated) | ❌ | **none** — builder is the route |
| Context-free API | opt-in (via `GoRouter` DI) | opt-in (`StackRouter`) | ❌ | **by construction** |
| Web | ✅ | ✅ | ✅ | ✅ |
| Awaitable presented result | — | — | — | ✅ `present<T>` |
| Built-in screen analytics + screen-time | — | — | — | ✅ `NavigationAnalyticsSink` + `ScreenTimeTracker` |

### The open problem: per-branch restoration on process death

This is the genuinely hard, still-unsolved problem in Flutter navigation.
**All three options above fail it**, with open issues:

- **go_router** — `StatefulShellRoute` does not fully restore per-branch
  back-stacks on Android process death ("Don't keep activities"). Switching
  tabs post-restore loses per-branch history; Android back closes the app.
  Open since Aug 2024. Plus a restoration crash
  (`flutter/flutter#185948`, `RangeError _matchByNavigatorKeyForGoRoute`).
  Plus: rebuilds all pages in a branch's stack on push; can't auto-dismiss a
  `ModalBottomSheetRoute` from a shell route.
- **auto_route** — doesn't restore the full backstack across nested/tabbed
  branches after process death even with `restorationScopeId`; only the
  last-visited tab round-trips. Open Sep 2025.
- **built-in Router** — no restoration natively.

j_navigation does not solve this either — it is an acknowledged gap and a
planned focus (see "Roadmap" below). The point of listing it here is honesty:
restoration is table-stakes-in-theory that nobody has landed yet.

## j_navigation's real strengths

1. **Context-free controller API, by construction.** `navigate(action)` takes
   no `BuildContext` — the controller API never took one, so there is no
   context-first path to drift back into. The incumbents offer context-free
   access as an opt-in escape hatch (grab `GoRouter` / `StackRouter` via DI);
   j_navigation starts there. This pairs naturally with MVVM + Coordinator
   architectures where ViewModels must not touch context. Real distinction
   in default mode, not a capability the incumbents lack entirely.
2. **Action-based, pure stack transforms.** Every navigation is an immutable
   value object; `navigationStackFrom(currentStack) → newStack` is a pure
   function. Trivially unit-testable with no widget tree. go_router
   (declarative config) and auto_route (codegen) don't offer this pattern.
3. **No codegen, no `build_runner`.** A real win vs auto_route (which requires
   codegen). Route builders are plain `WidgetBuilder` closures; no annotation
   processing, no build step.
4. **No route registry.** go_router requires an upfront `GoRoute` tree;
   auto_route requires a generated routes registry. j_navigation needs neither
   — the `WidgetBuilder` is the route, and `navigate` accepts any screen ad
   hoc. Adding a screen is one `Push(builder:)` call, no central config edit.
   The production app pushes 134 distinct screens across 48 coordinators with
   zero route registration. The honest trade: deep-linking is opt-in (a
   `FeatureProvider` maps screen names back to builders only for the screens
   you want URL-reachable), rather than automatic from a registry. Navigation
   is ad-hoc-first; deep-linking is a deliberate, scoped opt-in.
5. **Built-in screen analytics + screen-time tracking.** Navigation emits
   screen-enter / screen-exit events to an opt-in `NavigationAnalyticsSink`
   you implement — no analytics vendor locked in. A `ScreenTimeTracker`
   measures time-on-screen per navigation, carried on the exit event, so you
   get real screen-time analytics for free without wiring a stopwatch. The
   production app swapped analytics providers with **zero navigation-code
   changes** because the analytics boundary was already a sink.
6. **Production-proven engine.** ~8 months in production in a complex fintech
   app, 90 commits, 134 call sites, 3 engineers, zero controller-attributed
   crash frames. See [HISTORY.md](../HISTORY.md). Most OSS navigation packages
   launched as greenfield experiments; j_navigation shipped real users first.
   (The tabbed shell is newer — see scope note in HISTORY.)

## What is not (yet) a strength

- **Restoration.** Not implemented — same hole the incumbents have. Don't
  choose j_navigation *for* restoration; it doesn't have it yet.
- **Serializable route contracts.** Routes are `WidgetBuilder` closures, not
  typed serializable route objects. Pages and actions are typed, but the route
  itself isn't a replayable spec — which is part of why restoration is hard.
- **Shell maturity.** The tabbed shell is new in 1.0.0 (test-covered, not yet
  carried by production traffic). The single-stack engine is the proven part.

## Realistic adoption fit

j_navigation is **not** aiming to displace go_router as the ecosystem default —
go_router is first-party and good. It is a fit for teams that:

- want a **context-free, coordinator-friendly** navigation API;
- prefer **no codegen** and are happy with closure-based routes;
- value **testable, action-based** navigation as pure stack transforms;
- want **screen analytics + screen-time** built into the nav layer;
- can live without per-branch process-death restoration for now.

That is a real, if focused, audience.

## Roadmap

- **Per-branch stack restoration on process death.** The unclaimed wedge —
  both incumbents have it open. Likely requires moving from pure-closure
  routes toward a serializable screen-name → route-spec registry (the
  `FeatureProvider` is the seed).
- **Shell-level overlay stack** so modals persist above all tabs (go_router
  also struggles to cleanly dismiss shell modals).
- **Production-hardening the tabbed shell** by migrating the host app onto it.
