# Security Policy

## Reporting a vulnerability

If you discover a security vulnerability in j_navigation, please report it
**privately** — do not open a public issue.

- **Email:** the maintainers via the email listed on the repository owner's
  GitHub profile.
- **GitHub:** use the "Report a vulnerability" option under the repo's
  **Security** tab (private vulnerability reporting).

Please include:

- A description of the issue and its potential impact.
- Steps to reproduce, or a proof of concept.
- Affected versions (if known).

We will acknowledge receipt within 72 hours and aim to issue a fix within a
reasonable window depending on severity.

## Scope

j_navigation is a client-side Flutter navigation package. Security
considerations relevant to this package:

- **Deep-link handling.** If you implement a `FeatureProvider`, ensure it
  validates and sanitizes deep-link parameters before navigating. The
  package itself does not interpret deep-link payloads — that is the host
  app's responsibility.
- **Route builders.** Route builders are `WidgetBuilder` closures supplied
  by the host app. The package does not execute untrusted builders; ensure
  your app does not construct routes from untrusted input.

## Supported versions

Only the latest published version receives security fixes.
