# Repo notes - server-rendered web app

Example notes for a Rust web app: axum handlers, compiled-in templates, SQLite, and unbundled
browser JavaScript.

## The stack

| Layer | What it is | Where |
| --- | --- | --- |
| Server | axum handlers returning `impl IntoResponse` | `src/` |
| Templates | maud macros compiled into the binary, auto-escaping | `src/components/`, `src/routes/pages/` |
| Data | sqlx + SQLite, **runtime** `sqlx::query(...)` only | `src/db.rs`, `src/*/store.rs` |
| Frontend | vanilla ESM served raw - no bundler, no TypeScript | `static/js/` |
| Interactions | htmx attributes rendered by the templates | `src/` |
| Styles | plain CSS, globally scoped, no preprocessor or modules | `static/styles/` |
| E2E | Playwright specs in TypeScript, the only TS in the repo | `e2e/` |

This is not a TypeScript app. There is no monorepo, no workspace, and no endpoint-helper layer:
browser code calling `fetch("/health")` with a literal path is the convention, not a violation.

## What CI already covers, so never mention it

`cargo fmt --check`, `cargo clippy --all-targets -D warnings`, `oxlint` on `static/js/`, `stylelint`,
`tsc --noEmit` on `e2e/`, markdownlint, shellcheck, `cargo test`, `node --test`, and the Playwright
suite.

## What CI cannot cover, so it is yours

**SQL correctness.** Every query is built at runtime - there are zero compile-time-checked query
macros - so nothing validates SQL against the schema until a request hits it. For every new or
edited query, verify:

- placeholder count and order match the `.bind()` chain exactly
- column names and indices in `get` / `try_get` match the `SELECT` list
- Rust types match the column types, with `NULL` handled as `Option<T>`
- a new or renamed column has a matching migration in `src/migrations/`
- user-controlled values are bound as parameters, never formatted into the SQL string

Also yours: escaping decisions, panics on the request path, and CSS blast radius.

## Seams

- Store logic in a route handler, or route logic in a store, is misplaced.
- Business logic embedded in a template belongs in the module that owns it.
- Templates escape by default. A new `PreEscaped` wrapping anything user-controlled is an XSS
  finding.
- CSS is global with no scoping: a new bare element, `*`, or broad class selector can restyle
  unrelated pages. Require the change be scoped to its component or page.
- `hx-target` and `hx-swap` must point at markup the handler actually returns, and a partial
  response must be a fragment when it is swapped into one.
- `static/js/` is served unbundled and untranspiled: bare module specifiers, non-relative imports,
  and untranspiled syntax will not run.

## Coverage matrix

- New or changed Rust logic → a `#[test]` where the surrounding module tests its logic
- New user-facing flow, or a fixed UI regression → a Playwright spec following `docs/E2E.md`

## Repo-specific non-findings

- `.unwrap()` / `.expect()` inside `#[cfg(test)]` or `mod tests`.
- Existing `PreEscaped` uses, which are limited to trusted server-rendered markdown and inlined boot
  scripts.
