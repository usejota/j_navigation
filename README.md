# j_navigation - Action-Based Navigation System

A production-proven, action-based navigation system for Flutter, built on
`RouterDelegate` (Navigator 2.0). Navigation is expressed as **immutable, typed
action objects** processed by a single, `BuildContext`-free controller — so your
ViewModels and coordinators can navigate without ever holding a context.

## Why j_navigation

j_navigation was extracted from a shipping fintech app (tap-to-pay, PIX, open
finance, chat) after **~8 months in production**, not spun up as a side
project. Every navigation edge case the app hit — keyboard-deferred navigation,
bottom-sheet deduplication, Android system-back exit semantics, deep-link
cold-start races, analytics-vendor swaps — was caught and fixed in the engine.
The commit log is the receipt; see [HISTORY.md](HISTORY.md).

> **Scope of "production-proven":** the core engine (single-stack navigation,
> actions, analytics sink, deep-linking, system-back). The **tabbed shell**
> (`NavigationController.tabbed`, `SwitchTab`) and **web address-bar
> reporting** are new in 1.0.0 and are **test-covered, not yet shipped to
> production users** — the host app still runs its own `MainContainer` tab
> system. Treat the shell as v1 and report rough edges.

### What's different

- **Context-free controller API, by construction.** `controller.navigate(action)`
  takes no `BuildContext` — the controller API never took one, so there is no
  context-first path to fall back into. Navigate from coordinators,
  ViewModels, stores, or services without a widget tree. In the production
  app, all 48 feature coordinators hold the `NavigationController` and call
  `navigate()` directly — proof the API scales to that pattern at
  real-app size. (Coordinators can be driven with any DI'd router; j_navigation's
  distinction is that context-free is the default, not an opt-in escape hatch.)
  Unit-test navigation without `tester.pumpWidget`.
- **Action-based, pure stack transforms.** Every navigation is an immutable
  `NavigationType` (`Push`, `Present`, `Dismiss`, `ReplaceStack`,
  `ReplaceTop`, `PopTo`, `PushMultiple`, `SwitchTab`, …). Each implements
  `navigationStackFrom(currentStack) → newStack` — a pure function, trivially
  unit-testable, with no hidden state.
- **No codegen, no `build_runner`.** Route builders are plain `WidgetBuilder`
  closures. Pages and actions are already typed; no annotation processing,
  no generated code, no build step.
- **No route registry.** Navigate to any screen with a `WidgetBuilder` — no
  upfront route tree to declare (go_router) and no generated routes registry
  to maintain (auto_route). The builder IS the route; call `navigate` from
  any coordinator and the screen appears. In the production app, 48 feature
  coordinators push 134 distinct screens with zero route registration.
  Deep-linkable screens are opt-in via `FeatureProvider` (you register only
  the screens you want reachable by URL), so navigation stays ad-hoc while
  deep-linking is a deliberate, scoped choice — not the other way around.
- **Bring-your-own analytics.** Screen enter/exit events flow to an opt-in
  `NavigationAnalyticsSink` you implement — no analytics vendor locked in. The
  production app swapped analytics providers with **zero navigation-code
  changes** because the analytics boundary was already a sink.
- **Single-controller tabbed shell.** `NavigationController.tabbed` holds one
  independent stack per branch; `SwitchTab` flips the active-branch pointer
  without touching either stack, so each tab's history survives switches.
- **Awaitable presented results.** `controller.present<T>(Present)` awaits the
  value the screen pops via `Navigator.pop(context, result)`.
- **Self-contained theming + web address bar.** Presented UI reads a
  `NavigationTheme` (Material defaults when unconfigured); the router reports
  `currentConfiguration` so the browser address bar reflects navigation.

### Honest scope

j_navigation matches the incumbents (go_router, auto_route) on the table-stakes
features — shell/tabs, deep-linking, web, transitions. Two caveats a reviewer
should know up front:

- The **tabbed shell** and **web address-bar reporting** are new in 1.0.0 and
  **test-covered, not yet production-adopted** (see the note in "Why
  j_navigation"). The single-stack engine is the production-proven part.
- It does **not** (yet) ship per-branch stack restoration on process death;
  that is a known gap and a planned focus (both go_router and auto_route also
  fail this — see `doc/POSITIONING.md`).

See [Positioning](doc/POSITIONING.md) for a candid comparison against the
Flutter navigation landscape and where j_navigation fits.

`j_navigation` has **no dependency on a concrete analytics or design-system
package**. Analytics is an opt-in sink interface you adapt to your own stack, and
presented UI (dialogs, bottom sheets) is themed through a small, self-contained
theme that falls back to Material defaults.

## Features

- **Action-based navigation**: Navigate using composable action objects (`Push`, `Present`, `Dismiss`, `ReplaceStack`, `ReplaceTop`, `PushMultiple`)
- **Bring-your-own analytics**: Opt-in screen-enter / screen-exit events emitted to a sink interface you implement — no analytics vendor locked in
- **Performance optimized**: History compression, navigation stack caching, and efficient analytics processing
- **Centralized state management**: Single `NavigationController` manages the entire navigation stack
- **RouterDelegate integration**: Built on Flutter's modern navigation 2.0 architecture
- **Breadcrumb navigation**: Maintains action history for consistent navigation behavior and deep linking
- **Advanced navigation patterns**: Support for modal presentations, stack replacement, and multi-page pushes
- **Type-safe**: Strongly typed navigation actions with compile-time safety
- **Memory efficient**: Automatic history compression prevents unbounded memory growth
- **Same-page navigation policy**: Choose how to handle navigating to the same screen twice (ReplaceTop, NoReplace, or Custom)
- **Self-contained theming**: Navigation-presented UI reads colors from a `NavigationTheme` that defaults to Material when unconfigured
- **Tabbed navigation (shell)**: Independent per-branch navigation stacks that survive tab switches, with a host-supplied shell (bottom nav, drawer) built around an `IndexedStack` of branch `Navigator`s
- **Web-ready**: The router reports its current route so the browser address bar reflects navigation; deep-linkable screens round-trip via the `FeatureProvider`

## Getting started

Add `j_navigation` to your `pubspec.yaml`:

```yaml
dependencies:
  j_navigation: ^1.0.0
  provider: ^6.0.0    # Optional, for state management
```

Then run:
```bash
flutter pub get
```

## Usage

### Basic Setup with Provider (Recommended)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:j_navigation/navigation.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => NavigationController(
        Push(
          analyticsIdentifiable: AnalyticsIdentifiable(
            screenName: 'HomeScreen',
            builder: (_) => HomeScreen(),
          ),
        ),
        // analyticsSink: MyAnalyticsSink(), // optional — see "Analytics" below
      ),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: NavigationConfig(
        controller: context.read<NavigationController>(),
        // featureProvider: MyFeatureProvider(), // optional — enables deep linking
        // theme: NavigationThemeData(scrimColor: Colors.black87), // optional
      ),
    );
  }
}
```

> Without an `analyticsSink`, the controller runs in a "no analytics" build — navigation works exactly the same, just without event emission.
>
> `featureProvider` is also optional: omit it for a navigation-only setup, or supply a `FeatureProvider` to enable deep linking.

### Navigation Actions

#### Push - Add a new screen to the stack
```dart
context.read<NavigationController>().navigate(
  Push(
    analyticsIdentifiable: AnalyticsIdentifiable(
      screenName: 'DetailsScreen',
      builder: (context) => DetailsScreen(),
    ),
  ),
);
```

#### Present - Show a fullscreen modal dialog
```dart
context.read<NavigationController>().navigate(
  Present(
    analyticsIdentifiable: AnalyticsIdentifiable(
      screenName: 'ModalScreen',
      builder: (context) => ModalScreen(),
    ),
  ),
);
```

#### Dismiss - Remove the current screen from the stack
```dart
context.read<NavigationController>().navigate(Dismiss());
```

#### ReplaceStack - Replace entire navigation stack
Replaces the entire navigation stack with a new screen. Useful for resetting the navigation state (e.g., after login/logout).
```dart
context.read<NavigationController>().navigate(
  ReplaceStack(
    analyticsIdentifiable: AnalyticsIdentifiable(
      screenName: 'NewHomeScreen',
      builder: (context) => NewHomeScreen(),
    ),
  ),
);

// With hidden pages to build a specific stack
context.read<NavigationController>().navigate(
  ReplaceStack(
    hiddenPages: [
      Push(
        analyticsIdentifiable: AnalyticsIdentifiable(
          screenName: 'LandingScreen',
          builder: (context) => LandingScreen(),
        ),
      ),
    ],
    analyticsIdentifiable: AnalyticsIdentifiable(
      screenName: 'MainScreen',
      builder: (context) => MainScreen(),
    ),
  ),
);
```

#### ReplaceTop - Replace only the top screen
Replaces only the topmost screen in the navigation stack while preserving the rest of the stack. Useful for replacing a screen without affecting navigation history.
```dart
context.read<NavigationController>().navigate(
  ReplaceTop(
    analyticsIdentifiable: AnalyticsIdentifiable(
      screenName: 'UpdatedDetailsScreen',
      builder: (context) => UpdatedDetailsScreen(),
    ),
    // iOS: set to false to disable back-swipe gesture
    // swipeToDismissEnabled: true,
  ),
);
```

#### PushMultiple - Push multiple screens with intermediate pages
```dart
context.read<NavigationController>().navigate(
  PushMultiple(
    hiddenPages: [
      Push(
        analyticsIdentifiable: AnalyticsIdentifiable(
          screenName: 'IntermediateScreen1',
          builder: (context) => IntermediateScreen1(),
        ),
      ),
      Push(
        analyticsIdentifiable: AnalyticsIdentifiable(
          screenName: 'IntermediateScreen2', 
          builder: (context) => IntermediateScreen2(),
        ),
      ),
    ],
    analyticsIdentifiable: AnalyticsIdentifiable(
      screenName: 'FinalScreen',
      builder: (context) => FinalScreen(),
    ),
  ),
);
```

For a complete working example, see the `example/` directory in this package.

### Same-Page Navigation Policy

When navigating to the same screen consecutively, you can decide how to handle it using `samePageReplaceType`:

- `SamePageNavigationReplaceTop()` (default): replaces the top entry with the new one (keeps history clean).
- `SamePageNavigationNoReplace()`: always navigates, even if it's the same screen.
- `SamePageNavigationCustomReplace(handler: ...)`: decide dynamically how to transform the action.

Examples:

```dart
// Default: ReplaceTop when navigating to the same screen
controller.navigate(
  Push(
    analyticsIdentifiable: AnalyticsIdentifiable(
      screenName: 'Details',
      builder: (_) => DetailsScreen(),
    ),
  ),
  // samePageReplaceType: const SamePageNavigationReplaceTop(), // default
);

// Disable replacement (always push)
controller.navigate(
  Push(
    analyticsIdentifiable: AnalyticsIdentifiable(
      screenName: 'Details',
      builder: (_) => DetailsScreen(),
    ),
  ),
  samePageReplaceType: const SamePageNavigationNoReplace(),
);

// Custom behavior (e.g., switch to ReplaceTop only for specific screens)
controller.navigate(
  Push(
    analyticsIdentifiable: AnalyticsIdentifiable(
      screenName: 'Details',
      builder: (_) => DetailsScreen(),
    ),
  ),
  samePageReplaceType: SamePageNavigationCustomReplace(
    handler: (current) {
      // You can return ReplaceTop/ReplaceStack/Push/etc
      return ReplaceTop(
        analyticsIdentifiable: AnalyticsIdentifiable(
          screenName: current.screenName,
          builder: current.builder,
        ),
        navigationKey: current.key,
        // Preserve current swipe/animation semantics if desired
        animated: current.animated,
        swipeToDismissEnabled: current is DismissableNavigationType
            ? current.swipeToDismissEnabled
            : true,
      );
    },
  ),
);
```

Note: Analytics and breadcrumbs reflect the effective action after policy is applied (e.g., a Push that resolves to ReplaceTop is tracked as ReplaceTop).

### Dismiss Callbacks

You can intercept dismisses on a per-page basis by registering a callback for a page key. Return `false` to block the dismiss.

```dart
// Register
controller.registerDismissCallback(pageKey, () {
  // e.g., prompt to save changes; return false to block
  return canSafelyDismiss();
});

// Unregister when appropriate
controller.unregisterDismissCallback(pageKey);
```

### Swipe-to-Dismiss (iOS)

`Push`, `ReplaceTop`, and `ReplaceStack` support a `swipeToDismissEnabled` flag:
- When `true` (default), the standard back-swipe gesture is enabled on iOS.
- When `false` on iOS, the page is built with a no-swipe page wrapper to disable the gesture. Animation stays smooth.

Examples:
```dart
Push(
  analyticsIdentifiable: AnalyticsIdentifiable(
    screenName: 'Profile',
    builder: (_) => ProfileScreen(),
  ),
  swipeToDismissEnabled: false, // Disable back-swipe on iOS
);

ReplaceTop(
  analyticsIdentifiable: AnalyticsIdentifiable(
    screenName: 'EditProfile',
    builder: (_) => EditProfileScreen(),
  ),
  swipeToDismissEnabled: true,
);
```

## Awaiting a presented screen's result

A `Present` screen can return a value via `Navigator.pop(context, result)`. Await it with `NavigationController.present`, typed by the result you expect:

```dart
final choice = await controller.present<String>(
  Present(
    analyticsIdentifiable: AnalyticsIdentifiable(
      screenName: 'Picker',
      builder: (context) => PickerScreen(),
    ),
  ),
);
if (choice != null) {
  // user picked `choice`
}
```

`present` navigates and returns a future that resolves with the value the screen popped, or `null` if it was dismissed programmatically (e.g. a `Dismiss` action) or popped without a result. Declare `T` to match your result type — a mismatch throws at await time.

> Use the screen's own `BuildContext` for `Navigator.pop` (from inside the screen's `build`), not the `builder` param captured on `AnalyticsIdentifiable` — that resolves to the router's navigator, not the presented route.

`Present.dismissed` is the underlying untyped future if you prefer to await the action directly.

## Analytics

`j_navigation` does not depend on any analytics package. Instead it defines a small sink interface — `NavigationAnalyticsSink` — that receives self-contained `NavigationScreenEnterEvent` / `NavigationScreenExitEvent` objects. Implement the sink and pass it to `NavigationController`:

```dart
import 'package:j_navigation/navigation.dart';

final class MyAnalyticsSink implements NavigationAnalyticsSink {
  final YourAnalyticsBackend _backend;
  MyAnalyticsSink(this._backend);

  @override
  void onScreenEnter(NavigationScreenEnterEvent event) {
    _backend.track('screen_enter', {
      'screen_name': event.screenName,
      'source_screen': event.sourceScreen,
      'navigation_method': event.navigationMethod,
      'breadcrumb': event.breadcrumb,
    });
  }

  @override
  void onScreenExit(NavigationScreenExitEvent event) {
    _backend.track('screen_exit', {
      'screen_name': event.screenName,
      'destination_screen': event.destinationScreen,
      'exit_method': event.exitMethod,
      'time_spent_seconds': event.timeSpent,
    });
  }

  @override
  Future<void> flush() => _backend.flush();
}

// Wire it up:
final controller = NavigationController(
  Push(analyticsIdentifiable: AnalyticsIdentifiable(
    screenName: 'Home', builder: (_) => HomeScreen(),
  )),
  analyticsSink: MyAnalyticsSink(backend),
);
```

When no sink is provided, `NavigationController` silently skips analytics — the "no analytics" build. The sink's `flush()` is called on controller dispose so buffered events drain before teardown.

### Event fields

| Event | Field | Description |
|---|---|---|
| `NavigationScreenEnterEvent` | `screenName` | Screen being entered |
| | `navigationMethod` | Action that triggered the enter (push, present, replace, …) |
| | `sourceScreen` | Screen navigated from |
| | `breadcrumb` | Breadcrumb trail at enter time |
| `NavigationScreenExitEvent` | `screenName` | Screen being exited |
| | `exitMethod` | Method used to exit (dismiss, pop, replace, …) |
| | `destinationScreen` | Screen navigated to |
| | `timeSpent` | Seconds spent on screen, if tracked |

### Performance Features

#### Memory Management
- **History Compression**: Navigation history is automatically compressed after 100 actions to prevent memory leaks
- **Navigation Stack Caching**: Computed navigation stacks are cached for improved performance
- **Breadcrumb Indicators**: Shows `"... > "` prefix when history has been compressed

#### Analytics Optimization
- **Post-Frame Processing**: Analytics events are processed after UI rendering to prevent blocking
- **Clock-Resistant Timing**: Uses `Stopwatch` instead of `DateTime` for accurate time measurements
- **Efficient Type Caching**: Navigation type names are cached to reduce string computation overhead

## Theming

Navigation-presented UI (alert dialogs and modal bottom sheets) reads its colors from `NavigationTheme`, a self-contained `InheritedWidget`. Colors default to the Material/Cupertino defaults, so an unconfigured package still renders with standard colors.

Customize in one of two ways:

**1. Via `NavigationConfig`** — applies the theme to all navigation-presented UI in that router:

```dart
import 'package:flutter/cupertino.dart'; // for CupertinoColors

MaterialApp.router(
  routerConfig: NavigationConfig(
    controller: controller,
    theme: NavigationThemeData(
      scrimColor: Colors.black87,
      cupertinoPrimaryColor: CupertinoColors.activeOrange,
    ),
  ),
);
```

**2. Via the `NavigationTheme` widget** — override per-subtree:

```dart
NavigationTheme(
  data: NavigationThemeData(scrimColor: Colors.black87),
  child: MyApp(),
);
```

`NavigationThemeData` exposes:
- `scrimColor` — modal barrier color behind dialogs and bottom sheets (default `Colors.black54`).
- `cupertinoPrimaryColor` — accent for the primary action in Cupertino-style alerts (default `CupertinoColors.activeBlue`).

## Web & the browser address bar

The router reports its current route, so on web the browser address bar reflects where the user is. Serialization is built on screen names:

- The top-of-stack screen's `screenName` becomes the URL path segment (e.g. `/ProductDetails`).
- Screens registered in your `FeatureProvider` round-trip fully — the URL bar, back/forward, and reload all resolve back to the right screen.
- Screens pushed programmatically (without a `FeatureProvider` entry matching their `screenName`) still appear in the address bar, but on reload they resolve to no navigation. Register any screen you want to be deep-linkable in the `FeatureProvider`.

On mobile native, route reporting is a no-op (the platform has no address bar); deep-link arrival still works as before via the `PlatformRouteInformationProvider`.

## Tabbed navigation (shell)

A tabbed controller keeps an independent navigation stack per branch (tab). Switching branches preserves each branch's stack — push on tab A, switch to B, push on B, switch back to A, and A's stack is exactly as you left it.

### Building a tabbed controller

```dart
import 'package:j_navigation/navigation.dart';

enum Tab { home, profile, statement }

final controller = NavigationController.tabbed(
  branches: [
    NavigationBranch(
      id: Tab.home,
      initialNavigation: Push(
        analyticsIdentifiable: AnalyticsIdentifiable(
          screenName: 'HomeScreen',
          builder: (context) => HomeScreen(),
        ),
      ),
      screenName: 'home', // segment used in the web URL
    ),
    NavigationBranch(
      id: Tab.profile,
      initialNavigation: Push(
        analyticsIdentifiable: AnalyticsIdentifiable(
          screenName: 'ProfileScreen',
          builder: (context) => ProfileScreen(),
        ),
      ),
      screenName: 'profile',
    ),
  ],
  initialBranchId: Tab.home,
);
```

- `id` is the branch identity — use a const/frozen value (an `enum` value, an `int`, a const object). Never a fresh `Object()` per construction, since identity would never match.
- `wantsKeepAlive` (default `true`) keeps the branch's subtree alive while off-stage; set `false` to dispose and rebuild it on return.
- `screenName` is the URL segment prepended to the top-of-stack screen on web (`/<branchScreen>/<topScreen>`). When omitted it falls back to the initial page's `screenName`.

### Switching tabs

```dart
controller.navigate(const SwitchTab(Tab.profile));

// Switch and immediately push on the new branch:
controller.navigate(SwitchTab(
  Tab.profile,
  thenNavigate: Push(
    analyticsIdentifiable: AnalyticsIdentifiable(
      screenName: 'EditProfileScreen',
      builder: (context) => EditProfileScreen(),
    ),
  ),
));
```

`SwitchTab` does not modify either branch's stack — it only flips the active branch pointer. Branch switches emit enter/exit analytics through the `NavigationAnalyticsSink` like any other navigation.

### Rendering the shell

The package renders an `IndexedStack` of per-branch `Navigator`s (with keep-alive per branch). The surrounding chrome — the bottom navigation bar itself — stays host-supplied so the package never assumes your UI:

```dart
MaterialApp.router(
  routerConfig: NavigationConfig(
    controller: controller,
    shellBuilder: (context, branchContent, activeId, activeIndex, switchTo) {
      return Scaffold(
        body: branchContent,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: activeIndex,
          onTap: (index) => switchTo(controller.branchIds[index]),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      );
    },
  ),
);
```

`shellBuilder` is ignored for single-stack (non-tabbed) controllers.

### Scope notes

- **Branch-scoped actions.** `Push`, `Present`, `Dismiss`, `ReplaceStack`, `ReplaceTop`, and `PopTo` act on the active branch only. Cross-branch navigation uses `SwitchTab(target, thenNavigate: ...)`.
- **`Present` (modals) is branch-scoped.** A modal presented on tab A is tied to A's stack; switching tabs visually dismisses it. A shell-level overlay stack (modals that persist above all tabs) is planned for a follow-up.
- **Web URL (address bar only).** The address bar encodes the active branch and its top-of-stack screen (`/<branchScreen>/<topScreen>`). On reload, the parser does **not** auto-strip the branch segment — the host's `FeatureProvider` must recognize the branch screen segment (or map the full path) to restore navigation. Full tabbed deep-link round-trip and per-branch stack restoration on process death are out of scope for this release.
- **`NavigatorObserver`s in tabbed mode.** Observers passed to `NavigationConfig` are attached to every branch `Navigator`. Because a `NavigatorObserver` records a single `_navigator`, in tabbed mode it ends up pointing at the last-built branch and receives undifferentiated events from all branches. For per-branch observation, attach observers to each branch `Navigator` yourself (a per-branch observer API is planned). Single-stack controllers are unaffected.
- **`navigatorKey` in tabbed mode.** In tabbed mode the public `navigatorKey` is not attached to any `Navigator` (each branch owns its own). Use `NavigationRouterDelegate.currentNavigatorKey` to reach the on-stage `NavigatorState` — works for both single-stack and tabbed controllers.
- **Fixed branch set.** Branches are registered at construction time. To hide a branch's tab button (e.g. seller-mode restriction), filter in your `shellBuilder` — the controller keeps all branches registered.

## Architecture

The package is built around these core concepts:

1. **NavigationType**: Abstract base class for all navigation actions (`Push`, `Present`, `Dismiss`, `ReplaceStack`, `ReplaceTop`, `PushMultiple`, `SwitchTab`)
2. **AnalyticsIdentifiable**: Data class containing screen name and builder for analytics tracking
3. **NavigationBranch / NavigationBranchId**: A tab's identity and root page; the controller holds one independent stack per branch
4. **NavigationController**: Extends `ChangeNotifier` to manage navigation stack(s), action history, and analytics
5. **NavigationConfig**: RouterConfig implementation that bridges the controller with Flutter's Router
6. **NavigationAnalyticsSink**: Opt-in sink interface receiving `NavigationScreenEnterEvent` / `NavigationScreenExitEvent`
7. **AnalyticsQueue**: Background processing queue for analytics events with post-frame scheduling
8. **ScreenTimeTracker**: Stopwatch-based screen time measurement for accurate analytics
9. **NavigationTheme / NavigationThemeData**: Self-contained theming for presented UI
10. **Action History**: All navigation actions are stored with automatic compression for memory efficiency

### Navigation Flow

1. **Action Creation**: Navigation actions are created as immutable objects with analytics data
2. **Controller Processing**: The `NavigationController` processes actions and updates the navigation stack
3. **Analytics Tracking**: Screen exit/enter events are generated and queued (only when a sink is provided)
4. **History Management**: Actions are stored with automatic compression when exceeding 100 items
5. **Cache Invalidation**: Navigation stack cache is invalidated and recomputed as needed
6. **State Notification**: Changes are broadcast through `ChangeNotifier` for UI updates
7. **UI Rebuild**: The RouterDelegate rebuilds the navigation stack based on the cached state
8. **Post-Frame Analytics**: Analytics events are processed after frame rendering completes

This architecture enables predictable navigation behavior, optional analytics tracking, and optimal performance while maintaining memory efficiency.


## Additional information

This package is designed for applications that need fine-grained control over navigation flow with optional, vendor-neutral analytics tracking while maintaining the benefits of Flutter's declarative UI paradigm. It's particularly useful for:

- Complex navigation scenarios where traditional imperative navigation becomes difficult to manage
- Applications that want to plug their own analytics stack into screen-time tracking
- Production apps that need memory-efficient navigation with automatic optimization
- Teams that want type-safe navigation with comprehensive testing support

For issues and feature requests, please file them in the project repository.
