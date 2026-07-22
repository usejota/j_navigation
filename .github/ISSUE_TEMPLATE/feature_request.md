---
name: Feature request
about: Propose a new capability or improvement for j_navigation
title: "[feature] "
labels: enhancement
---

## Summary

What capability are you proposing?

## Motivation

What problem does this solve? What can't you do today, or what's painful?

## Proposed approach

How you imagine it working. Keep in mind j_navigation's principles:

- **Action-based** — navigation as immutable `NavigationType` objects with
  pure `navigationStackFrom` stack transforms.
- **Context-free controller** — no `BuildContext` in the controller API.
- **No codegen** — no `build_runner`, no annotations.

If your proposal bends any of these, say so explicitly and explain why.

## Alternatives considered

What other shapes could this take, and why is yours preferred?

## Out of scope

What this proposal intentionally does NOT cover.
