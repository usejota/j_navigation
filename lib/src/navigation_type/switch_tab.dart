part of 'navigation_type.dart';

/// Switches the active navigation branch (tab).
///
/// Does not modify either branch's stack — it only flips the active branch
/// pointer on the navigation controller. Each branch preserves its own stack
/// independently.
///
/// When [thenNavigate] is provided, the controller switches to
/// [targetBranchId] and then immediately applies [thenNavigate] on the new
/// branch's stack. This mirrors the common "switch tab then push a screen"
/// pattern in a single action.
final class SwitchTab extends NavigationType {
  const SwitchTab(
    this.targetBranchId, {
    this.thenNavigate,
    this.skipKeyboardDismissal = false,
  });

  /// The branch to switch to.
  final NavigationBranchId targetBranchId;

  /// Optional navigation to apply on the new branch after switching.
  final NavigationType? thenNavigate;

  @override
  String get analyticsName => 'SwitchTab';

  @override
  final bool skipKeyboardDismissal;

  /// Returns the current stack unchanged — [SwitchTab] does not modify stack
  /// contents; the controller handles the branch pointer flip.
  @override
  List<ViewNavigationType> navigationStackFrom(
    List<ViewNavigationType> currentStack,
  ) => currentStack;
}
