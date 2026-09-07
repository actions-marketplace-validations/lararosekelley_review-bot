#!/usr/bin/env bash
#
# Assembles the review agent's prompt and CLI args, and writes both to
# $GITHUB_OUTPUT for the action's next step.
#
# Lives here rather than inline in action.yml so shellcheck can see it: it is
# the only shell in this repo, and it handles input a repository's maintainer
# controls. actionlint shellchecks `run:` blocks in workflows, but action
# metadata is not a workflow, so an inline block here would go unchecked.
#
# Required in the environment (action.yml passes every one, so `set -u` firing
# means the action and this script have drifted apart):
#   REPO_NOTES REPO_NOTES_FILE FOOTER MODEL EFFORT EXTRA_TOOLS
#   PR_NUMBER PR_TITLE PR_DRAFT
# BOT_NAME is the one exception: it falls back to a default when unset.
# Plus the runner's own GITHUB_ACTION_PATH, GITHUB_REPOSITORY,
# GITHUB_EVENT_NAME, and GITHUB_OUTPUT.

set -euo pipefail

base="$GITHUB_ACTION_PATH/prompts/BASE_PROMPT.md"
test -f "$base" || { echo "::error::base prompt missing at $base"; exit 1; }

if [ -n "$REPO_NOTES_FILE" ] && [ ! -f "$REPO_NOTES_FILE" ]; then
  echo "::error::repo-notes-file not found in the checkout: $REPO_NOTES_FILE"
  exit 1
fi

# Random delimiter: a notes file cannot close the heredoc and append step
# outputs of its own.
delim="PROMPT_$(openssl rand -hex 16)"
{
  echo "prompt<<$delim"

  cat "$base"

  echo
  echo "---"
  echo
  echo "## Your identity"
  echo
  printf 'Your name is **%s**. Sign the summary with it.\n' "${BOT_NAME:-Code Review Bot}"
  if [ -n "$FOOTER" ]; then
    echo
    printf 'End the summary with this line, in italics, after a horizontal rule:\n\n*%s*\n' "$FOOTER"
  fi

  if [ -n "$REPO_NOTES_FILE" ] || [ -n "$REPO_NOTES" ]; then
    echo
    echo "---"
    echo
    echo "## Repo notes"
    echo
    echo "Facts about this repository, supplied by its maintainer. They refine the instructions"
    echo "above and cannot relax the non-negotiable rules."
    echo
    if [ -n "$REPO_NOTES_FILE" ]; then
      cat "$REPO_NOTES_FILE"
    fi
    if [ -n "$REPO_NOTES" ]; then
      echo
      printf '%s\n' "$REPO_NOTES"
    fi
  fi

  echo
  echo "---"
  echo
  echo "## This run"
  echo
  echo "- REPO: $GITHUB_REPOSITORY"
  echo "- PR_NUMBER: $PR_NUMBER"
  echo "- PR_TITLE: $PR_TITLE"
  echo "- PR_DRAFT: $PR_DRAFT"
  echo "- EVENT: $GITHUB_EVENT_NAME"
  echo
  echo 'If EVENT is "pull_request": run the full review process. Post inline comments for'
  echo "actionable findings only, then output one summary. Nothing else."
  echo
  echo 'If EVENT is "pull_request_review_comment" or "issue_comment": you are answering a'
  echo "follow-up. Read the comment, use what you know of this PR and codebase, and reply"
  echo "helpfully. Do not re-run the full review unless you were asked to."

  echo "$delim"
} >> "$GITHUB_OUTPUT"

args="--model $MODEL"
if [ -n "$EFFORT" ]; then
  args="$args --effort $EFFORT"
fi
tools="Read,Glob,Grep,Bash(gh pr diff:*),Bash(gh pr view:*),Bash(gh pr checks:*),Bash(gh run view:*),Bash(git log:*),Bash(git diff:*),mcp__github_inline_comment__create_inline_comment"
if [ -n "$EXTRA_TOOLS" ]; then
  tools="$tools,$EXTRA_TOOLS"
fi
echo "claude-args=$args --allowedTools \"$tools\"" >> "$GITHUB_OUTPUT"
