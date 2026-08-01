# Probe the Windows dev environment. Emits one `name|status|detail` line per check.
# This script NEVER installs anything - remediation is the caller's job.

$ErrorActionPreference = 'SilentlyContinue'

function Probe {
    param(
        [string]$Name,
        [string]$Command,
        [string]$VersionFlag = '--version'
    )
    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        $version = (& $Command $VersionFlag 2>$null | Select-Object -First 1)
        "$Name|OK|$version"
    } else {
        "$Name|MISSING|"
    }
}

$caption = (Get-CimInstance Win32_OperatingSystem).Caption
"os|OK|$caption"

# winget ships with Windows 10 1809+ / Windows 11. If it is missing the user is on
# an older build and every install command below is unavailable to them.
Probe -Name 'winget'     -Command 'winget'
Probe -Name 'node'       -Command 'node'
Probe -Name 'github-cli' -Command 'gh'

# Claude Code CLI. Remediation differs by install method - `claude update` for a
# native install, npm for an npm one - so report which is in play.
$claude = Get-Command claude -ErrorAction SilentlyContinue
if ($claude) {
    $version = (& claude --version 2>$null | Select-Object -First 1)
    $method = if ($claude.Source -like '*node_modules*') { 'npm' } else { 'native' }
    "claude-code|OK|$version ($method)"
} else {
    "claude-code|MISSING|"
}
