---
name: sanity-check
description: Use when a user wants to verify their development environment is ready, set up a new machine, or asks whether they have the required tools — checks Homebrew, Node.js, GitHub CLI, and the Supabase MCP connector on macOS or Windows, and guides installation of whatever is missing.
---

# Environment Sanity Check

Verify a machine has the tools required to start work, and guide the user through installing anything missing. Works on macOS and Windows.

**Core principle:** probe everything in one pass, then remediate one tool at a time with the user's approval. Never install without asking.

## Flow

1. **Determine the OS.** Read it from the environment, then state what you found and let the user correct it: "Detected macOS — is that right?" Do not silently assume.
2. **Run the probe script** for that OS (see Quick Reference). It emits `name|status|detail` lines and installs nothing.
3. **macOS only — Homebrew is a gate.** If Homebrew is `MISSING`, stop and fix it first. Every other macOS install command depends on it, so reporting the rest as "failed" is misleading.
4. **Remediate each remaining failure** in order: Node.js, then GitHub CLI.
5. **Check the Supabase MCP connector.** This is a Claude Code session check, not a shell check — see below.
6. **Print the final report table.**

## Quick Reference

| Check | Probe | macOS fix | Windows fix |
|---|---|---|---|
| Homebrew | `scripts/check-macos.sh` | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` | n/a — `winget` ships with Windows |
| Node.js | both scripts | `brew install node` | `winget install --id OpenJS.NodeJS --source winget` |
| GitHub CLI | both scripts | `brew install gh` | `winget install --id GitHub.cli --source winget` |
| Supabase MCP | `claude mcp list` | see below | see below |

Run the probe with `bash scripts/check-macos.sh` or `pwsh -File scripts/check-windows.ps1`, resolving the path relative to this skill's directory.

## Remediation Rules

For every missing tool:

1. Show the exact command for the detected OS.
2. Ask the user to approve it before running. One approval covers one tool — never batch several installs behind a single yes.
3. Run it on approval, or step aside if the user prefers their own terminal.
4. Re-probe that one tool afterward and report the version. An install that reported success but left the binary unreachable is a failure, not a pass.

**`NOT_ON_PATH` is not `MISSING`.** The macOS probe reports this when Homebrew exists on disk but the shell can't see it. Installing again won't help — the fix is adding it to the shell profile:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile && eval "$(/opt/homebrew/bin/brew shellenv)"
```

Use `/usr/local/bin/brew` instead if that is the path the probe reported.

## Supabase MCP Connector

This is a session check, not a shell check. Run `claude mcp list` — it reports both registration and auth state per server, which is what you actually need:

```
plugin:supabase:supabase: https://mcp.supabase.com/mcp (HTTP) - ! Needs authentication
```

Then act on the status:

1. **`✔ Connected`** — done. Record it as passing.
2. **`! Needs authentication` or a connection failure** — tell the user to run `/mcp`, select Supabase, and complete the auth flow. It is interactive and browser-based, so the user must do it; you cannot, and no tool call will do it for them.
3. **No `supabase` entry at all** — give them:

   ```
   claude mcp add --transport http supabase https://mcp.supabase.com/mcp
   ```

   Then `/mcp` to authenticate. Point them at https://supabase.com/docs/guides/getting-started/mcp if the endpoint has moved — that page is authoritative, this command is a convenience.

## Final Report

Always end with a table, even when everything passes:

```
| Check        | Status | Detail                    |
|--------------|--------|---------------------------|
| macOS        | ✅     | 14.5 (arm64)              |
| Homebrew     | ✅     | Homebrew 4.3.8            |
| Node.js      | ✅     | v22.3.0                   |
| GitHub CLI   | ❌     | not installed             |
| Supabase MCP | ⚠️      | registered, not signed in |
```

Follow it with one line naming exactly what is left to do, or "Environment is ready." if nothing is.

## Common Mistakes

| Mistake | Do this instead |
|---|---|
| Concluding Supabase is ready because `mcp__*supabase*` tools exist | Those tools appear even when unauthenticated — an exposed `authenticate` tool is a sign it is *not* connected. Trust `claude mcp list`. |
| Asking "Mac or Windows?" when the environment already says | Detect, state it, invite correction |
| Reporting Node and `gh` as failures when Homebrew is missing on macOS | Fix Homebrew first; the rest are blocked, not broken |
| Treating `NOT_ON_PATH` as a missing install | Fix the shell profile — reinstalling changes nothing |
| Running installs without asking | Show the command, get a yes, then run it |
| Claiming an install worked because the command exited 0 | Re-probe the binary and report its version |
| Reading `brew install X` → "already installed and up-to-date" as a contradiction of a `MISSING` probe | Both are true: the formula was in the Cellar but unlinked, so the binary was genuinely unreachable. `brew install` silently re-links it. Re-probe — it will now pass. |
| Trying to authenticate the Supabase MCP for the user | Hand off — the OAuth flow needs a human in a browser |
