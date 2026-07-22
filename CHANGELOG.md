# Changelog

## Unreleased

- _(open for next changes)_

## 1.0.0

First standalone, open-source-ready release. Analytics is an opt-in sink
interface (no analytics vendor locked in) and presented UI is themed through a
self-contained `NavigationTheme`. The router now reports its current route so
the browser address bar reflects navigation on web.

### Breaking changes

- **`NavigationController` constructor**: analytics is now passed as an
  optional `NavigationAnalyticsSink? analyticsSink`. Pass `null` (or omit)
  for the "no analytics" build; pass a sink implementing
  `NavigationAnalyticsSink` to receive screen-enter / screen-exit events.
- **Analytics event types**: navigation emits self-contained
  `NavigationScreenEnterEvent` and `NavigationScreenExitEvent` objects to the
  sink (with `screenName`, `navigationMethod`, `sourceScreen`, `breadcrumb`
  on enter; `exitMethod`, `destinationScreen`, `timeSpent` on exit).
- **`AnalyticsQueue`**: takes a `NavigationAnalyticsSink`; enqueue a
  `NavigationAnalyticsEvent` via a single `enqueue(event)` (the queue
  dispatches enter/exit to the sink). `flush()` drains the queue and calls
  `sink.flush()`.
- **Presented UI theming**: `AlertDialogPage` and `ModalBottomSheetPage` read
  `NavigationTheme.of(context)` (which falls back to Material defaults when no
  theme is configured) instead of host theme colors.
- **`NavigationConfig`**: accepts an optional `NavigationThemeData? theme`
  used to theme the router's presented UI.

### Added

- `NavigationAnalyticsSink` — interface class; implementers override
  `onScreenEnter`, `onScreenExit`, and optionally `flush`. Default const
  constructor is a no-op sink.
- `NavigationScreenEnterEvent` / `NavigationScreenExitEvent` — self-contained event
  objects with `screenName`, `navigationMethod`, `sourceScreen`, `breadcrumb`
  (enter) and `exitMethod`, `destinationScreen`, `timeSpent` (exit).
- `NavigationTheme` (`InheritedWidget`) and `NavigationThemeData` (`scrimColor`,
  `cupertinoPrimaryColor`, both defaulting to Material/Cupertino defaults).
- `NavigationConfig.theme` to supply navigation-presented UI colors per router.
- **Web address bar support**: `NavigationRouterDelegate.currentConfiguration`
  reports the top-of-stack screen, and `NavigationRouteInformationParser
  .restoreRouteInformation` serializes it to a URL path. On web the browser
  address bar reflects the current screen; deep-linkable screens (registered
  in the `FeatureProvider`) round-trip fully, while programmatic pushes reflect
  in the URL but resolve to no navigation on reload unless the host also maps
  that screen name.
- **Awaitable presented results**: `NavigationController.present<T>(Present)`
  navigates and awaits the value the screen returns via
  `Navigator.pop(context, result)`, resolving with `null` on a programmatic
  dismiss. `Present.dismissed` exposes the underlying untyped future.
- **Tabbed navigation (shell)**: `NavigationController.tabbed(branches:...)`
  keeps an independent navigation stack per branch (tab). `SwitchTab(id,
  thenNavigate:...)` flips the active branch without disturbing either stack.
  `NavigationBranch` / `NavigationBranchId` describe each branch (root page,
  `wantsKeepAlive`, URL `screenName`). `NavigationConfig.shellBuilder` wraps an
  `IndexedStack` of per-branch `Navigator`s with host-supplied chrome (e.g. a
  bottom navigation bar). Branch switches emit enter/exit analytics. On web the
  address bar encodes `/<branchScreen>/<topScreen>` for the active branch.
  Per-branch stack restoration on process death is out of scope for this
  release. Single-stack (non-tabbed) controllers are behavior-identical to
  before — the tabbed path is opt-in.

  **Known limitations (tabbed mode):** the address bar encodes
  `/<branchScreen>/<topScreen>` for display, but on reload the parser does not
  auto-strip the branch segment — the host `FeatureProvider` must recognize the
  branch segment to restore navigation (full tabbed deep-link round-trip is
  planned). `NavigatorObserver`s passed to `NavigationConfig` are attached to
  every branch `Navigator`; because an observer records a single navigator, in
  tabbed mode it receives undifferentiated events from all branches (per-branch
  observer API planned). The public `navigatorKey` is unused in tabbed mode;
  use `NavigationRouterDelegate.currentNavigatorKey` for the on-stage
  `NavigatorState`.
- **`RouteConfig`**: gained a nullable `branchScreenName` field used to
  serialize the active branch. Existing `RouteConfig` constructions must add
  `branchScreenName: null` (or the active branch's screen name when tabbed).

### Removed

- Dependencies on `j_analytics` and `design_system` (from `pubspec.yaml`).
- Transitive `package:j_analytics/analytics.dart` and `package:design_system/design_system.dart`
  imports throughout `lib/`.

### Migration

Replace any `AnalyticsModule` wiring with a `NavigationAnalyticsSink` implementation
that adapts to your analytics stack, and pass it as `analyticsSink:`. If you only
consumed `ScreenEnterEvent` / `ScreenExitEvent`, map their fields onto the new
`NavigationScreen*Event` types (note `breadcrumb` is now a top-level field, not nested
under `extraProperties`).
