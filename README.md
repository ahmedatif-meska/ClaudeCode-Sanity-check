# sanity-check

A [Claude Code](https://claude.com/claude-code) skill that verifies a development environment is ready to work in, and walks you through installing whatever is missing.

Checks **Python**, **pip**, **Homebrew** (macOS), **Node.js**, **GitHub CLI**, the **Claude Code CLI**, and the **Supabase MCP connector** on macOS and Windows.

GitHub gets a live check on top of the presence check — `gh api user` and `git ls-remote` make real authenticated calls over the same auth and transport a push uses, so an expired token or blocked network shows up as a failure rather than a false pass. Both are read-only; the skill never pushes to verify.

No dependencies on other skills or plugins — a `SKILL.md` and two probe scripts.

**Free to use, no API keys.** Nothing here asks for a key, token, or paid account. Every tool it installs is free and open source, and the scripts read no credentials and set no environment variables. The one sign-in involved is the Supabase MCP connector, which uses a browser OAuth flow against your own Supabase account (free tier is fine) — you can skip that check entirely if you don't use Supabase.

## Install

```bash
git clone https://github.com/ahmedatif-meska/ClaudeCode-Sanity-check.git
cd ClaudeCode-Sanity-check
./install.sh
```

`install.sh` symlinks the skill into `~/.claude/skills/`, so `git pull` updates it in place. To install manually, or on Windows:

```bash
ln -s "$PWD/sanity-check" ~/.claude/skills/sanity-check
```

```powershell
New-Item -ItemType SymbolicLink -Path "$HOME\.claude\skills\sanity-check" -Target "$PWD\sanity-check"
```

Copying the `sanity-check/` directory instead of symlinking works too — you just have to re-copy to update.

## Use

Ask Claude Code anything along the lines of:

> check my environment
> am I set up to start working?
> I just got a new laptop, what do I need to install?

Or invoke it directly with `/sanity-check`.

## What it does

1. Detects your OS and asks you to confirm.
2. Runs one probe script — `scripts/check-macos.sh` or `scripts/check-windows.ps1` — that reports every tool in a single pass and **installs nothing**.
3. On macOS, treats Homebrew as a gate: if it's missing, that gets fixed first, because every other install command depends on it.
4. For each missing tool, shows you the exact command, **asks before running it**, then re-probes to confirm the install actually took.
5. Checks the Supabase MCP connector via `claude mcp list`, and hands off to you for the browser sign-in — that part can't be automated.
6. Prints a ✅/❌ summary.

### Install commands it uses

| Tool | macOS | Windows |
|---|---|---|
| Python + pip | `brew install python` | `winget install --id Python.Python.3.13 --source winget` |
| Homebrew | official `install.sh` from Homebrew | n/a — `winget` ships with Windows |
| Node.js | `brew install node` | `winget install --id OpenJS.NodeJS --source winget` |
| GitHub CLI | `brew install gh` | `winget install --id GitHub.cli --source winget` |
| Claude Code CLI | `claude update`, or `curl -fsSL https://claude.ai/install.sh \| bash` | `claude update`, or `irm https://claude.ai/install.ps1 \| iex` |
| Supabase MCP | `claude mcp add --transport http supabase https://mcp.supabase.com/mcp` | same |

## Running the probes on their own

The scripts are standalone and read-only. They print one `name|status|detail` line per check:

```console
$ bash sanity-check/scripts/check-macos.sh
os|OK|macOS 14.5 (arm64)
python|OK|Python 3.13.12
pip|OK|pip 25.3 from /Library/.../site-packages/pip (python 3.13)
homebrew|OK|Homebrew 6.0.14
node|OK|v24.18.0
github-cli|MISSING|
claude-code|OK|2.1.220 (Claude Code) (native)
```

The Claude Code line reports the install method — `native` or `npm` — because the upgrade path differs between them.

Python and pip are probed under both names (`python3`/`python`, `pip3`/`pip`), since macOS ships only the 3-suffixed ones and Windows ships the bare ones. Presence and version are separate facts: an interpreter that exists but whose `--version` fails reports `OK|…, version unavailable`, never `MISSING` — reinstalling wouldn't be the fix.

`NOT_ON_PATH` is a distinct status from `MISSING`: it means Homebrew is installed but your shell can't see it — common on Apple Silicon, where reinstalling won't help and a shell-profile fix will.

## Adding a check

Add a `probe` line to both scripts, then a row to the Quick Reference table in `sanity-check/SKILL.md` with the fix command for each OS. The scripts only report; all remediation logic lives in `SKILL.md`.

## Status

The macOS probe is tested on macOS 14.5 (arm64), on both its passing and degraded-`PATH` paths. The Supabase check is verified against a live Claude Code session.

**`check-windows.ps1` has not been executed on Windows.** It uses only standard cmdlets (`Get-Command`, `Get-CimInstance`), but treat it as unverified until it runs on a real Windows machine. Reports welcome.

## License

MIT © 2026 Ahmed Atef. See [LICENSE](LICENSE) — free to use, modify, and redistribute, including commercially.
