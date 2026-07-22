import 'package:flutter/widgets.dart';

import 'package:j_navigation/src/branch/navigation_branch.dart';

/// Builds the shell (e.g. a bottom navigation bar) around the branch content
/// swap widget.
///
/// [branchContent] is the [IndexedStack] of per-branch [Navigator]s the router
/// owns; the active branch is the one on stage. [activeBranchId] is the
/// currently visible branch. [activeBranchIndex] is its index in the
/// controller's registered branch order. [switchTo] navigates to a target
/// branch — wire it to a tab button's `onTap`.
///
/// The package keeps the bar widget host-supplied so it stays UI-agnostic.
typedef NavigationShellBuilder =
    Widget Function(
      BuildContext context,
      Widget branchContent,
      NavigationBranchId activeBranchId,
      int activeBranchIndex,
      void Function(NavigationBranchId target) switchTo,
    );
