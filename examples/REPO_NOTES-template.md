# Repo notes template

Copy this, delete what does not apply, and keep it short. The base prompt already carries the
philosophy, the finding categories, the workflow, the scoring, and the output format - do not repeat
any of it here. This file is only for facts the bot cannot safely infer from the code in one pass.

Rule of thumb: if a sentence would be true of any repository, it belongs in the base prompt, not
here.

## The stack

One table or list. Language, framework, where each layer lives. Correct a wrong assumption
explicitly if your repo invites one ("this is not a TypeScript app", "there is no bundler", "there
is no endpoint-helper layer - a literal path in a fetch call is the convention here").

## What CI already covers, so never mention it

List the exact checks. The bot reads `.github/workflows/` on its own, but naming them removes all
doubt and is the single highest-value section of this file.

## What CI cannot cover, so it is yours

The dimension where this repo actually breaks. Examples: queries built at runtime with nothing
checking them against the schema; a provider CLI whose flags only a live suite exercises; a
generated artifact that must stay deterministic.

## Seams

The boundaries that are deliberate, and what violating one looks like:

- only `<module>` may shell out / talk to the network / write to disk
- user-facing knobs are `<mechanism>`, never a bespoke environment variable
- `<kind of code>` lives in `<path>`; logic wired directly into `<path>` is misplaced
- managed text (PR bodies, templates, generated blocks) is assembled in `<module>`, never hand-rolled

## Coverage matrix

What kind of change requires what kind of test, in this repo's own vocabulary:

- new `<thing>` → `<test kind>` in `<path>`
- change to `<rendering / geometry / snapshot>` → baseline update
- new user-facing surface → an entry in `<README section / CHANGELOG / command reference>`

## Repo-specific non-findings

The things that look wrong but are not, so the bot stops reporting them:

- `.unwrap()` inside `#[cfg(test)]` is the norm here
- `PreEscaped` around trusted server-rendered markdown is an established, documented exception
