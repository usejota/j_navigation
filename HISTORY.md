# History

j_navigation has always been a package — it was born as the in-app navigation
engine of a shipping fintech app (tap-to-pay, PIX, open finance, chat) and was
decoupled for open source once the engine stabilized. This document is the
receipt for the "production-proven" claim: every entry below is a real change
made because the app hit a real navigation situation in production.

## Timeline

| Date | Event |
|---|---|
| 2025-06-09 | Package created (`5c44b9eb`). |
| ~2025-11 → 2026-07 | ~8 months carrying production traffic, across releases up to `1.4.6+179`. |
| 2026-07 | Decoupled from in-house analytics and design-system packages; **tabbed shell support added** (new — test-covered, not yet shipped to production users); open-source ready. |

> **Production scope.** The production run covers the single-stack engine
> (navigation actions, analytics sink, deep-linking, system-back). The tabbed
> shell (`NavigationController.tabbed`, `SwitchTab`) and web address-bar
> reporting were added for 1.0.0 and are exercised by the test suite and the
> example app, but the host app has not yet migrated onto them — treat them as
> v1.

## By the numbers (as of the open-source split)

- **~8 months** in production.
- **90 commits** touching the package.
- **134 static call sites** across the host app (`navigation_controller.dart`
  is hot-file rank #6 by caller count).
- **48 feature coordinators** drive all navigation in the host app — each
  holds the `NavigationController` and calls `navigate()` directly.
  Coordinators aren't widgets, so this only works because the controller API
  is context-free. This is the architecture the engine was extracted from.
- **3 engineers** contributed.
- **0 crash-attributed frames** in `navigation_controller.dart` over the
  production window (verified via the host app's crash tracker).

## Production PRs that shaped the engine

Each PR below fixed a navigation behavior the app needed in production, not a
theoretical concern.

| PR | What it solved |
|---|---|
| #182 | Deep-link support for 12 features; introduced `DismissToTab` (switch tab + chain navigation) and `UseNavigationPath` for programmatic in-app deep links. Cold-start deep-link races handled. |
| #194 | Refactored chat screen to FP patterns; added **keyboard-deferred navigation** — navigation is deferred until the software keyboard dismisses, so a push doesn't race the keyboard animation. |
| #290 | Added `BottomSheetPresentationManager` with session-level deduplication (one managed sheet at a time, once per foreground session) to stop sheet-stacking bugs. |
| #387 | Stack-aware **Android system-back exit semantics** — back pops when there's a stack to pop, exits the app at root, with an optional confirmation handler. Stopped the "back closes the app at home" bug. |
| #280 | Flutter/Dart SDK upgrade (3.44.0 / 3.12.0) + migrating constructors to initializing formals — kept the engine current with the latest Flutter line. |

## What "production-proven" means here — and what it doesn't

**Does mean:** the engine has carried real user traffic, on a real device
matrix, through real edge cases (keyboard races, sheet dedup, back-button
semantics, deep-link cold start, analytics-vendor swap). The API stabilized
under that pressure — 134 call sites depend on it without churn.

**Doesn't mean:**

- **Multi-app provenance.** Battle-tested in one app. The API is shaped by that
  app's needs; assumptions may surface when other apps adopt it. Treat the first
  external adopters as collaborators, not just users.
- **Restoration.** Per-branch stack restoration on process death is **not**
  implemented. The production app did not require it. See
  [doc/POSITIONING.md](doc/POSITIONING.md).
- **Crash-free.** The host app has runtime crashes (frame timing, layout,
  signals). None are attributed to the navigation controller, but
  "zero nav crashes" is not the same as "zero app crashes." Don't conflate them.

## Open-source split (2026-07)

The decouple was deliberately scoped to remove host coupling without changing
the existing single-stack behavior:

- `j_analytics` → `NavigationAnalyticsSink` (opt-in interface; pass `null` for
  the no-analytics build).
- `design_system` → `NavigationTheme` / `NavigationThemeData` (self-contained,
  Material defaults).
- Tabbed shell added (`NavigationController.tabbed`, `SwitchTab`,
  `NavigationShellBuilder`) — generalizing the host's `MainContainer` tab system
  into the package.
- Web address bar support (`currentConfiguration` + `restoreRouteInformation`).
- Awaitable presented results (`present<T>`).

Single-stack (non-tabbed) controllers are behavior-identical to the pre-split
engine; the tabbed path is fully opt-in.
