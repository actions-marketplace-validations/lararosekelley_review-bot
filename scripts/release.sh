#!/usr/bin/env bash
#
# Tags a release and moves the major tag callers use. Run on an up-to-date main
# whose CHANGELOG.md already has the version's section at the top.
#
#   scripts/release.sh 1.2.0
#
# Pushing vX.Y.Z runs the release workflow, which publishes the GitHub release
# with that section as its notes. The major tag (v1) is moved with a force push,
# so callers on @v1 get the release as soon as this finishes.

set -euo pipefail

version="${1:?usage: release.sh X.Y.Z}"
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

die() {
  echo "release.sh: $*" >&2
  exit 1
}

[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "version must be X.Y.Z, got $version"
tag="v$version"
major="v${version%%.*}"

[ "$(git rev-parse --abbrev-ref HEAD)" = main ] || die "must be on main"
[ -z "$(git status --porcelain --untracked-files=no)" ] || die "tracked changes are uncommitted"
git fetch --quiet --tags origin main
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || die "main is not in sync with origin/main"
! git rev-parse --quiet --verify "refs/tags/$tag" >/dev/null || die "$tag already exists"

latest="$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' | sed 's/^v//' | sort -V | tail -1)"
if [ -n "$latest" ] && [ "$(printf '%s\n%s\n' "$latest" "$version" | sort -V | tail -1)" != "$version" ]; then
  die "$version is not newer than $latest"
fi

top="$(sed -n 's/^## \([0-9][0-9.]*\) - .*/\1/p' CHANGELOG.md | head -1)"
[ "$top" = "$version" ] || die "CHANGELOG.md's newest section is $top, not $version"
notes="$(scripts/release-notes.sh "$version")"

echo "Release $tag at $(git log --oneline -1), and move $major to it."
echo
printf '%s\n\n' "$notes"
read -r -p "Tag and push? [y/N] " answer
[ "$answer" = y ] || die "nothing done"

git tag -a "$tag" -m "$tag"
git tag -f -a "$major" -m "$major" >/dev/null
git push origin "refs/tags/$tag"
git push --force origin "refs/tags/$major"
echo "Pushed $tag and moved $major. The release workflow publishes the GitHub release."
