# Pull request

## What

A one-line description of the change.

## Why

The motivation. What problem does this solve, or what does it enable?

## How

Brief description of the approach. If the change touches j_navigation's
core principles (action-based, context-free, no-codegen), explain how it
respects or deliberately bends them.

## Verification

- [ ] `flutter analyze` passes with no issues.
- [ ] `flutter test` passes.
- [ ] `dart format --set-exit-if-changed .` passes.
- [ ] Tests added for any new behavior.
- [ ] `CHANGELOG.md` updated under `[Unreleased]`.

## Checklist

- [ ] One logical change per PR.
- [ ] No `BuildContext` introduced in the `NavigationController` API.
- [ ] No `build_runner` / codegen introduced.
- [ ] New navigation kinds implement `navigationStackFrom` as a pure
      stack-transform (if applicable).

## Related

Closes #issue (if applicable).
