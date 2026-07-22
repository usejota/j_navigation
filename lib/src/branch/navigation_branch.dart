import 'package:j_navigation/src/navigation_type/navigation_type.dart';

/// Opaque identity for a navigation branch (tab).
///
/// The package treats this as a stable equality key only — it never inspects
/// the value. Use const/frozen values: enums, ints, or const objects. Never
/// use per-instantiation objects (their identity will never match across
/// constructions).
typedef NavigationBranchId = Object;

/// Describes one branch (tab) in a tabbed navigation shell.
///
/// A branch owns its own independent navigation stack. The first entry of that
/// stack is [initialNavigation]; subsequent pushes/presents append to it.
/// Switching branches preserves each branch's stack.
class NavigationBranch {
  const NavigationBranch({
    required this.id,
    required this.initialNavigation,
    this.wantsKeepAlive = true,
    this.screenName,
  });

  /// Unique identity for this branch. Must be a const/frozen value.
  final NavigationBranchId id;

  /// The root page of this branch's stack.
  final ViewNavigationType initialNavigation;

  /// When `true` (default), the branch's widget subtree is kept alive while
  /// off-stage. When `false`, it is disposed and rebuilt on return.
  final bool wantsKeepAlive;

  /// Screen name used for analytics and deep-link serialization. Defaults to
  /// [initialNavigation]'s screen name when `null`.
  final String? screenName;

  /// Resolved screen name, falling back to [initialNavigation]'s screen name.
  String get resolvedScreenName => screenName ?? initialNavigation.screenName;
}
