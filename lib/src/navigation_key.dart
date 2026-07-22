import 'package:flutter/foundation.dart';

/// A helper class for generating unique navigation keys.
///
/// This class provides a way to generate stable, unique keys for navigation
/// pages that can be used both when creating the page and within the page's
/// view model for registering callbacks.
class NavigationKey {
  NavigationKey._();

  static int _counter = 0;

  /// Generates a unique key for a navigation page.
  ///
  /// This method returns a unique [ValueKey] for each call, ensuring that
  /// multiple instances of the same screen type have different keys.
  ///
  /// The key is generated using a combination of the screen name and a counter.
  static ValueKey<String> generate(String screenName) {
    final uniqueId = '${screenName}_${_counter++}';

    return ValueKey<String>(uniqueId);
  }
}
