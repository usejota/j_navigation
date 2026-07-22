// ignore_for_file: prefer-moving-to-variable, no-empty-block, no-magic-number
// ignore_for_file: avoid-dynamic, prefer-static-class
// ignore_for_file: cascade_invocations, no_leading_underscores_for_local_identifiers, lines_longer_than_80_chars, avoid_redundant_argument_values

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:j_navigation/navigation.dart';
import 'package:j_navigation/test_exports.dart';

// Helper function to create navigation types with analytics
AnalyticsIdentifiable _createAnalytics(
  WidgetBuilder builder, [
  String? screenName,
]) {
  return AnalyticsIdentifiable(
    screenName: screenName ?? 'TestScreen${builder.hashCode}',
    builder: builder,
  );
}

final class _NoopFeatureProvider implements FeatureProvider {
  const _NoopFeatureProvider();

  @override
  Future<FeatureRoute?> featureRouteFor(String featureName) async => null;
}

final class _TestFeatureProvider implements FeatureProvider {
  _TestFeatureProvider(this._routes);

  final Map<String, FeatureRoute> _routes;

  @override
  Future<FeatureRoute?> featureRouteFor(String featureName) async {
    return _routes[featureName];
  }
}

final class _CapturingFeatureRoute implements FeatureRoute {
  @override
  List<String> get piorNavigationRequired => const <String>[];

  Map<String, String>? lastParameters;
  String? lastScreenName;

  @override
  NavigationType? navigationFor({
    required Map<String, String> parameters,
    String? screenName,
  }) {
    lastParameters = parameters;
    lastScreenName = screenName;

    return Push(
      analyticsIdentifiable: AnalyticsIdentifiable(
        screenName: screenName ?? 'FallbackScreen',
        builder: (context) => Container(),
      ),
    );
  }
}

void main() {
  group('NavigationType Tests', () {
    testWidgets('Push adds page to navigation stack', (tester) async {
      final push = Push(
        analyticsIdentifiable: _createAnalytics((context) => Container()),
      );
      final currentStack = <ViewNavigationType>[];

      final newStack = push.navigationStackFrom(currentStack);

      expect(newStack.length, 1);
      expect(newStack.first, push);
    });

    testWidgets('Push preserves existing stack', (tester) async {
      final existingPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Page1',
        ),
      );
      final newPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Page2',
        ),
      );
      final currentStack = [existingPage];

      final newStack = newPage.navigationStackFrom(currentStack);

      expect(newStack.length, 2);
      expect(newStack[0], existingPage);
      expect(newStack[1], newPage);
    });

    testWidgets(
      'Present adds page to navigation stack with fullscreen dialog',
      (tester) async {
        final present = Present(
          analyticsIdentifiable: _createAnalytics((context) => Container()),
        );
        final currentStack = <ViewNavigationType>[];

        final newStack = present.navigationStackFrom(currentStack);

        expect(newStack.length, 1);
        expect(newStack.first, present);

        // The fullscreen-dialog flag lives on the route the page builds, so
        // create it inside a real widget tree (MaterialPageRoute needs a
        // Navigator ancestor).
        late Route<dynamic> route;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                route = present.buildPage(context).createRoute(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(route, isA<MaterialPageRoute<dynamic>>());
        expect((route as MaterialPageRoute<dynamic>).fullscreenDialog, true);
      },
    );

    testWidgets(
      'PresentMultiple appends hidden pages and presents last as Present',
      (tester) async {
        final page1 = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'Page1',
          ),
        );
        final hidden1 = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'Hidden1',
          ),
        );
        final hidden2 = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'Hidden2',
          ),
        );

        final presentMultiple = PresentMultiple(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'Presented',
          ),
          hiddenPages: [hidden1, hidden2],
        );

        final newStack = presentMultiple.navigationStackFrom([page1]);

        expect(newStack.length, 4);
        expect(newStack[0], page1);
        expect(newStack[1], hidden1);
        expect(newStack[2], hidden2);
        expect(newStack[3], isA<Present>());

        final presented = newStack.last as Present;
        expect(presented.screenName, 'Presented');

        late Route<dynamic> route;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                route = presented.buildPage(context).createRoute(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(route, isA<MaterialPageRoute<dynamic>>());
        expect((route as MaterialPageRoute<dynamic>).fullscreenDialog, true);
      },
    );

    testWidgets('Dismiss removes last page from stack', (tester) async {
      const dismiss = Dismiss();
      final page1 = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Page1',
        ),
      );
      final page2 = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Page2',
        ),
      );
      final currentStack = [page1, page2];

      final newStack = dismiss.navigationStackFrom(currentStack);

      expect(newStack.length, 1);
      expect(newStack.first, page1);
    });

    testWidgets('Dismiss handles empty stack gracefully', (tester) async {
      const dismiss = Dismiss();
      final currentStack = <ViewNavigationType>[];

      final newStack = dismiss.navigationStackFrom(currentStack);

      expect(newStack.length, 0);
      expect(newStack, isEmpty);
    });

    testWidgets('PopTo pops back to first match from top', (tester) async {
      final page1 = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'A',
        ),
      );
      final page2 = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'B',
        ),
      );
      final page3 = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'A',
        ),
      );
      final currentStack = [page1, page2, page3];

      const popToA = PopTo('A');
      final newStack = popToA.navigationStackFrom(currentStack);

      // The first match from the top is the last 'A' (page3),
      // so the stack is unchanged.
      expect(newStack.length, 3);
      expect(newStack.last.screenName, 'A');

      const popToB = PopTo('B');
      final newStack2 = popToB.navigationStackFrom(currentStack);
      expect(newStack2.length, 2);
      expect(newStack2.last.screenName, 'B');
    });

    testWidgets('PopTo is no-op when screenName not found', (tester) async {
      final page1 = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Page1',
        ),
      );
      final page2 = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Page2',
        ),
      );
      final currentStack = [page1, page2];

      const popTo = PopTo('DoesNotExist');
      final newStack = popTo.navigationStackFrom(currentStack);

      expect(newStack, currentStack);
    });

    testWidgets('ReplaceStack replaces entire stack with new page)', (
      tester,
    ) async {
      final replace = ReplaceStack(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Replace',
        ),
        animationType: const ReplaceAnimationTypePush(),
      );
      final page1 = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Page1',
        ),
      );
      final page2 = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Page2',
        ),
      );
      final currentStack = [page1, page2];

      final newStack = replace.navigationStackFrom(currentStack);

      expect(newStack.length, 1);
      expect(newStack.first.screenName, 'Replace');
    });

    testWidgets('ReplaceTop replaces the first page', (
      tester,
    ) async {
      final replace = ReplaceTop(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Replace',
        ),
        animationType: const ReplaceAnimationTypePush(),
      );
      final page1 = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Page1',
        ),
      );
      final page2 = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Page2',
        ),
      );
      final currentStack = [page1, page2];

      final newStack = replace.navigationStackFrom(currentStack);

      expect(newStack.length, 2);
      expect(newStack.last.screenName, 'Replace');
    });

    testWidgets('ReplaceTop respects animationType parameter', (tester) async {
      final replaceAnimated = ReplaceTop(
        analyticsIdentifiable: _createAnalytics((context) => Container()),
        animationType: const ReplaceAnimationTypePush(),
      );
      final replaceNotAnimated = ReplaceTop(
        analyticsIdentifiable: _createAnalytics((context) => Container()),
        animationType: const ReplaceAnimationTypeNone(),
      );

      expect(replaceAnimated.animated, true);
      expect(replaceNotAnimated.animated, false);

      final animatedPage = replaceAnimated.buildPage(mockContext);
      final notAnimatedPage = replaceNotAnimated.buildPage(mockContext);

      expect(animatedPage, isA<MaterialPage<dynamic>>());
      expect(notAnimatedPage, isA<NoAnimationPage<dynamic>>());
    });

    testWidgets('ReplaceTop defaults to animated=true', (tester) async {
      final replace = ReplaceTop(
        analyticsIdentifiable: _createAnalytics((context) => Container()),
        animationType: const ReplaceAnimationTypePush(),
      );

      expect(replace.animated, true);
      final page = replace.buildPage(mockContext);
      expect(page, isA<MaterialPage<dynamic>>());
    });

    testWidgets('PushMultiple adds hidden pages and main page', (tester) async {
      final hiddenPage1 = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Hidden1',
        ),
      );
      final hiddenPage2 = Present(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Hidden2',
        ),
      );
      final pushMultiple = PushMultiple(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Main',
        ),
        hiddenPages: [hiddenPage1, hiddenPage2],
      );
      final existingPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Existing',
        ),
      );
      final currentStack = [existingPage];

      final newStack = pushMultiple.navigationStackFrom(currentStack);

      expect(newStack.length, 4);
      expect(newStack[0], existingPage);
      expect(newStack[1], hiddenPage1);
      expect(newStack[2], hiddenPage2);
      expect(newStack[3], isA<Push>()); // The main page is added as a Push
    });

    testWidgets('ViewNavigationType generates consistent keys', (tester) async {
      Widget builder(BuildContext _) => Container();
      final analytics = _createAnalytics(builder, 'SamePage');

      final page1 = Push(analyticsIdentifiable: analytics);
      final page2 = Push(analyticsIdentifiable: analytics);

      expect(page1.key, page2.key);

      final differentPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => const Text('Different'),
          'DifferentPage',
        ),
      );
      expect(page1.key, isNot(differentPage.key));
    });

    testWidgets('ViewNavigationType buildPage creates MaterialPage', (
      tester,
    ) async {
      final push = Push(
        analyticsIdentifiable: _createAnalytics((context) => Container()),
      );
      final page = push.buildPage(mockContext);

      expect(page, isA<MaterialPage<dynamic>>());
      expect(page.key, push.key);
    });

    testWidgets('ViewNavigationType defaults to animated=true', (tester) async {
      final push = Push(
        analyticsIdentifiable: _createAnalytics((context) => Container()),
      );

      expect(push.animated, true);
    });

    testWidgets('ViewNavigationType buildPage returns animated page when '
        'animated=true', (tester) async {
      final push = Push(
        analyticsIdentifiable: _createAnalytics((context) => Container()),
      );
      final page = push.buildPage(mockContext);

      expect(page, isA<MaterialPage<dynamic>>());
      expect(page, isNot(isA<NoAnimationPage<dynamic>>()));
    });

    testWidgets('ViewNavigationType buildPage returns NoAnimationPage when '
        'animated=false', (tester) async {
      final push = Push(
        analyticsIdentifiable: _createAnalytics((context) => Container()),
        animated: false,
      );
      final page = push.buildPage(mockContext);

      expect(page, isA<NoAnimationPage<dynamic>>());
      expect(page.key, push.key);
    });

    testWidgets('Present respects animated parameter', (tester) async {
      final presentAnimated = Present(
        analyticsIdentifiable: _createAnalytics((context) => Container()),
      );
      final presentNotAnimated = Present(
        analyticsIdentifiable: _createAnalytics((context) => Container()),
        animated: false,
      );

      expect(presentAnimated.animated, true);
      expect(presentNotAnimated.animated, false);

      final animatedPage = presentAnimated.buildPage(mockContext);
      final notAnimatedPage = presentNotAnimated.buildPage(mockContext);

      // animated=true takes the buildAnimatedPage path (a real animated
      // page, not the no-animation fallback).
      expect(animatedPage, isNot(isA<NoAnimationPage<dynamic>>()));
      expect(notAnimatedPage, isA<NoAnimationPage<dynamic>>());
    });

    testWidgets('Present buildAnimatedPage creates fullscreenDialog', (
      tester,
    ) async {
      final present = Present(
        analyticsIdentifiable: _createAnalytics((context) => Container()),
      );

      late Route<dynamic> route;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              route = present.buildPage(context).createRoute(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(route, isA<MaterialPageRoute<dynamic>>());
      expect((route as MaterialPageRoute<dynamic>).fullscreenDialog, true);
    });

    testWidgets(
      'ReplaceStack respects animationType parameter',
      (tester) async {
        final replaceAnimated = ReplaceStack(
          analyticsIdentifiable: _createAnalytics((context) => Container()),
          animationType: const ReplaceAnimationTypePush(),
        );
        final replaceNotAnimated = ReplaceStack(
          analyticsIdentifiable: _createAnalytics((context) => Container()),
          animationType: const ReplaceAnimationTypeNone(),
        );

        expect(replaceAnimated.animated, true);
        expect(replaceNotAnimated.animated, false);

        final animatedPage = replaceAnimated.buildPage(mockContext);
        final notAnimatedPage = replaceNotAnimated.buildPage(mockContext);

        expect(animatedPage, isA<MaterialPage<dynamic>>());
        expect(notAnimatedPage, isA<NoAnimationPage<dynamic>>());
      },
    );

    testWidgets('ReplaceStack defaults to animated=true', (tester) async {
      final replace = ReplaceStack(
        analyticsIdentifiable: _createAnalytics((context) => Container()),
        animationType: const ReplaceAnimationTypePush(),
      );

      expect(replace.animated, true);
      final page = replace.buildPage(mockContext);
      expect(page, isA<MaterialPage<dynamic>>());
    });

    testWidgets('PushMultiple respects animated parameter', (tester) async {
      final pushMultiple = PushMultiple(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Main',
        ),
        hiddenPages: [],
        animated: false,
      );

      expect(pushMultiple.animated, false);

      final stack = pushMultiple.navigationStackFrom([]);
      final mainPage = stack.last;

      expect(mainPage, isA<Push>());
      expect((mainPage as Push).animated, false);
    });

    testWidgets('Push respects animated parameter when true', (tester) async {
      final push = Push(
        analyticsIdentifiable: _createAnalytics((context) => Container()),
      );

      expect(push.animated, true);
      final page = push.buildPage(mockContext);
      expect(page, isA<MaterialPage<dynamic>>());
      expect(page, isNot(isA<NoAnimationPage<dynamic>>()));
    });

    testWidgets('Push with swipeToDismissEnabled defaults animated to true', (
      tester,
    ) async {
      final push = Push(
        analyticsIdentifiable: _createAnalytics((context) => Container()),
      );

      expect(push.swipeToDismissEnabled, true);
      expect(push.animated, true);
    });

    testWidgets('Push animated parameter can be set to false', (tester) async {
      final push = Push(
        analyticsIdentifiable: _createAnalytics((context) => Container()),
        animated: false,
      );

      expect(push.animated, false);
      final page = push.buildPage(mockContext);
      expect(page, isA<NoAnimationPage<dynamic>>());
    });

    testWidgets('Swipe does not modify navigation stack', (tester) async {
      final swipe = Swipe(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'SwipePage',
        ),
      );
      final page1 = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Page1',
        ),
      );
      final page2 = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'Page2',
        ),
      );
      final currentStack = [page1, page2];

      final newStack = swipe.navigationStackFrom(currentStack);

      expect(newStack.length, 2);
      expect(newStack[0], page1);
      expect(newStack[1], page2);
      expect(newStack, currentStack);
    });

    testWidgets('Swipe handles empty stack', (tester) async {
      final swipe = Swipe(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'SwipePage',
        ),
      );
      final currentStack = <ViewNavigationType>[];

      final newStack = swipe.navigationStackFrom(currentStack);

      expect(newStack.length, 0);
      expect(newStack, isEmpty);
    });

    testWidgets('Swipe has correct screen name', (tester) async {
      final swipe = Swipe(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'SwipePage',
        ),
      );

      expect(swipe.screenName, 'SwipePage');
    });

    testWidgets('Swipe generates consistent keys', (tester) async {
      Widget builder(BuildContext _) => Container();
      final analytics = _createAnalytics(builder, 'SwipePage');

      final swipe1 = Swipe(analyticsIdentifiable: analytics);
      final swipe2 = Swipe(analyticsIdentifiable: analytics);

      expect(swipe1.key, swipe2.key);

      final differentSwipe = Swipe(
        analyticsIdentifiable: _createAnalytics(
          (context) => const Text('Different'),
          'DifferentSwipe',
        ),
      );
      expect(swipe1.key, isNot(differentSwipe.key));
    });
  });

  group('NavigationController Tests', () {
    late _CapturingSink sink;

    setUp(() {
      sink = _CapturingSink();
      sink.events.clear();
    });

    testWidgets('NavigationController initializes with initial navigation', (
      tester,
    ) async {
      final initialPage = Push(
        analyticsIdentifiable: _createAnalytics((context) => Container()),
      );
      final controller = NavigationController(
        initialPage,
        analyticsSink: sink,
      );

      final stack = controller.currentNavigationStack;
      expect(stack.length, 1);
      expect(stack.first, initialPage);
    });

    test('NavigationController navigate adds action to history', () async {
      final initialPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'HomePage',
        ),
      );
      var listenerCalled = false;
      final newPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'DetailsPage',
        ),
      );
      final controller = NavigationController(initialPage, analyticsSink: sink)
        ..addListener(() => listenerCalled = true)
        ..navigate(newPage);

      expect(listenerCalled, true);
      final stack = controller.currentNavigationStack;
      expect(stack.length, 2);
      expect(stack[1], newPage);

      // Validate analytics events
      await controller.flushAnalytics();
      expect(sink.events.length, 3);
      final firstEvent = sink.events.first;
      if (firstEvent is NavigationScreenEnterEvent) {
        expect(firstEvent.screenName, initialPage.screenName);
        expect(firstEvent.sourceScreen, 'root');
        expect(firstEvent.navigationMethod, 'initial');
        expect(firstEvent.breadcrumb, 'root:HomePage');
      } else {
        fail('First event is not a ScreenEnterEvent');
      }
      final secondEvent = sink.events[1];
      if (secondEvent is NavigationScreenExitEvent) {
        expect(secondEvent.screenName, initialPage.screenName);
        expect(secondEvent.destinationScreen, newPage.screenName);
        expect(secondEvent.exitMethod, 'Push');
      } else {
        fail('Second event is not a ScreenExitEvent');
      }
      final thirdEvent = sink.events[2];
      if (thirdEvent is NavigationScreenEnterEvent) {
        expect(thirdEvent.screenName, newPage.screenName);
        expect(thirdEvent.sourceScreen, initialPage.screenName);
        expect(thirdEvent.navigationMethod, 'Push');
        expect(thirdEvent.breadcrumb, 'root:HomePage > Push:DetailsPage');
      } else {
        fail('Third event is not a ScreenEnterEvent');
      }
    });

    test('NavigationController tracks Present analytics events', () async {
      final initialPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'HomePage',
        ),
      );
      final modalPage = Present(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'ModalPage',
        ),
      );
      final controller = NavigationController(
        initialPage,
        analyticsSink: sink,
      )..navigate(modalPage);
      await controller.flushAnalytics();

      expect(sink.events.length, 3);

      // Validate initial ScreenEnterEvent (from constructor)
      final initialEvent = sink.events.first;
      if (initialEvent is NavigationScreenEnterEvent) {
        expect(initialEvent.screenName, 'HomePage');
        expect(initialEvent.sourceScreen, 'root');
        expect(initialEvent.navigationMethod, 'initial');
      } else {
        fail('First event is not a ScreenEnterEvent');
      }

      // Validate ScreenExitEvent
      final exitEvent = sink.events[1];
      if (exitEvent is NavigationScreenExitEvent) {
        expect(exitEvent.screenName, 'HomePage');
        expect(exitEvent.destinationScreen, 'ModalPage');
        expect(exitEvent.exitMethod, 'Present');
      } else {
        fail('Second event is not a ScreenExitEvent');
      }

      // Validate ScreenEnterEvent
      final enterEvent = sink.events[2];
      if (enterEvent is NavigationScreenEnterEvent) {
        expect(enterEvent.screenName, 'ModalPage');
        expect(enterEvent.sourceScreen, 'HomePage');
        expect(enterEvent.navigationMethod, 'Present');
        expect(enterEvent.breadcrumb, 'root:HomePage > Present:ModalPage');
      } else {
        fail('Third event is not a ScreenEnterEvent');
      }
    });

    test('NavigationController tracks ReplaceTop analytics events', () async {
      final initialPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'HomePage',
        ),
      );
      final secondPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'DetailsPage',
        ),
      );
      final replacePage = ReplaceTop(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'ReplacePage',
        ),
        animationType: const ReplaceAnimationTypePush(),
      );

      final controller = NavigationController(
        initialPage,
        analyticsSink: sink,
      );

      sink.events.clear();

      controller
        ..navigate(secondPage)
        ..navigate(replacePage);

      await controller.flushAnalytics();

      expect(sink.events.length, 5);

      // Validate initial ScreenEnterEvent (from constructor)
      final initialEvent = sink.events[0];
      if (initialEvent is NavigationScreenEnterEvent) {
        expect(initialEvent.screenName, 'HomePage');
        expect(initialEvent.sourceScreen, 'root');
        expect(initialEvent.navigationMethod, 'initial');
        expect(initialEvent.breadcrumb, 'root:HomePage');
      } else {
        fail('First event is not a ScreenEnterEvent');
      }

      // First navigation: HomePage -> DetailsPage
      final firstExitEvent = sink.events[1];
      if (firstExitEvent is NavigationScreenExitEvent) {
        expect(firstExitEvent.screenName, 'HomePage');
        expect(firstExitEvent.destinationScreen, 'DetailsPage');
        expect(firstExitEvent.exitMethod, 'Push');
      } else {
        fail('Second event is not a ScreenExitEvent');
      }

      final firstEnterEvent = sink.events[2];
      if (firstEnterEvent is NavigationScreenEnterEvent) {
        expect(firstEnterEvent.screenName, 'DetailsPage');
        expect(firstEnterEvent.sourceScreen, 'HomePage');
        expect(firstEnterEvent.navigationMethod, 'Push');
        expect(firstEnterEvent.breadcrumb, 'root:HomePage > Push:DetailsPage');
      } else {
        fail('Third event is not a ScreenEnterEvent');
      }

      // Second navigation: DetailsPage -> ReplacePage (ReplaceTop)
      final secondExitEvent = sink.events[3];
      if (secondExitEvent is NavigationScreenExitEvent) {
        expect(secondExitEvent.screenName, 'DetailsPage');
        expect(secondExitEvent.destinationScreen, 'ReplacePage');
        expect(secondExitEvent.exitMethod, 'ReplaceTop');
      } else {
        fail('Fourth event is not a ScreenExitEvent');
      }

      final secondEnterEvent = sink.events[4];
      if (secondEnterEvent is NavigationScreenEnterEvent) {
        expect(secondEnterEvent.screenName, 'ReplacePage');
        expect(secondEnterEvent.sourceScreen, 'DetailsPage');
        expect(secondEnterEvent.navigationMethod, 'ReplaceTop');
        expect(
          secondEnterEvent.breadcrumb,
          'root:HomePage > Push:DetailsPage > ReplaceTop:ReplacePage',
        );
      } else {
        fail('Fifth event is not a ScreenEnterEvent');
      }
    });

    test('NavigationController tracks Dismiss analytics events', () async {
      final initialPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'HomePage',
        ),
      );
      final secondPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'DetailsPage',
        ),
      );
      final controller = NavigationController(
        initialPage,
        analyticsSink: sink,
      );

      sink.events.clear();

      controller
        ..navigate(secondPage)
        ..navigate(const Dismiss());

      await controller.flushAnalytics();

      expect(sink.events.length, 5);

      // Validate initial ScreenEnterEvent (from constructor)
      final initialEvent = sink.events[0];
      if (initialEvent is NavigationScreenEnterEvent) {
        expect(initialEvent.screenName, 'HomePage');
        expect(initialEvent.sourceScreen, 'root');
        expect(initialEvent.navigationMethod, 'initial');
        expect(initialEvent.breadcrumb, 'root:HomePage');
      } else {
        fail('First event is not a ScreenEnterEvent');
      }

      // First navigation: HomePage -> DetailsPage
      final firstExitEvent = sink.events[1];
      if (firstExitEvent is NavigationScreenExitEvent) {
        expect(firstExitEvent.screenName, 'HomePage');
        expect(firstExitEvent.destinationScreen, 'DetailsPage');
        expect(firstExitEvent.exitMethod, 'Push');
      } else {
        fail('Second event is not a ScreenExitEvent');
      }

      final firstEnterEvent = sink.events[2];
      if (firstEnterEvent is NavigationScreenEnterEvent) {
        expect(firstEnterEvent.screenName, 'DetailsPage');
        expect(firstEnterEvent.sourceScreen, 'HomePage');
        expect(firstEnterEvent.navigationMethod, 'Push');
        expect(firstEnterEvent.breadcrumb, 'root:HomePage > Push:DetailsPage');
      } else {
        fail('Third event is not a ScreenEnterEvent');
      }

      // Second navigation: DetailsPage -> HomePage (Dismiss)
      final secondExitEvent = sink.events[3];
      if (secondExitEvent is NavigationScreenExitEvent) {
        expect(secondExitEvent.screenName, 'DetailsPage');
        expect(secondExitEvent.destinationScreen, 'HomePage');
        expect(secondExitEvent.exitMethod, 'Dismiss');
      } else {
        fail('Fourth event is not a ScreenExitEvent');
      }

      final secondEnterEvent = sink.events[4];
      if (secondEnterEvent is NavigationScreenEnterEvent) {
        expect(secondEnterEvent.screenName, 'HomePage');
        expect(secondEnterEvent.sourceScreen, 'DetailsPage');
        expect(secondEnterEvent.navigationMethod, 'Dismiss');
        expect(
          secondEnterEvent.breadcrumb,
          'root:HomePage > Push:DetailsPage > Dismiss',
        );
      } else {
        fail('Fifth event is not a ScreenEnterEvent');
      }
    });

    test('NavigationController tracks PopTo analytics events', () async {
      final initialPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'HomePage',
        ),
      );
      final secondPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'DetailsPage',
        ),
      );
      final thirdPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'MoreDetailsPage',
        ),
      );
      final controller = NavigationController(
        initialPage,
        analyticsSink: sink,
      );

      sink.events.clear();

      controller
        ..navigate(secondPage)
        ..navigate(thirdPage)
        ..navigate(const PopTo('HomePage'));

      await controller.flushAnalytics();

      // Push, Push, PopTo => 6 events (exit+enter each), plus initial enter.
      expect(sink.events.length, 7);

      // Last exit should go from MoreDetailsPage -> HomePage via PopTo
      final exitEvent = sink.events[5];
      if (exitEvent is NavigationScreenExitEvent) {
        expect(exitEvent.screenName, 'MoreDetailsPage');
        expect(exitEvent.destinationScreen, 'HomePage');
        expect(exitEvent.exitMethod, 'PopTo');
      } else {
        fail('Expected ScreenExitEvent');
      }

      // Last enter should be HomePage
      final enterEvent = sink.events[6];
      if (enterEvent is NavigationScreenEnterEvent) {
        expect(enterEvent.screenName, 'HomePage');
        expect(enterEvent.sourceScreen, 'MoreDetailsPage');
        expect(enterEvent.navigationMethod, 'PopTo');
        expect(
          enterEvent.breadcrumb,
          'root:HomePage > Push:DetailsPage > Push:MoreDetailsPage'
          ' > PopTo:HomePage',
        );
      } else {
        fail('Expected ScreenEnterEvent');
      }
    });

    test('NavigationController tracks Swipe analytics events', () async {
      final initialPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'HomePage',
        ),
      );
      final secondPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'DetailsPage',
        ),
      );
      final swipe = Swipe(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'SwipePage',
        ),
      );
      final controller = NavigationController(
        initialPage,
        analyticsSink: sink,
      );

      sink.events.clear();

      controller
        ..navigate(secondPage)
        ..navigate(swipe);

      await controller.flushAnalytics();

      expect(sink.events.length, 5);

      // Validate initial ScreenEnterEvent (from constructor)
      final initialEvent = sink.events[0];
      if (initialEvent is NavigationScreenEnterEvent) {
        expect(initialEvent.screenName, 'HomePage');
        expect(initialEvent.sourceScreen, 'root');
        expect(initialEvent.navigationMethod, 'initial');
        expect(initialEvent.breadcrumb, 'root:HomePage');
      } else {
        fail('First event is not a ScreenEnterEvent');
      }

      // First navigation: HomePage -> DetailsPage
      final firstExitEvent = sink.events[1];
      if (firstExitEvent is NavigationScreenExitEvent) {
        expect(firstExitEvent.screenName, 'HomePage');
        expect(firstExitEvent.destinationScreen, 'DetailsPage');
        expect(firstExitEvent.exitMethod, 'Push');
      } else {
        fail('Second event is not a ScreenExitEvent');
      }

      final firstEnterEvent = sink.events[2];
      if (firstEnterEvent is NavigationScreenEnterEvent) {
        expect(firstEnterEvent.screenName, 'DetailsPage');
        expect(firstEnterEvent.sourceScreen, 'HomePage');
        expect(firstEnterEvent.navigationMethod, 'Push');
        expect(firstEnterEvent.breadcrumb, 'root:HomePage > Push:DetailsPage');
      } else {
        fail('Third event is not a ScreenEnterEvent');
      }

      // Second navigation: DetailsPage -> SwipePage(Swipe doesn't change stack)
      final secondExitEvent = sink.events[3];
      if (secondExitEvent is NavigationScreenExitEvent) {
        expect(secondExitEvent.screenName, 'DetailsPage');
        expect(secondExitEvent.destinationScreen, 'SwipePage');
        expect(secondExitEvent.exitMethod, 'Swipe');
      } else {
        fail('Fourth event is not a ScreenExitEvent');
      }

      final secondEnterEvent = sink.events[4];
      if (secondEnterEvent is NavigationScreenEnterEvent) {
        expect(secondEnterEvent.screenName, 'SwipePage');
        expect(secondEnterEvent.sourceScreen, 'DetailsPage');
        expect(secondEnterEvent.navigationMethod, 'Swipe');
        expect(
          secondEnterEvent.breadcrumb,
          'root:HomePage > Push:DetailsPage > Swipe:SwipePage',
        );
      } else {
        fail('Fifth event is not a ScreenEnterEvent');
      }
    });

    test(
      'NavigationController tracks Swipe in complex navigation flow',
      () async {
        final initialPage = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'HomePage',
          ),
        );
        final secondPage = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'DetailsPage',
          ),
        );
        final swipe1 = Swipe(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'SwipePage1',
          ),
        );
        final swipe2 = Swipe(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'SwipePage2',
          ),
        );

        final controller = NavigationController(
          initialPage,
          analyticsSink: sink,
        );

        sink.events.clear();

        controller
          ..navigate(secondPage)
          ..navigate(swipe1)
          ..navigate(swipe2)
          ..navigate(const Dismiss());

        await controller.flushAnalytics();

        expect(sink.events.length, 9);

        // Validate breadcrumb after multiple swipes
        final lastEnterEvent = sink.events[8];
        if (lastEnterEvent is NavigationScreenEnterEvent) {
          expect(lastEnterEvent.screenName, 'HomePage');
          expect(lastEnterEvent.sourceScreen, 'SwipePage2');
          expect(lastEnterEvent.navigationMethod, 'Dismiss');
          expect(
            lastEnterEvent.breadcrumb,
            'root:HomePage > Push:DetailsPage > Swipe:SwipePage1'
            ' > Swipe:SwipePage2 > Dismiss',
          );
        } else {
          fail('Last event is not a ScreenEnterEvent');
        }
      },
    );

    test('NavigationController tracks screen time', () async {
      final initialPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'HomePage',
        ),
      );
      final secondPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'DetailsPage',
        ),
      );
      final controller = NavigationController(
        initialPage,
        analyticsSink: sink,
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      controller.navigate(secondPage);
      await controller.flushAnalytics();

      expect(sink.events.length, 3);

      // Validate initial ScreenEnterEvent (from constructor)
      final initialEvent = sink.events.first;
      if (initialEvent is NavigationScreenEnterEvent) {
        expect(initialEvent.screenName, 'HomePage');
        expect(initialEvent.sourceScreen, 'root');
        expect(initialEvent.navigationMethod, 'initial');
        expect(initialEvent.breadcrumb, 'root:HomePage');
      } else {
        fail('First event is not a ScreenEnterEvent');
      }

      // Validate ScreenExitEvent with screen time tracking
      final exitEvent = sink.events[1];
      if (exitEvent is NavigationScreenExitEvent) {
        expect(exitEvent.screenName, 'HomePage');
        expect(exitEvent.destinationScreen, 'DetailsPage');
        expect(exitEvent.exitMethod, 'Push');
        expect(exitEvent.timeSpent, isA<int>());
        expect(exitEvent.timeSpent, greaterThan(0));
      } else {
        fail('Second event is not a ScreenExitEvent');
      }

      // Validate ScreenEnterEvent
      final enterEvent = sink.events[2];
      if (enterEvent is NavigationScreenEnterEvent) {
        expect(enterEvent.screenName, 'DetailsPage');
        expect(enterEvent.sourceScreen, 'HomePage');
        expect(enterEvent.navigationMethod, 'Push');
        expect(enterEvent.breadcrumb, 'root:HomePage > Push:DetailsPage');
      } else {
        fail('Third event is not a ScreenEnterEvent');
      }
    });

    test('NavigationController handles multiple navigations', () async {
      final initialPage = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'HomePage',
        ),
      );
      final controller = NavigationController(initialPage, analyticsSink: sink)
        ..navigate(
          Push(
            analyticsIdentifiable: _createAnalytics(
              (context) => Container(),
              'SecondPage',
            ),
          ),
        )
        ..navigate(
          Present(
            analyticsIdentifiable: _createAnalytics(
              (context) => Container(),
              'PresentedPage',
            ),
          ),
        )
        ..navigate(const Dismiss());

      await controller.flushAnalytics();

      final stack = controller.currentNavigationStack;
      expect(stack.length, 2);

      expect(sink.events.length, 7);

      // Validate initial ScreenEnterEvent (from constructor)
      final initialEvent = sink.events[0];
      if (initialEvent is NavigationScreenEnterEvent) {
        expect(initialEvent.screenName, 'HomePage');
        expect(initialEvent.sourceScreen, 'root');
        expect(initialEvent.navigationMethod, 'initial');
        expect(initialEvent.breadcrumb, 'root:HomePage');
      } else {
        fail('First event is not a ScreenEnterEvent');
      }

      // First navigation: HomePage -> SecondPage
      final firstExitEvent = sink.events[1];
      if (firstExitEvent is NavigationScreenExitEvent) {
        expect(firstExitEvent.screenName, 'HomePage');
        expect(firstExitEvent.destinationScreen, 'SecondPage');
        expect(firstExitEvent.exitMethod, 'Push');
      } else {
        fail('Second event is not a ScreenExitEvent');
      }

      final firstEnterEvent = sink.events[2];
      if (firstEnterEvent is NavigationScreenEnterEvent) {
        expect(firstEnterEvent.screenName, 'SecondPage');
        expect(firstEnterEvent.sourceScreen, 'HomePage');
        expect(firstEnterEvent.navigationMethod, 'Push');
        expect(firstEnterEvent.breadcrumb, 'root:HomePage > Push:SecondPage');
      } else {
        fail('Third event is not a ScreenEnterEvent');
      }

      // Second navigation: SecondPage -> PresentedPage
      final secondExitEvent = sink.events[3];
      if (secondExitEvent is NavigationScreenExitEvent) {
        expect(secondExitEvent.screenName, 'SecondPage');
        expect(secondExitEvent.destinationScreen, 'PresentedPage');
        expect(secondExitEvent.exitMethod, 'Present');
      } else {
        fail('Fourth event is not a ScreenExitEvent');
      }

      final secondEnterEvent = sink.events[4];
      if (secondEnterEvent is NavigationScreenEnterEvent) {
        expect(secondEnterEvent.screenName, 'PresentedPage');
        expect(secondEnterEvent.sourceScreen, 'SecondPage');
        expect(secondEnterEvent.navigationMethod, 'Present');
        expect(
          secondEnterEvent.breadcrumb,
          'root:HomePage > Push:SecondPage > Present:PresentedPage',
        );
      } else {
        fail('Fifth event is not a ScreenEnterEvent');
      }

      // Third navigation: PresentedPage -> SecondPage (Dismiss)
      final thirdExitEvent = sink.events[5];
      if (thirdExitEvent is NavigationScreenExitEvent) {
        expect(thirdExitEvent.screenName, 'PresentedPage');
        expect(thirdExitEvent.destinationScreen, 'SecondPage');
        expect(thirdExitEvent.exitMethod, 'Dismiss');
      } else {
        fail('Sixth event is not a ScreenExitEvent');
      }

      final thirdEnterEvent = sink.events[6];
      if (thirdEnterEvent is NavigationScreenEnterEvent) {
        expect(thirdEnterEvent.screenName, 'SecondPage');
        expect(thirdEnterEvent.sourceScreen, 'PresentedPage');
        expect(thirdEnterEvent.navigationMethod, 'Dismiss');
        expect(
          thirdEnterEvent.breadcrumb,
          'root:HomePage > Push:SecondPage > Present:PresentedPage'
          ' > Dismiss',
        );
      } else {
        fail('Seventh event is not a ScreenEnterEvent');
      }
    });

    testWidgets(
      'NavigationController removePoppedPageIfNotUserInitiated works correctly',
      (tester) async {
        final initialPage = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => const Scaffold(body: Text('Page 1')),
            'Page1',
          ),
        );
        final controller = NavigationController(
          initialPage,
          analyticsSink: sink,
        );

        // Set up a proper widget tree to get a real BuildContext
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: NavigationConfig(
              controller: controller,
              featureProvider: const _NoopFeatureProvider(),
            ),
          ),
        );

        // Add a second page
        controller.navigate(
          Push(
            analyticsIdentifiable: _createAnalytics(
              (context) => const Scaffold(body: Text('Page 2')),
              'Page2',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify initial stack has 2 pages
        var stack = controller.currentNavigationStack;
        expect(stack.length, 2);

        // Simulate what happens when a page is popped by the system
        // This should add a Dismiss action to the history
        controller.removePoppedPageIfNotUserInitiated(null);

        // After adding Dismiss action, the stack should have 1 page
        stack = controller.currentNavigationStack;
        expect(stack.length, 1);
      },
    );

    testWidgets(
      'NavigationController does not remove page during user navigation',
      (tester) async {
        final initialPage = Push(
          analyticsIdentifiable: _createAnalytics((context) => Container()),
        );
        final controller =
            NavigationController(initialPage, analyticsSink: sink)
              ..navigate(
                Push(
                  analyticsIdentifiable: _createAnalytics(
                    (context) => Container(),
                  ),
                ),
              )
              ..navigate(
                Push(
                  analyticsIdentifiable: _createAnalytics(
                    (context) => Container(),
                  ),
                ),
              )
              ..removePoppedPageIfNotUserInitiated(null);

        final stack = controller.currentNavigationStack;
        expect(stack.length, 3);
      },
    );

    testWidgets('NavigationController handles empty stack in '
        'removePoppedPageIfNotUserInitiated', (tester) async {
      final initialPage = Push(
        analyticsIdentifiable: _createAnalytics((context) => Container()),
      );
      final controller = NavigationController(
        initialPage,
        analyticsSink: sink,
      )..removePoppedPageIfNotUserInitiated(null);

      final stack = controller.currentNavigationStack;
      expect(stack.length, 1);
    });

    test(
      'NavigationController ignores page removal from ReplaceStack operation',
      () {
        final homePage = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'HomePage',
          ),
        );
        final replacePage = ReplaceStack(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'ReplacePage',
          ),
          animationType: const ReplaceAnimationTypePush(),
        );

        final controller = NavigationController(
          homePage,
          analyticsSink: sink,
        )..navigate(replacePage);

        // Verify that Replace created the new stack
        var stack = controller.currentNavigationStack;
        expect(stack.length, 1);
        expect(stack.first.screenName, 'ReplacePage');

        // Simulate Flutter's Navigator removing the HomePage
        // This should be ignored because HomePage was marked for removal
        final removed = controller.removePoppedPageIfNotUserInitiated(
          'HomePage',
        );

        // Should return false (removal was ignored)
        expect(removed, false);

        // Stack should remain unchanged
        stack = controller.currentNavigationStack;
        expect(stack.length, 1);
        expect(stack.first.screenName, 'ReplacePage');
      },
    );

    test(
      'NavigationController handles ReplaceStack with multiple pages to remove',
      () {
        final page1 = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'Page1',
          ),
        );
        final page2 = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'Page2',
          ),
        );
        final replacePage = ReplaceStack(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'ReplacePage',
          ),
          animationType: const ReplaceAnimationTypePush(),
        );

        final controller =
            NavigationController(
                page1,
                analyticsSink: sink,
              )
              ..navigate(page2)
              ..navigate(replacePage);

        // Both Page1 and Page2 should be marked to ignore
        final removed1 = controller.removePoppedPageIfNotUserInitiated('Page1');
        expect(removed1, false);

        final removed2 = controller.removePoppedPageIfNotUserInitiated('Page2');
        expect(removed2, false);

        // Stack should remain unchanged after ignoring the removals
        final stack = controller.currentNavigationStack;
        expect(stack.length, 1);
        expect(stack.first.screenName, 'ReplacePage');
      },
    );

    test(
      'NavigationController does not ignore non-Replace page removals',
      () {
        final homePage = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'HomePage',
          ),
        );
        final replacePage = ReplaceStack(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'ReplacePage',
          ),
          animationType: const ReplaceAnimationTypePush(),
        );

        final controller = NavigationController(
          homePage,
          analyticsSink: sink,
        )..navigate(replacePage);

        // Process HomePage removal from Replace (should be ignored)
        var removed = controller.removePoppedPageIfNotUserInitiated('HomePage');
        expect(removed, false);

        // Try to remove a page that was NOT part of Replace operation
        // This should not be ignored (but will return false due to stack size)
        removed = controller.removePoppedPageIfNotUserInitiated(
          'SomeOtherPage',
        );
        expect(removed, false); // Stack has only 1 page, so can't remove

        // Verify the ignore list only affects pages from the Replace operation
        final stack = controller.currentNavigationStack;
        expect(stack.length, 1);
        expect(stack.first.screenName, 'ReplacePage');
      },
    );

    test(
      'NavigationController clears ignore list as pages are processed',
      () {
        final page1 = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'Page1',
          ),
        );
        final page2 = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'Page2',
          ),
        );
        final replacePage = ReplaceStack(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'ReplacePage',
          ),
          animationType: const ReplaceAnimationTypePush(),
        );

        final controller =
            NavigationController(
                page1,
                analyticsSink: sink,
              )
              ..navigate(page2)
              ..navigate(replacePage);

        // Process Page1 removal
        var removed1 = controller.removePoppedPageIfNotUserInitiated('Page1');
        expect(removed1, false);

        // Process Page2 removal
        final removed2 = controller.removePoppedPageIfNotUserInitiated('Page2');
        expect(removed2, false);

        // Try to process Page1 removal again (should not be ignored anymore)
        // Since we're not in user navigation and stack has only 1 page,
        // it returns false
        removed1 = controller.removePoppedPageIfNotUserInitiated('Page1');
        expect(removed1, false);
      },
    );

    test(
      'NavigationController Replace with hiddenPages ignores all removed pages',
      () {
        final homePage = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'HomePage',
          ),
        );
        final landingPage = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'LandingPage',
          ),
        );
        final replacePage = ReplaceStack(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'AccessChatPage',
          ),
          hiddenPages: [landingPage],
          animationType: const ReplaceAnimationTypePush(),
        );

        final controller = NavigationController(
          homePage,
          analyticsSink: sink,
        )..navigate(replacePage);

        // Verify the stack has 2 pages (hidden + main)
        var stack = controller.currentNavigationStack;
        expect(stack.length, 2);
        expect(stack[0].screenName, 'LandingPage');
        expect(stack[1].screenName, 'AccessChatPage');

        // HomePage removal should be ignored
        final removed = controller.removePoppedPageIfNotUserInitiated(
          'HomePage',
        );
        expect(removed, false);

        // Stack should remain unchanged
        stack = controller.currentNavigationStack;
        expect(stack.length, 2);
      },
    );

    test(
      'NavigationController ignores page removal from ReplaceTop operation',
      () {
        final page1 = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'Page1',
          ),
        );
        final page2 = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'Page2',
          ),
        );
        final replacePage = ReplaceTop(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'ReplacePage',
          ),
          animationType: const ReplaceAnimationTypePush(),
        );

        final controller =
            NavigationController(
                page1,
                analyticsSink: sink,
              )
              ..navigate(page2)
              ..navigate(replacePage);

        // Verify that ReplaceTop replaced the top page
        var stack = controller.currentNavigationStack;
        expect(stack.length, 2);
        expect(stack[0].screenName, 'Page1');
        expect(stack[1].screenName, 'ReplacePage');

        // Simulate Flutter's Navigator removing Page2
        // This should be ignored because Page2 was marked for removal
        final removed = controller.removePoppedPageIfNotUserInitiated(
          'Page2',
        );

        // Should return false (removal was ignored)
        expect(removed, false);

        // Stack should remain unchanged
        stack = controller.currentNavigationStack;
        expect(stack.length, 2);
        expect(stack[0].screenName, 'Page1');
        expect(stack[1].screenName, 'ReplacePage');
      },
    );

    test(
      'NavigationController handles ReplaceTop with multiple replaces',
      () {
        final page1 = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'Page1',
          ),
        );
        final page2 = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'Page2',
          ),
        );
        final replacePage1 = ReplaceTop(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'ReplacePage1',
          ),
          animationType: const ReplaceAnimationTypePush(),
        );
        final replacePage2 = ReplaceTop(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'ReplacePage2',
          ),
          animationType: const ReplaceAnimationTypePush(),
        );

        final controller =
            NavigationController(
                page1,
                analyticsSink: sink,
              )
              ..navigate(page2)
              ..navigate(replacePage1);

        // First replacement should work
        final removed1 = controller.removePoppedPageIfNotUserInitiated('Page2');
        expect(removed1, false);

        var stack = controller.currentNavigationStack;
        expect(stack.length, 2);
        expect(stack[1].screenName, 'ReplacePage1');

        // Second replacement
        controller.navigate(replacePage2);
        final removed2 = controller.removePoppedPageIfNotUserInitiated(
          'ReplacePage1',
        );
        expect(removed2, false);

        // Stack should have the second replacement
        stack = controller.currentNavigationStack;
        expect(stack.length, 2);
        expect(stack[0].screenName, 'Page1');
        expect(stack[1].screenName, 'ReplacePage2');
      },
    );

    test(
      'NavigationController compresses history but keeps breadcrumb',
      () async {
        final initialPage = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'Initial',
          ),
        );
        final controller = NavigationController(
          initialPage,
          analyticsSink: sink,
        );

        for (var i = 0; i < 10; i++) {
          controller
            ..navigate(
              Push(
                analyticsIdentifiable: _createAnalytics(
                  (context) => Container(),
                  'Page$i',
                ),
              ),
            )
            ..navigate(const Dismiss());
        }

        final stack = controller.currentNavigationStack;
        expect(stack.length, 1);

        controller.navigate(
          Push(
            analyticsIdentifiable: _createAnalytics(
              (context) => Container(),
              'Page10',
            ),
          ),
        );

        final newStack = controller.currentNavigationStack;
        expect(newStack.length, 2);

        await controller.flushAnalytics();

        // Validate compressed history
        final lastEvent = sink.events.last;
        if (lastEvent is NavigationScreenEnterEvent) {
          expect(lastEvent.screenName, 'Page10');
          expect(lastEvent.sourceScreen, 'Initial');
          expect(lastEvent.navigationMethod, 'Push');
          expect(
            lastEvent.breadcrumb,
            'root:Initial > Push:Page0 > Dismiss > Push:Page1 > Dismiss'
            ' > Push:Page2 > Dismiss > Push:Page3 > Dismiss > Push:Page4'
            ' > Dismiss > Push:Page5 > Dismiss > Push:Page6 > Dismiss'
            ' > Push:Page7 > Dismiss > Push:Page8 > Dismiss > Push:Page9'
            ' > Dismiss > Push:Page10',
          );
        } else {
          fail('Last event is not a ScreenEnterEvent');
        }
      },
    );
  });

  group('NavigationConfig Tests', () {
    late _CapturingSink sink;

    setUp(() {
      sink = _CapturingSink();
    });

    test('NavigationConfig creates proper router configuration', () async {
      final controller = NavigationController(
        Push(analyticsIdentifiable: _createAnalytics((context) => Container())),
        analyticsSink: sink,
      );
      final config = NavigationConfig(
        controller: controller,
        featureProvider: const _NoopFeatureProvider(),
      );

      expect(config.routerDelegate, isA<NavigationRouterDelegate>());
      expect(
        config.routeInformationParser,
        isA<NavigationRouteInformationParser>(),
      );
      expect(
        config.routeInformationProvider,
        isA<PlatformRouteInformationProvider>(),
      );
    });
  });

  group('NavigationRouteInformationParser Tests', () {
    test(
      'parseRouteInformation returns no navigation for unknown feature',
      () async {
        final parser = NavigationRouteInformationParser(
          featureProvider: const _NoopFeatureProvider(),
        );
        final routeInfo = RouteInformation(uri: Uri.parse('/test'));

        final result = await parser.parseRouteInformation(routeInfo);
        expect(result, isA<RouteConfig>());
        final config = result as RouteConfig;
        expect(config.navigationType, isNot(isA<NavigationType>()));
      },
    );

    test(
      'parseRouteInformation returns NavigationType for known feature',
      () async {
        final featureRoute = _CapturingFeatureRoute();
        final parser = NavigationRouteInformationParser(
          featureProvider: _TestFeatureProvider({'feature': featureRoute}),
        );
        final routeInfo = RouteInformation(
          uri: Uri.parse('/feature/MyScreen?foo=bar&x=1'),
        );

        final result = await parser.parseRouteInformation(routeInfo);

        expect(result, isA<RouteConfig>());
        final config = result as RouteConfig;
        expect(config.navigationType, isA<NavigationType>());
        expect(featureRoute.lastParameters, {'foo': 'bar', 'x': '1'});
        expect(featureRoute.lastScreenName, 'MyScreen');

        final navigation = config.navigationType as NavigationType;
        expect(navigation, isA<Push>());
        expect((navigation as Push).screenName, 'MyScreen');
      },
    );

    test(
      'restoreRouteInformation builds a URL from the top screen name',
      () {
        final parser = NavigationRouteInformationParser(
          featureProvider: const _NoopFeatureProvider(),
        );
        final config = (
          requiredPriorNavigation: const <String>[],
          navigationType: Push(
            analyticsIdentifiable: _createAnalytics(
              (context) => Container(),
              'ProductDetails',
            ),
          ),
          branchScreenName: null,
        );

        final info = parser.restoreRouteInformation(config);

        expect(info, isNotNull);
        expect(info!.uri.pathSegments.last, 'ProductDetails');
      },
    );

    test('restoreRouteInformation returns null for non-RouteConfig', () {
      final parser = NavigationRouteInformationParser(
        featureProvider: const _NoopFeatureProvider(),
      );
      expect(parser.restoreRouteInformation(Object()), isNull);
    });

    test(
      'restoreRouteInformation round-trips through parse for known feature',
      () async {
        final featureRoute = _CapturingFeatureRoute();
        final parser = NavigationRouteInformationParser(
          featureProvider: _TestFeatureProvider({
            'ProductDetails': featureRoute,
          }),
        );
        final config = (
          requiredPriorNavigation: const <String>[],
          navigationType: Push(
            analyticsIdentifiable: _createAnalytics(
              (context) => Container(),
              'ProductDetails',
            ),
          ),
          branchScreenName: null,
        );

        final restored = parser.restoreRouteInformation(config)!;
        expect(restored.uri.pathSegments.last, 'ProductDetails');

        // Re-parsing the restored URI must resolve via the FeatureProvider:
        // the serialized screen name becomes the feature lookup key.
        final reparsed = await parser.parseRouteInformation(restored);
        expect(reparsed, isA<RouteConfig>());
        expect((reparsed as RouteConfig).navigationType, isA<NavigationType>());
      },
    );
  });

  group('NavigationRouterDelegate Tests', () {
    late _CapturingSink sink;

    setUp(() {
      sink = _CapturingSink();
    });

    testWidgets(
      'NavigationRouterDelegate builds Navigator with correct pages',
      (tester) async {
        final controller = NavigationController(
          Push(
            analyticsIdentifiable: _createAnalytics((context) => Container()),
          ),
          analyticsSink: sink,
        );
        final delegate = NavigationRouterDelegate(
          controller,
          routeInformationParser: NavigationRouteInformationParser(
            featureProvider: const _NoopFeatureProvider(),
          ),
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: delegate,
            routeInformationParser: NavigationRouteInformationParser(
              featureProvider: const _NoopFeatureProvider(),
            ),
          ),
        );

        expect(find.byType(Navigator), findsOneWidget);
      },
    );

    test(
      'currentConfiguration reports the top-of-stack screen for the URL bar',
      () {
        final controller = NavigationController(
          Push(
            analyticsIdentifiable: _createAnalytics(
              (context) => Container(),
              'Home',
            ),
          ),
          analyticsSink: sink,
        );
        final delegate = NavigationRouterDelegate(
          controller,
          routeInformationParser: NavigationRouteInformationParser(
            featureProvider: const _NoopFeatureProvider(),
          ),
        );

        // Initial stack is just the home page.
        var config = delegate.currentConfiguration;
        expect(config, isNotNull);
        expect(
          (config!.navigationType as ViewNavigationType)
              .analyticsIdentifiable
              .screenName,
          'Home',
        );

        // Navigate to a second screen; currentConfiguration must track it.
        controller.navigate(
          Push(
            analyticsIdentifiable: _createAnalytics(
              (context) => Container(),
              'Details',
            ),
          ),
        );
        config = delegate.currentConfiguration;
        expect(config, isNotNull);
        expect(
          (config!.navigationType as ViewNavigationType)
              .analyticsIdentifiable
              .screenName,
          'Details',
        );
      },
    );

    test(
      'NavigationRouterDelegate notifies listeners when controller changes',
      () async {
        final controller = NavigationController(
          Push(
            analyticsIdentifiable: _createAnalytics((context) => Container()),
          ),
          analyticsSink: sink,
        );
        final delegate = NavigationRouterDelegate(
          controller,
          routeInformationParser: NavigationRouteInformationParser(
            featureProvider: const _NoopFeatureProvider(),
          ),
        );

        var listenerCalled = false;
        delegate.addListener(() => listenerCalled = true);

        controller.navigate(
          Push(
            analyticsIdentifiable: _createAnalytics((context) => Container()),
          ),
        );

        expect(listenerCalled, true);
      },
    );

    test('NavigationRouterDelegate disposes correctly', () async {
      final controller = NavigationController(
        Push(analyticsIdentifiable: _createAnalytics((context) => Container())),
        analyticsSink: sink,
      );
      final delegate = NavigationRouterDelegate(
        controller,
        routeInformationParser: NavigationRouteInformationParser(
          featureProvider: const _NoopFeatureProvider(),
        ),
      )..dispose();

      expect(delegate.notifyListeners, throwsA(isA<FlutterError>()));
    });
  });

  group('Integration Tests', () {
    late _CapturingSink sink;

    setUp(() {
      sink = _CapturingSink();
    });

    testWidgets('present awaits the popped result', (tester) async {
      final controller = NavigationController(
        Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => const Scaffold(body: Text('Home')),
            'Home',
          ),
        ),
        analyticsSink: sink,
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: NavigationConfig(
            controller: controller,
            featureProvider: const _NoopFeatureProvider(),
          ),
        ),
      );

      final presentFuture = controller.present<String>(
        Present(
          analyticsIdentifiable: AnalyticsIdentifiable(
            screenName: 'Picker',
            builder: (context) => Scaffold(
              // Use Builder so Navigator.pop targets the j_navigation
              // Navigator (the screen's own build context), not the root
              // navigator that owns the builder param.
              body: Builder(
                builder: (inner) => TextButton(
                  onPressed: () => Navigator.pop(inner, 'picked'),
                  child: const Text('pick'),
                ),
              ),
            ),
          ),
        ),
      );

      // Mount the presented page so its route (and its popped future) exist.
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();

      expect(await presentFuture, 'picked');
    });

    testWidgets('present resolves with null on a programmatic Dismiss', (
      tester,
    ) async {
      final controller = NavigationController(
        Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => const Scaffold(body: Text('Home')),
            'Home',
          ),
        ),
        analyticsSink: sink,
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: NavigationConfig(
            controller: controller,
            featureProvider: const _NoopFeatureProvider(),
          ),
        ),
      );

      final presentFuture = controller.present<String>(
        Present(
          analyticsIdentifiable: AnalyticsIdentifiable(
            screenName: 'Modal',
            builder: (context) => const Scaffold(body: Text('Modal')),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      // Dismiss programmatically — no pop result.
      controller.navigate(const Dismiss());
      await tester.pumpAndSettle();

      expect(await presentFuture, isNull);
    });

    testWidgets('Dismiss(result:) resolves present with the value', (
      tester,
    ) async {
      final controller = NavigationController(
        Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => const Scaffold(body: Text('Home')),
            'Home',
          ),
        ),
        analyticsSink: sink,
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: NavigationConfig(
            controller: controller,
            featureProvider: const _NoopFeatureProvider(),
          ),
        ),
      );

      final presentFuture = controller.present<String>(
        Present(
          analyticsIdentifiable: AnalyticsIdentifiable(
            screenName: 'Modal',
            builder: (context) => const Scaffold(body: Text('Modal')),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      // Dismiss with a result — the action-based equivalent of
      // Navigator.pop(context, 'picked').
      controller.navigate(const Dismiss(result: 'picked'));
      await tester.pumpAndSettle();

      expect(await presentFuture, 'picked');
    });

    testWidgets('Full navigation flow works correctly', (tester) async {
      final controller = NavigationController(
        Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => const Scaffold(body: Text('Page 1')),
            'Page1',
          ),
        ),
        analyticsSink: sink,
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: NavigationConfig(
            controller: controller,
            featureProvider: const _NoopFeatureProvider(),
          ),
        ),
      );

      expect(find.text('Page 1'), findsOneWidget);

      controller.navigate(
        Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => const Scaffold(body: Text('Page 2')),
            'Page2',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);

      controller.navigate(const Dismiss());
      await tester.pumpAndSettle();

      expect(find.text('Page 1'), findsOneWidget);
    });

    testWidgets('ReplaceStack navigation works in full flow', (tester) async {
      final controller = NavigationController(
        Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => const Scaffold(body: Text('Page 1')),
            'Page1',
          ),
        ),
        analyticsSink: sink,
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: NavigationConfig(
            controller: controller,
            featureProvider: const _NoopFeatureProvider(),
          ),
        ),
      );

      controller.navigate(
        Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => const Scaffold(body: Text('Page 2')),
            'Page2',
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.navigate(
        ReplaceStack(
          analyticsIdentifiable: _createAnalytics(
            (context) => const Scaffold(body: Text('Replaced')),
            'Replaced',
          ),
          animationType: const ReplaceAnimationTypePush(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Replaced'), findsOneWidget);
      expect(find.text('Page 1'), findsNothing);
      expect(find.text('Page 2'), findsNothing);
    });

    testWidgets('ReplaceTop navigation works in full flow', (tester) async {
      final controller = NavigationController(
        Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => const Scaffold(body: Text('Page 1')),
            'Page1',
          ),
        ),
        analyticsSink: sink,
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: NavigationConfig(
            controller: controller,
            featureProvider: const _NoopFeatureProvider(),
          ),
        ),
      );

      controller.navigate(
        Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => const Scaffold(body: Text('Page 2')),
            'Page2',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);

      controller.navigate(
        ReplaceTop(
          analyticsIdentifiable: _createAnalytics(
            (context) => const Scaffold(body: Text('Replaced')),
            'Replaced',
          ),
          animationType: const ReplaceAnimationTypePush(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Replaced'), findsOneWidget);
      expect(find.text('Page 1'), findsNothing);
      expect(find.text('Page 2'), findsNothing);
    });
  });

  group('ScreenTimeTracker Tests', () {
    late ScreenTimeTracker tracker;

    setUp(() {
      tracker = ScreenTimeTracker();
    });

    test('records screen enter and exit with Stopwatch', () async {
      const screenName = 'TestScreen';

      // Record screen enter
      tracker.recordScreenEnter(screenName);

      // Wait a small amount to ensure some time passes
      await Future<void>.delayed(const Duration(seconds: 2));

      // Record screen exit
      final timeSpent = tracker.recordScreenExit(screenName);

      expect(timeSpent, isNotNull);
      expect(timeSpent, greaterThan(0));
    });

    test('returns null for screen exit without enter', () {
      final timeSpent = tracker.recordScreenExit('NonExistentScreen');
      expect(timeSpent, isNull);
    });

    test('handles multiple screens independently', () async {
      const screen1 = 'Screen1';
      const screen2 = 'Screen2';

      tracker.recordScreenEnter(screen1);
      await Future<void>.delayed(const Duration(seconds: 2));
      tracker.recordScreenEnter(screen2);
      await Future<void>.delayed(const Duration(seconds: 2));

      final time1 = tracker.recordScreenExit(screen1);
      final time2 = tracker.recordScreenExit(screen2);

      expect(time1, isNotNull);
      expect(time2, isNotNull);
      expect(time1, greaterThan(0));
      expect(time2, greaterThan(0));
    });

    test('clear removes all tracked screens', () {
      tracker
        ..recordScreenEnter('Screen1')
        ..recordScreenEnter('Screen2')
        ..clear();

      expect(tracker.recordScreenExit('Screen1'), isNull);
      expect(tracker.recordScreenExit('Screen2'), isNull);
    });
  });

  group('AnalyticsQueue Tests', () {
    late _CapturingSink sink;
    late AnalyticsQueue analyticsQueue;

    setUp(() {
      sink = _CapturingSink();
      analyticsQueue = AnalyticsQueue(sink);
    });

    test('creates analytics queue without errors', () {
      expect(analyticsQueue, isNotNull);
    });

    test('enqueue does not throw errors', () {
      const event = NavigationScreenEnterEvent(
        screenName: 'TestScreen',
        sourceScreen: 'PreviousScreen',
      );

      expect(() => analyticsQueue.enqueue(event), returnsNormally);
    });

    test('flush processes remaining events synchronously', () async {
      const event = NavigationScreenEnterEvent(
        screenName: 'TestScreen',
        sourceScreen: 'PreviousScreen',
      );

      sink.events.clear();
      analyticsQueue.enqueue(event);

      // Flush should process events immediately
      await analyticsQueue.flush();

      expect(sink.events.length, 1);
      expect(sink.events.first, isA<NavigationScreenEnterEvent>());
    });

    // Regression: a re-entrant flush() (e.g. dispose + a concurrent
    // flushAnalytics) must NOT resolve before the in-flight
    // sink.flush() completes. The old `if (_isShutdown) return;`
    // returned a completed future; the fix awaits the in-flight flush.
    test('re-entrant flush awaits the in-flight sink flush', () async {
      final sink = _ControllableFlushSink();
      final queue = AnalyticsQueue(sink);

      final first = queue.flush();
      final second = queue.flush();

      // Neither resolves until the sink's flush completes.
      expect(await _isCompleted(first), isFalse);
      expect(await _isCompleted(second), isFalse);

      sink.completeFlush();

      await first;
      await second;
      expect(sink.flushCount, 1);
    });
  });

  group('SamePageNavigationReplaceType Tests', () {
    late _CapturingSink sink;
    late NavigationController navigationController;

    setUp(() {
      sink = _CapturingSink();

      final home = Push(
        analyticsIdentifiable: _createAnalytics(
          (context) => Container(),
          'HomePage',
        ),
      );
      navigationController = NavigationController(
        home,
        analyticsSink: sink,
      );
    });

    test(
      'SamePageNavigationReplaceTop replaces the current page with '
      'the new page',
      () async {
        final newPage = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'NewPage',
          ),
        );
        final samePage = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'NewPage',
          ),
        );

        // Navigate to the new page
        navigationController.navigate(
          newPage,
        );
        expect(navigationController.currentNavigationStack.length, 2);
        expect(
          navigationController.currentNavigationStack.last.screenName,
          'NewPage',
        );

        // Navigate to the same page
        navigationController.navigate(samePage);
        expect(navigationController.currentNavigationStack.length, 2);
        expect(
          navigationController.currentNavigationStack.last.screenName,
          'NewPage',
        );

        await navigationController.flushAnalytics();
        expect(sink.events.length, equals(5));
        final pushEvent = sink.events[2];
        if (pushEvent is NavigationScreenEnterEvent) {
          expect(pushEvent.screenName, 'NewPage');
          expect(pushEvent.sourceScreen, 'HomePage');
          expect(pushEvent.navigationMethod, 'Push');
          expect(pushEvent.breadcrumb, 'root:HomePage > Push:NewPage');
        } else {
          fail('Push event is not a ScreenEnterEvent');
        }
        final replaceEvent = sink.events.last;
        if (replaceEvent is NavigationScreenEnterEvent) {
          expect(replaceEvent.screenName, 'NewPage');
          expect(replaceEvent.sourceScreen, 'NewPage');
          expect(replaceEvent.navigationMethod, 'ReplaceTop');
          expect(
            replaceEvent.breadcrumb,
            'root:HomePage > Push:NewPage > ReplaceTop:NewPage',
          );
        } else {
          fail('Replace event is not a ScreenEnterEvent');
        }
      },
    );

    test(
      'SamePageNavigationCustomReplace replaces the current page with '
      'a custom NavigationType',
      () async {
        final newPage = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'NewPage',
          ),
        );
        final samePage = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'NewPage',
          ),
        );
        final customPageReplacer = SamePageNavigationCustomReplace(
          handler: (viewNavigationType) => _DismissAndPresent(
            analyticsIdentifiable: _createAnalytics(
              viewNavigationType.builder,
              viewNavigationType.screenName,
            ),
          ),
        );

        // Navigate to the new page
        navigationController.navigate(
          newPage,
        );
        expect(navigationController.currentNavigationStack.length, 2);
        expect(
          navigationController.currentNavigationStack.last.screenName,
          'NewPage',
        );

        // Navigate to the same page
        navigationController.navigate(
          samePage,
          samePageReplaceType: customPageReplacer,
        );
        expect(navigationController.currentNavigationStack.length, 2);
        expect(
          navigationController.currentNavigationStack.last.screenName,
          'NewPage',
        );

        await navigationController.flushAnalytics();
        expect(sink.events.length, equals(5));
        final pushEvent = sink.events[2];
        if (pushEvent is NavigationScreenEnterEvent) {
          expect(pushEvent.screenName, 'NewPage');
          expect(pushEvent.sourceScreen, 'HomePage');
          expect(pushEvent.navigationMethod, 'Push');
          expect(pushEvent.breadcrumb, 'root:HomePage > Push:NewPage');
        } else {
          fail('Push event is not a ScreenEnterEvent');
        }

        final replaceEvent = sink.events.last;
        if (replaceEvent is NavigationScreenEnterEvent) {
          expect(replaceEvent.screenName, 'NewPage');
          expect(replaceEvent.sourceScreen, 'NewPage');
          expect(replaceEvent.navigationMethod, 'DismissAndPresent');
          expect(
            replaceEvent.breadcrumb,
            'root:HomePage > Push:NewPage > DismissAndPresent:NewPage',
          );
        } else {
          fail('Replace event is not a ScreenEnterEvent');
        }
      },
    );

    test(
      'SamePageNavigationNoReplace allows multiple navigations '
      'to the same page',
      () async {
        final newPage = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'NewPage',
          ),
        );
        final samePage = Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'NewPage',
          ),
        );

        // Navigate to the new page
        navigationController.navigate(
          newPage,
        );
        expect(navigationController.currentNavigationStack.length, 2);
        expect(
          navigationController.currentNavigationStack.last.screenName,
          'NewPage',
        );

        // Navigate to the same page
        navigationController.navigate(
          samePage,
          samePageReplaceType: const SamePageNavigationNoReplace(),
        );
        expect(navigationController.currentNavigationStack.length, 3);
        expect(
          navigationController.currentNavigationStack[1].screenName,
          'NewPage',
        );
        expect(
          navigationController.currentNavigationStack.last.screenName,
          'NewPage',
        );

        await navigationController.flushAnalytics();
        expect(sink.events.length, equals(5));
        final pushEvent = sink.events[2];
        if (pushEvent is NavigationScreenEnterEvent) {
          expect(pushEvent.screenName, 'NewPage');
          expect(pushEvent.sourceScreen, 'HomePage');
          expect(pushEvent.navigationMethod, 'Push');
          expect(pushEvent.breadcrumb, 'root:HomePage > Push:NewPage');
        } else {
          fail('Push event is not a ScreenEnterEvent');
        }
        final pushEvent2 = sink.events.last;
        if (pushEvent2 is NavigationScreenEnterEvent) {
          expect(pushEvent2.screenName, 'NewPage');
          expect(pushEvent2.sourceScreen, 'NewPage');
          expect(pushEvent2.navigationMethod, 'Push');
          expect(
            pushEvent2.breadcrumb,
            'root:HomePage > Push:NewPage > Push:NewPage',
          );
        } else {
          fail('Push event is not a ScreenEnterEvent');
        }
      },
    );
  });

  group('NavigationTheme Tests', () {
    testWidgets('of returns Material defaults without a provider', (
      tester,
    ) async {
      late NavigationThemeData captured;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            captured = NavigationTheme.of(context);
            return const SizedBox();
          },
        ),
      );
      expect(captured.scrimColor, Colors.black54);
    });

    testWidgets('of returns the provided theme data', (tester) async {
      const custom = NavigationThemeData(scrimColor: Colors.red);
      late NavigationThemeData captured;
      await tester.pumpWidget(
        NavigationTheme(
          data: custom,
          child: Builder(
            builder: (context) {
              captured = NavigationTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(captured, same(custom));
    });

    test('NavigationConfig accepts a custom theme', () {
      final controller = NavigationController(
        Push(analyticsIdentifiable: _createAnalytics((context) => Container())),
      );
      final config = NavigationConfig(
        controller: controller,
        featureProvider: const _NoopFeatureProvider(),
        theme: const NavigationThemeData(scrimColor: Colors.black87),
      );
      expect(config.routerDelegate, isA<NavigationRouterDelegate>());
    });
  });

  group('Tabbed Shell Tests', () {
    late _CapturingSink sink;

    setUp(() {
      sink = _CapturingSink();
      sink.events.clear();
    });

    Push _page(String screenName) => Push(
      analyticsIdentifiable: _createAnalytics(
        (context) => Container(),
        screenName,
      ),
    );

    NavigationController _twoBranchController() => NavigationController.tabbed(
      branches: [
        NavigationBranch(
          id: 1,
          initialNavigation: _page('A_root'),
          screenName: 'branchA',
        ),
        NavigationBranch(
          id: 2,
          initialNavigation: _page('B_root'),
          screenName: 'branchB',
        ),
      ],
      analyticsSink: sink,
    );

    test('tabbed controller exposes registered branches', () {
      final controller = _twoBranchController();

      expect(controller.isTabbed, isTrue);
      expect(controller.branchIds, [1, 2]);
      expect(controller.activeBranchId, 1);
      expect(controller.currentNavigationStack.last.screenName, 'A_root');
    });

    test('SwitchTab preserves each branch stack independently', () {
      final controller = _twoBranchController();

      controller.navigate(
        Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'A_details',
          ),
        ),
      );
      controller.navigate(const SwitchTab(2));
      controller.navigate(
        Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'B_details',
          ),
        ),
      );
      controller.navigate(const SwitchTab(1));

      // Back on branch A: its earlier push survived the round-trip.
      expect(controller.activeBranchId, 1);
      expect(controller.currentNavigationStack.length, 2);
      expect(controller.currentNavigationStack.last.screenName, 'A_details');
      // Branch B kept its own push.
      expect(controller.stackForBranch(2).length, 2);
      expect(controller.stackForBranch(2).last.screenName, 'B_details');
    });

    test('Push on branch A does not leak into branch B', () {
      final controller = _twoBranchController();

      controller.navigate(
        Push(
          analyticsIdentifiable: _createAnalytics(
            (context) => Container(),
            'A_details',
          ),
        ),
      );
      controller.navigate(const SwitchTab(2));

      // Branch B is untouched by A's push.
      expect(controller.stackForBranch(2).length, 1);
      expect(controller.stackForBranch(2).last.screenName, 'B_root');
    });

    test('SwitchTab with thenNavigate switches branch then pushes', () {
      final controller = _twoBranchController();

      controller.navigate(
        SwitchTab(
          2,
          thenNavigate: Push(
            analyticsIdentifiable: _createAnalytics(
              (context) => Container(),
              'B_details',
            ),
          ),
        ),
      );

      expect(controller.activeBranchId, 2);
      expect(controller.currentNavigationStack.length, 2);
      expect(controller.currentNavigationStack.last.screenName, 'B_details');
    });

    test('SwitchTab to unknown branch throws in debug', () {
      final controller = _twoBranchController();

      expect(
        () => controller.navigate(const SwitchTab(999)),
        throwsA(isA<AssertionError>()),
      );
    });

    test('SwitchTab to the active branch with no chain is a no-op', () {
      final controller = _twoBranchController();

      final result = controller.navigate(const SwitchTab(1));

      expect(result, isTrue);
      expect(controller.activeBranchId, 1);
      expect(controller.currentNavigationStack.length, 1);
      expect(controller.currentNavigationStack.last.screenName, 'A_root');
    });

    test('SwitchTab emits enter and exit analytics', () async {
      final controller = _twoBranchController();

      controller.navigate(const SwitchTab(2));
      await controller.flushAnalytics();

      // events[0] = initial enter on branch A.
      expect(sink.events.length, 3);
      final exit = sink.events[1];
      if (exit is NavigationScreenExitEvent) {
        expect(exit.screenName, 'A_root');
        expect(exit.exitMethod, 'SwitchTab');
        // destinationScreen is the actual destination screen, not the branch
        // URL segment.
        expect(exit.destinationScreen, 'B_root');
      } else {
        fail('Expected a NavigationScreenExitEvent at index 1.');
      }
      final enter = sink.events[2];
      if (enter is NavigationScreenEnterEvent) {
        expect(enter.screenName, 'B_root');
        expect(enter.sourceScreen, 'A_root');
        expect(enter.navigationMethod, 'SwitchTab');
      } else {
        fail('Expected a NavigationScreenEnterEvent at index 2.');
      }
    });

    test(
      'SwitchTab with thenNavigate emits no phantom branch-root view',
      () async {
        final controller = _twoBranchController();

        controller.navigate(
          SwitchTab(
            2,
            thenNavigate: Push(
              analyticsIdentifiable: _createAnalytics(
                (context) => Container(),
                'B_details',
              ),
            ),
          ),
        );
        await controller.flushAnalytics();

        // events[0] = initial enter on branch A.
        // Then exactly one transition: exit(A_root) → enter(B_details). The
        // branch root (B_root) is never recorded as seen — no phantom view.
        expect(sink.events.length, 3);
        final exit = sink.events[1];
        if (exit is NavigationScreenExitEvent) {
          expect(exit.screenName, 'A_root');
          expect(exit.exitMethod, 'Push');
          expect(exit.destinationScreen, 'B_details');
        } else {
          fail('Expected a NavigationScreenExitEvent at index 1.');
        }
        final enter = sink.events[2];
        if (enter is NavigationScreenEnterEvent) {
          expect(enter.screenName, 'B_details');
          expect(enter.sourceScreen, 'A_root');
          expect(enter.navigationMethod, 'Push');
        } else {
          fail('Expected a NavigationScreenEnterEvent at index 2.');
        }
      },
    );

    test(
      'SwitchTab with thenNavigate blocked by a nav callback still switches',
      () {
        final controller = _twoBranchController();
        // Register a navigation callback on branch B's root that blocks all
        // actions, so the chained Push is rejected.
        final bRoot = controller.stackForBranch(2).first;
        controller.registerNavigationCallback(
          bRoot.key,
          (action) => false,
        );

        // SwitchTab(2, thenNavigate: Push) — the Push is blocked, but the
        // branch must still switch and the controller must not desync.
        final result = controller.navigate(
          SwitchTab(
            2,
            thenNavigate: Push(
              analyticsIdentifiable: _createAnalytics(
                (context) => Container(),
                'B_details',
              ),
            ),
          ),
        );

        expect(result, isFalse); // the chained action was blocked
        expect(controller.activeBranchId, 2); // but the switch committed
        expect(controller.currentNavigationStack.last.screenName, 'B_root');
      },
    );

    test('default-branch controller is not tabbed', () {
      final controller = NavigationController(
        _page('Home'),
        analyticsSink: sink,
      );

      expect(controller.isTabbed, isFalse);
      // currentConfiguration guards on isTabbed, so the default branch never
      // serializes a branch segment even though it carries a root screen name.
      expect(controller.activeBranchScreenName, 'Home');
      // Unknown id resolves to an empty stack, keep-alive defaults true.
      expect(controller.stackForBranch(999), isEmpty);
      expect(controller.wantsKeepAlive(999), isTrue);
    });

    test('keep-alive getter reflects branch configuration', () {
      final controller = NavigationController.tabbed(
        branches: [
          NavigationBranch(
            id: 1,
            initialNavigation: _page('A_root'),
            wantsKeepAlive: true,
            screenName: 'branchA',
          ),
          NavigationBranch(
            id: 2,
            initialNavigation: _page('B_root'),
            wantsKeepAlive: false,
            screenName: 'branchB',
          ),
        ],
        analyticsSink: sink,
      );

      expect(controller.wantsKeepAlive(1), isTrue);
      expect(controller.wantsKeepAlive(2), isFalse);
    });

    test('currentConfiguration encodes the active branch screen name', () {
      final controller = _twoBranchController();
      final parser = NavigationRouteInformationParser();
      final delegate = NavigationRouterDelegate(
        controller,
        routeInformationParser: parser,
      );

      final config = delegate.currentConfiguration;
      expect(config, isNotNull);
      expect(config!.branchScreenName, 'branchA');

      final restored = parser.restoreRouteInformation(config);
      expect(restored, isNotNull);
      expect(restored!.uri.pathSegments, ['branchA', 'A_root']);

      // After switching, the URL reflects the new branch.
      controller.navigate(const SwitchTab(2));
      final configB = delegate.currentConfiguration;
      expect(configB!.branchScreenName, 'branchB');
      final restoredB = parser.restoreRouteInformation(configB);
      expect(restoredB!.uri.pathSegments, ['branchB', 'B_root']);
    });

    test('restoreRouteInformation does not double-encode segment names', () {
      final controller = NavigationController.tabbed(
        branches: [
          NavigationBranch(
            id: 1,
            initialNavigation: Push(
              analyticsIdentifiable: _createAnalytics(
                (context) => Container(),
                'My Screen',
              ),
            ),
            screenName: 'branch one',
          ),
          NavigationBranch(
            id: 2,
            initialNavigation: Push(
              analyticsIdentifiable: _createAnalytics(
                (context) => Container(),
                'Other',
              ),
            ),
            screenName: 'branch two',
          ),
        ],
        analyticsSink: sink,
      );
      final parser = NavigationRouteInformationParser();
      final delegate = NavigationRouterDelegate(
        controller,
        routeInformationParser: parser,
      );

      final restored = parser.restoreRouteInformation(
        delegate.currentConfiguration!,
      )!;
      // A space must be single-encoded (%20), not double-encoded (%2520).
      final uri = restored.uri.toString();
      expect(uri, contains('%20'));
      expect(uri, isNot(contains('%2520')));
      // Segments decode back to the original names.
      expect(restored.uri.pathSegments, ['branch one', 'My Screen']);
    });

    test(
      'blocked SwitchTab+thenNavigate aligns analytics to the new branch top',
      () async {
        final controller = _twoBranchController();
        // Block every action on branch B's root so the chained Push rejects.
        final bRoot = controller.stackForBranch(2).first;
        controller.registerNavigationCallback(bRoot.key, (action) => false);

        controller.navigate(
          SwitchTab(
            2,
            thenNavigate: Push(
              analyticsIdentifiable: _createAnalytics(
                (context) => Container(),
                'B_details',
              ),
            ),
          ),
        );
        await controller.flushAnalytics();

        // The branch switched; analytics should reflect the new branch root
        // (B_root), not the previous branch's screen — i.e. the exit source
        // is A_root and the enter destination is B_root.
        final exit = sink.events.whereType<NavigationScreenExitEvent>().last;
        expect(exit.screenName, 'A_root');
        expect(exit.destinationScreen, 'B_root');
        final enter = sink.events.whereType<NavigationScreenEnterEvent>().last;
        expect(enter.screenName, 'B_root');
      },
    );
  });
}

/// Capturing sink that records navigation analytics events in order for
/// verification. Enter and exit events share one ordered [events] list so
/// tests can assert on event sequence by index.
final class _CapturingSink implements NavigationAnalyticsSink {
  final List<Object> events = [];

  @override
  void onScreenEnter(NavigationScreenEnterEvent event) => events.add(event);

  @override
  void onScreenExit(NavigationScreenExitEvent event) => events.add(event);

  @override
  Future<void> flush() async {}
}

/// A sink whose [flush] stays pending until [completeFlush] is called.
///
/// Used to assert re-entrant [AnalyticsQueue.flush] behavior: concurrent
/// callers must not resolve before the sink's flush completes.
final class _ControllableFlushSink implements NavigationAnalyticsSink {
  int flushCount = 0;
  Completer<void>? _completer;

  void completeFlush() {
    _completer?.complete();
    _completer = null;
  }

  @override
  void onScreenEnter(NavigationScreenEnterEvent event) {}

  @override
  void onScreenExit(NavigationScreenExitEvent event) {}

  @override
  Future<void> flush() {
    flushCount++;
    _completer = Completer<void>();
    return _completer!.future;
  }
}

/// Returns `true` if [future] has already completed.
Future<bool> _isCompleted(Future<void> future) async {
  var done = false;
  unawaited(future.whenComplete(() => done = true));
  // Let any microtasks queued by the flush machinery run.
  await Future<void>.delayed(Duration.zero);
  return done;
}

// Minimal mock context for tests that don't actually use the context
class _MockContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ignore: avoid-top-level-members-in-tests
BuildContext get mockContext => _MockContext();

final class _DismissAndPresent extends ViewNavigationType {
  _DismissAndPresent({required super.analyticsIdentifiable});

  @override
  String get analyticsName => 'DismissAndPresent';

  @override
  List<ViewNavigationType> navigationStackFrom(
    List<ViewNavigationType> currentStack,
  ) {
    return [...currentStack.take(currentStack.length - 1), this];
  }

  @override
  Page<dynamic> buildAnimatedPage(BuildContext context) {
    return MaterialPage<dynamic>(
      key: key,
      name: screenName,
      fullscreenDialog: true,
      child: builder(context),
    );
  }
}
