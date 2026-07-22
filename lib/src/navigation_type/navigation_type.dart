// ignore_for_file: avoid-dynamic

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:j_navigation/src/analytics/analytics_identifiable.dart';
import 'package:j_navigation/src/branch/navigation_branch.dart';
import 'package:j_navigation/src/components/alert_dialog_page.dart';
import 'package:j_navigation/src/components/modal_bottom_sheet_page.dart';
import 'package:j_navigation/src/components/no_animation_page.dart';
import 'package:j_navigation/src/components/no_swipe_page.dart';
import 'package:j_navigation/src/custom_types/replace_animation_type.dart';

part 'alert.dart';
part 'dismiss.dart';
part 'pop_to.dart';
part 'modal.dart';
part 'present.dart';
part 'present_multiple.dart';
part 'push.dart';
part 'push_multiple.dart';
part 'replace_stack.dart';
part 'replace_top.dart';
part 'switch_tab.dart';
part 'swipe.dart';

abstract base class NavigationType {
  const NavigationType();

  /// Stable identifier for analytics and breadcrumbs.
  ///
  /// Do NOT rely on `runtimeType.toString()` here, because it will be
  /// obfuscated in release builds.
  String get analyticsName;

  /// If true, the keyboard dismissal will be skipped before the navigation.
  bool get skipKeyboardDismissal;

  /// Modifies the navigation stack based on the current stack
  /// and the new navigation type.
  List<ViewNavigationType> navigationStackFrom(
    List<ViewNavigationType> currentStack,
  );
}

/// Base class for all navigation types that use a widget builder.
abstract base class ViewNavigationType extends NavigationType
    with PageNavigationType {
  ViewNavigationType({
    required this.analyticsIdentifiable,
    ValueKey<String>? navigationKey,
    this.skipKeyboardDismissal = false,
    this.animated = true,
  }) : key = navigationKey ?? ValueKey('${analyticsIdentifiable.hashCode}');

  final AnalyticsIdentifiable analyticsIdentifiable;
  final ValueKey<String> key;
  final bool animated;

  @override
  final bool skipKeyboardDismissal;

  @override
  String get screenName => analyticsIdentifiable.screenName;
  WidgetBuilder get builder => analyticsIdentifiable.builder;

  @nonVirtual
  Page<dynamic> buildPage(BuildContext context) {
    return animated
        ? buildAnimatedPage(context)
        : NoAnimationPage<dynamic>(
            key: key,
            name: screenName,
            child: builder(context),
          );
  }

  Page<dynamic> buildAnimatedPage(BuildContext context) {
    return MaterialPage<dynamic>(
      key: key,
      name: screenName,
      child: builder(context),
    );
  }
}

/// Base class for all navigation types that do not modify the navigation stack
/// because is managed by something else outside of the navigation system but
/// still needs to be tracked for analytics and breadcrumbs.
abstract base class NoPageViewNavigationType extends NavigationType
    with PageNavigationType {
  NoPageViewNavigationType({
    required AnalyticsIdentifiable analyticsIdentifiable,
  }) : _analyticsIdentifiable = analyticsIdentifiable,
       key = ValueKey('${analyticsIdentifiable.hashCode}');

  final AnalyticsIdentifiable _analyticsIdentifiable;
  final ValueKey<String> key;

  @override
  String get screenName => _analyticsIdentifiable.screenName;

  @nonVirtual
  @override
  List<ViewNavigationType> navigationStackFrom(
    List<ViewNavigationType> currentStack,
  ) {
    return currentStack;
  }
}

base mixin DismissableNavigationType on ViewNavigationType {
  bool get swipeToDismissEnabled;
}

base mixin PageNavigationType on NavigationType {
  String get screenName;
}
