# Repo notes - Rust CLI with forge integrations

Example notes for a Git-native CLI written in Rust that integrates with GitHub, GitLab, and Gitea by
shelling out to `gh` / `glab` / `tea`.

## The stack

Single Rust crate. `anyhow::Result` with contextual errors throughout; a panic is a user-facing
crash. User-facing output goes through `anstream::println!` / `eprintln!` and the `style::` helpers;
raw subprocess output is shown only on failure, or under `--verbose`.

## What CI already covers, so never mention it

`rustfmt`, `clippy -D warnings`, markdownlint, commitlint, and the `cargo test` matrix across
Linux/macOS/Windows, plus a live e2e suite.

## What CI cannot cover, so it is yours

Rebase and fork-point logic that can replay or drop the wrong commits, and anything that
force-pushes or deletes a ref. Test fakes assert on *arguments*: they prove the CLI would run
`gh pr edit --title`, not that `gh` accepts that flag. A new or changed subprocess invocation is only
genuinely covered by the live suite.

## Seams

- Only `src/git.rs` runs `git`; only `src/providers/` runs `gh` / `glab` / `tea`. A new
  `std::process::Command` anywhere else is a violation - route it through the existing helper or add
  one there.
- User-facing knobs are `stk.*` git-config keys declared in the `SETTINGS` table in
  `src/settings.rs`. Never read behavior off a bespoke environment variable.
- Subcommands live in `src/commands/<name>.rs` and implement `Run`; stack manipulation lives in
  `src/stack/`. Business logic wired directly into `cli.rs` is misplaced.
- Behavior shared across forges belongs on the `ReviewProvider` trait and lands for all
  implementations. Uniform on the trait does not mean uniform underneath: a draft is a real flag on
  GitHub but a `WIP:` title prefix elsewhere. Review the per-forge encoding, not just the signature.
- Managed sections of a PR body are assembled in `src/notes/`. A hand-rolled marker string drifts
  from the parser that has to read it back.

## Coverage matrix

- New flag, subcommand, or settings key → an integration test under `tests/`, plus the `SETTINGS`
  table, the README `[stk]` config block, and `docs/COMMANDS.md`
- New provider method → implemented for every forge, including the demo provider
- Pure helper (parsing, normalizing, prefix handling) → a colocated `#[cfg(test)] mod tests`, not
  only an end-to-end test that happens to cover it
- Any user-facing change → a `CHANGELOG.md` entry; the release publishes that section verbatim, so a
  missing entry ships empty release notes

## Repo-specific non-findings

- `.unwrap()` / `.expect()` inside `#[cfg(test)]` or `mod tests` is the norm and is never a finding.
- Shell completions and man pages are generated from clap at release time; they need no edit.
