import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:j_navigation/navigation.dart';

import 'mock_analytics.dart';

final class _NoopFeatureProvider implements FeatureProvider {
  const _NoopFeatureProvider();

  @override
  Future<FeatureRoute?> featureRouteFor(String featureName) async => null;
}

Widget button(String text, {required VoidCallback onPressed}) {
  return Platform.isIOS
      ? CupertinoButton(onPressed: onPressed, child: Text(text))
      : ElevatedButton(onPressed: onPressed, child: Text(text));
}

// Set up analytics (optional — NavigationController runs without a sink
// too; this shows the analytics-enabled path). Top-level so page builders
// can capture it without a Provider.
final MockAnalyticsSink analyticsSink = MockAnalyticsSink();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (context) => NavigationController(
        Push(
          analyticsIdentifiable: AnalyticsIdentifiable(
            screenName: 'HomePage',
            builder: (_) => MyHomePage(title: 'Navigation Demo'),
          ),
        ),
        analyticsSink: analyticsSink,
      ),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'j_navigation demo',
      routerConfig: NavigationConfig(
        controller: context.read<NavigationController>(),
        featureProvider: const _NoopFeatureProvider(),
        // Brand colors for navigation-presented UI (dialogs, bottom
        // sheets). Defaults to Material colors when omitted.
        theme: NavigationThemeData(
          scrimColor: Colors.black87,
          cupertinoPrimaryColor: CupertinoColors.activeOrange,
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text('Counter: $_counter'),
          ),
          FloatingActionButton(
            onPressed: () => setState(() => _counter++),
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              button(
                'Push Screen',
                onPressed: () => context.read<NavigationController>().navigate(
                  Push(
                    analyticsIdentifiable: AnalyticsIdentifiable(
                      screenName: 'NestedPage',
                      builder: (context) => NestedPage(),
                    ),
                  ),
                ),
              ),
              button(
                'Present Screen',
                onPressed: () => context.read<NavigationController>().navigate(
                  Present(
                    analyticsIdentifiable: AnalyticsIdentifiable(
                      screenName: 'PresentedPage',
                      builder: (context) => NestedPage(),
                    ),
                  ),
                ),
              ),
              button(
                'Push Multiple',
                onPressed: () => context.read<NavigationController>().navigate(
                  PushMultiple(
                    analyticsIdentifiable: AnalyticsIdentifiable(
                      screenName: 'PushMultiplePage',
                      builder: (context) => NestedPage(),
                    ),
                    hiddenPages: [
                      Present(
                        analyticsIdentifiable: AnalyticsIdentifiable(
                          screenName: 'HiddenPresentedPage',
                          builder: (context) => NestedPage(),
                        ),
                      ),
                      Push(
                        analyticsIdentifiable: AnalyticsIdentifiable(
                          screenName: 'HiddenPushedPage',
                          builder: (context) => NestedPage(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              button(
                'Replace',
                onPressed: () => context.read<NavigationController>().navigate(
                  ReplaceStack(
                    analyticsIdentifiable: AnalyticsIdentifiable(
                      screenName: 'ReplacedHomePage',
                      builder: (context) =>
                          MyHomePage(title: 'Navigation Demo $_counter'),
                    ),
                    animationType: const ReplaceAnimationTypePush(),
                  ),
                ),
              ),
              button(
                'Analytics',
                onPressed: () => context.read<NavigationController>().navigate(
                  Push(
                    analyticsIdentifiable: AnalyticsIdentifiable(
                      screenName: 'AnalyticsPage',
                      builder: (context) =>
                          AnalyticsPage(analyticsSink: analyticsSink),
                    ),
                  ),
                ),
              ),
              button(
                'Await Present Result',
                onPressed: () async {
                  final controller = context.read<NavigationController>();
                  final choice = await controller.present<String>(
                    Present(
                      analyticsIdentifiable: AnalyticsIdentifiable(
                        screenName: 'PickerPage',
                        builder: (context) => PickerPage(),
                      ),
                    ),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Picked: $choice')));
                },
              ),
              button(
                'Tabbed Shell',
                onPressed: () => context.read<NavigationController>().navigate(
                  Push(
                    analyticsIdentifiable: AnalyticsIdentifiable(
                      screenName: 'TabbedShellPage',
                      builder: (context) => const TabbedShellPage(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NestedPage extends StatelessWidget {
  const NestedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nested Page')),
      body: Center(
        child: button(
          'Pop or Dismiss',
          onPressed: () =>
              context.read<NavigationController>().navigate(Dismiss()),
        ),
      ),
    );
  }
}

/// A presented screen that returns a result via a `Dismiss(result: ...)`
/// action — the action-based equivalent of `Navigator.pop(context, result)`.
/// The value resolves the `controller.present<String>(...)` future on the
/// caller side.
class PickerPage extends StatelessWidget {
  const PickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick a color')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            button(
              'Red',
              onPressed: () => context.read<NavigationController>().navigate(
                const Dismiss(result: 'Red'),
              ),
            ),
            button(
              'Green',
              onPressed: () => context.read<NavigationController>().navigate(
                const Dismiss(result: 'Green'),
              ),
            ),
            button(
              'Cancel',
              onPressed: () => context.read<NavigationController>().navigate(
                const Dismiss(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key, required this.analyticsSink});

  final MockAnalyticsSink analyticsSink;

  @override
  Widget build(BuildContext context) {
    final events = analyticsSink.events;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: events.isEmpty
          ? const Center(child: Text('No analytics events yet'))
          : ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _eventToString(events[index]),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
    );
  }

  String _eventToString(Object event) {
    if (event is NavigationScreenEnterEvent) {
      return '${event.runtimeType} - ${event.screenName}\n${event.breadcrumb}';
    } else if (event is NavigationScreenExitEvent) {
      return '${event.runtimeType} - ${event.screenName}: ${event.timeSpent}s';
    } else {
      return event.toString();
    }
  }
}

/// Demonstrates the tabbed shell: a [NavigationController.tabbed] with one
/// independent stack per branch, wrapped in a host-supplied
/// [NavigationShellBuilder] (here a [BottomNavigationBar]). Switching tabs
/// preserves each branch's back stack.
///
/// Hosted in its own nested [MaterialApp.router] so the tabbed controller is
/// fully isolated from the root router.
class TabbedShellPage extends StatefulWidget {
  const TabbedShellPage({super.key});

  @override
  State<TabbedShellPage> createState() => _TabbedShellPageState();
}

class _TabbedShellPageState extends State<TabbedShellPage> {
  // Created once in initState (not in build) so a parent rebuild never resets
  // the branch stacks, and disposed on unmount so the ChangeNotifier and its
  // router-delegate listener are released.
  late final NavigationController controller = NavigationController.tabbed(
    branches: [
      NavigationBranch(
        id: ExampleTab.home,
        initialNavigation: Push(
          analyticsIdentifiable: AnalyticsIdentifiable(
            screenName: 'TabHome',
            builder: (context) => const _TabPage(
              title: 'Home tab',
              detailScreenName: 'TabHomeDetail',
            ),
          ),
        ),
        screenName: 'tab-home',
      ),
      NavigationBranch(
        id: ExampleTab.profile,
        initialNavigation: Push(
          analyticsIdentifiable: AnalyticsIdentifiable(
            screenName: 'TabProfile',
            builder: (context) => const _TabPage(
              title: 'Profile tab',
              detailScreenName: 'TabProfileDetail',
            ),
          ),
        ),
        screenName: 'tab-profile',
      ),
      NavigationBranch(
        id: ExampleTab.settings,
        initialNavigation: Push(
          analyticsIdentifiable: AnalyticsIdentifiable(
            screenName: 'TabSettings',
            builder: (context) => const _TabPage(
              title: 'Settings tab',
              detailScreenName: 'TabSettingsDetail',
            ),
          ),
        ),
        screenName: 'tab-settings',
      ),
    ],
    initialBranchId: ExampleTab.home,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `switchTo` is wired to the bar's onTap; it navigates via SwitchTab so
    // each branch's stack survives the switch. Provider.value is used because
    // the StatefulWidget owns the controller's lifecycle (dispose above).
    return ChangeNotifierProvider<NavigationController>.value(
      value: controller,
      child: MaterialApp.router(
        routerConfig: NavigationConfig(
          controller: controller,
          shellBuilder:
              (context, branchContent, activeId, activeIndex, switchTo) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Tabbed Shell')),
                  body: branchContent,
                  bottomNavigationBar: BottomNavigationBar(
                    currentIndex: activeIndex,
                    onTap: (index) => switchTo(controller.branchIds[index]),
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.settings),
                        label: 'Settings',
                      ),
                    ],
                  ),
                );
              },
        ),
      ),
    );
  }
}

/// Identifies a branch in the tabbed shell example.
enum ExampleTab { home, profile, settings }

/// A branch root page with a button to push a detail — proves each branch
/// keeps its own back stack across tab switches.
class _TabPage extends StatelessWidget {
  const _TabPage({required this.title, required this.detailScreenName});
  final String title;
  final String detailScreenName;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<NavigationController>();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: button(
          'Push detail (preserved on tab switch)',
          onPressed: () => controller.navigate(
            Push(
              analyticsIdentifiable: AnalyticsIdentifiable(
                screenName: detailScreenName,
                builder: (context) => _TabDetailPage(title: detailScreenName),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabDetailPage extends StatelessWidget {
  const _TabDetailPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<NavigationController>();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: button('Back', onPressed: () => controller.navigate(Dismiss())),
      ),
    );
  }
}
