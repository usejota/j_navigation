import 'package:flutter/material.dart';

/// A class that contains the analytics information for ViewNavigationType.
final class AnalyticsIdentifiable {
  const AnalyticsIdentifiable({
    required this._screenName,
    required this.builder,
    this._dynamicScreenName,
  });

  factory AnalyticsIdentifiable.withDynamicScreenName(
    String Function() screenName, {
    required WidgetBuilder builder,
  }) {
    return AnalyticsIdentifiable(
      screenName: '',
      dynamicScreenName: screenName,
      builder: builder,
    );
  }

  String get screenName => _dynamicScreenName?.call() ?? _screenName;

  final String _screenName;
  final String Function()? _dynamicScreenName;
  final WidgetBuilder builder;
}
