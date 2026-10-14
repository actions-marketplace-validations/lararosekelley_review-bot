# Changelog

What changed in each version, for the people using the action. Each section is drafted with
`git cliff` and then written up by hand; see [RELEASING.md](RELEASING.md). The release workflow
publishes the section matching the tag as the GitHub release notes, so headings must stay
`## X.Y.Z - YYYY-MM-DD`.

## 1.1.1 - 2026-10-14

### Changed

- The action is named Low-Noise Code Review, so it can be listed on the GitHub Marketplace. Callers
  do not need to change anything: `lararosekelley/review-bot@v1` and the reusable workflow at `@v1`
  keep working.

## 1.1.0 - 2026-10-01

### Changed

- The default model is `claude-sonnet-5-5` at `high` effort, in place of `claude-opus-5`. Set
  `model: claude-opus-5-5` for the most thorough reviews, or `effort: xhigh` to trade cost for
  depth. If you pinned `model` or `effort` only to get the defaults, you can remove them.

## 1.0.0 - 2026-09-07

### Added

- A GitHub Action that reviews pull requests with Claude and posts inline findings plus one summary
  with a confidence score, tuned to post only what is worth a change.
- A reusable workflow that gates reviews to the repository owner by default and re-reviews when a
  comment mentions `@bot`.
- Repo notes, from a file or inline, that teach the reviewer a codebase's specifics and coverage
  rules.
