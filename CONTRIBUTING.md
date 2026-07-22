# Contributing to j_navigation

Thanks for your interest in improving j_navigation. This package is
production-proven but young as an open-source project — first external
adopters are collaborators, not just users.

## Before you start

- **Search existing issues** before opening a new one.
- For design questions or feature proposals, open a discussion/issue first
  before writing code, so we can align on direction. j_navigation has a
  deliberate architecture (action-based, context-free, no codegen) and
  changes that bend those principles are likely to be declined.

## Development setup

This is a standalone Flutter package (no melos workspace required):

```bash
cd packages/j_navigation       # or the repo root after extraction
flutter pub get
flutter test
flutter analyze
```

The `example_app/` directory has a runnable demo:

```bash
cd example_app
flutter pub get
flutter run
```

## Code style

- `very_good_analysis` lint rules apply (strict casts, strict inference).
  `flutter analyze` must pass with no issues.
- `dart format` must pass (`dart format --set-exit-if-changed .`).
- Prefer `interface class` over `final class` for anything that should be
  mockable in tests. (The controller, sinks, and providers are `interface
  class` for this reason.)
- Tests use `flutter_test` + `mocktail` (NOT mockito). No `build_runner` —
  the package is codegen-free and should stay that way.
- Mirror source file structure in `test/`.

## Tests

Every behavior change needs a test. The existing suite
(`test/j_navigation_test.dart`) follows the Arrange-Act-Assert pattern and
uses a `_CapturingSink` for analytics assertions. Add to it, or create a new
test file mirroring the source path.

Run the full suite before opening a PR:

```bash
flutter test
```

## Pull requests

1. Branch from `main`.
2. One logical change per PR.
3. Include tests.
4. Update `CHANGELOG.md` under an `[Unreleased]` heading.
5. Make sure `flutter analyze` and `flutter test` pass.
6. Reference any issue in the PR description (`Closes #123`).

## Commit messages

Conventional Commits style:

```
feat(scope): summary
fix(scope): summary
docs(scope): summary
refactor(scope): summary
test(scope): summary
chore(scope): summary
```

## Architecture notes

j_navigation is built on three principles that every change should respect:

- **Action-based.** Navigation is expressed as immutable `NavigationType`
  objects; each implements `navigationStackFrom(currentStack) → newStack`
  as a pure function. New navigation kinds follow this pattern.
- **Context-free controller.** `NavigationController.navigate` takes no
  `BuildContext`. Don't add context-dependent APIs to the controller.
- **No codegen.** Route builders are `WidgetBuilder` closures. Don't
  introduce `build_runner`, annotations, or generated code.

See [doc/POSITIONING.md](doc/POSITIONING.md) for the full design rationale
and how j_navigation compares to go_router / auto_route.

## Releasing

Maintainers only. Bump `version` in `pubspec.yaml`, update `CHANGELOG.md`,
tag, then `flutter pub publish`. Run `flutter pub publish --dry-run` first.

