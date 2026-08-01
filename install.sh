#!/usr/bin/env bash
# Symlink the sanity-check skill into the user's Claude Code skills directory.
# Symlinking rather than copying means `git pull` updates the installed skill.

set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sanity-check"
dest_dir="${HOME}/.claude/skills"
dest="${dest_dir}/sanity-check"

[ -d "$src" ] || { echo "error: $src not found — run this from the repo root" >&2; exit 1; }

mkdir -p "$dest_dir"

if [ -L "$dest" ]; then
  current="$(readlink "$dest")"
  if [ "$current" = "$src" ]; then
    echo "Already installed: $dest"
    exit 0
  fi
  # Repointing our own symlink is safe; clobbering a real directory is not.
  echo "Replacing existing symlink ($current)"
  rm "$dest"
elif [ -e "$dest" ]; then
  echo "error: $dest already exists and is not a symlink." >&2
  echo "Move or remove it, then re-run this script." >&2
  exit 1
fi

ln -s "$src" "$dest"
chmod +x "$src/scripts/check-macos.sh"

echo "Installed: $dest -> $src"
echo "Start a new Claude Code session, then ask it to check your environment."
