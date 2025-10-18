<# 
  setup-pwsh7-dotnet8.ps1
  - Installs/updates PowerShell 7, .NET Runtime 8 (run), and .NET SDK 8 (build) via winget
  - Exits if not elevated
  - Logs to %ProgramData%\SetupLogs
#>

[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

function Ensure-Admin-OrExit {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Not elevated. Run PowerShell as Administrator." -ForegroundColor Yellow
        exit 1
    }
}

function Start-SetupLogging {
    $logDir = Join-Path $env:ProgramData "SetupLogs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $script:LogPath = Join-Path $logDir ("setup-pwsh7-dotnet8_{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    Start-Transcript -Path $script:LogPath -Append | Out-Null
}

function Require-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget not found. Install “App Installer” from Microsoft Store and re-run."
    }
}

function WingetInstallOrUpgrade([string]$Id) {
    Write-Host ("-> winget install --id {0}" -f $Id)
    & winget install --id $Id --exact --source winget `
        --accept-package-agreements --accept-source-agreements --silent
    if ($LASTEXITCODE -ne 0) {
        Write-Host ("winget returned exit {0} for {1}. Continuing if package is present..." -f $LASTEXITCODE, $Id) -ForegroundColor Yellow
    }
}


Ensure-Admin-OrExit
Start-SetupLogging
Require-Winget

function Write-Header([string]$t){ Write-Host "`n===== $t =====" -ForegroundColor Cyan }

# --- PowerShell 7 ---
Write-Header "PowerShell 7 (pwsh)"
$pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwsh) {
    $v = & $pwsh.Source -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
    Write-Host ("Detected pwsh at: {0} (version {1})" -f $pwsh.Source,$v)
} else {
    Write-Host "pwsh not found."
}
try { WingetInstallOrUpgrade 'Microsoft.PowerShell' } catch { Write-Host $_.Exception.Message -ForegroundColor Yellow }
$pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwsh){
    $v = & $pwsh.Source -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
    Write-Host ("pwsh ready at: {0} (version {1})" -f $pwsh.Source,$v) -ForegroundColor Green
}

# --- .NET detection ---
Write-Header ".NET (dotnet) detection"
$dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
if ($dotnet) {
    Write-Host ("dotnet found at: {0}" -f $dotnet.Source)
    Write-Host "Installed SDKs:";      & $dotnet.Source --list-sdks 2>$null
    Write-Host "Installed Runtimes:";  & $dotnet.Source --list-runtimes 2>$null
} else {
    Write-Host "dotnet not found."
}

# --- .NET Runtime 8 (run stuff) ---
Write-Header ".NET Runtime 8 (run stuff)"
try { WingetInstallOrUpgrade 'Microsoft.DotNet.Runtime.8' } catch { Write-Host $_.Exception.Message -ForegroundColor Yellow }

# --- .NET SDK 8 (build stuff) ---
Write-Header ".NET SDK 8 (build stuff)"
try { WingetInstallOrUpgrade 'Microsoft.DotNet.SDK.8' } catch { Write-Host $_.Exception.Message -ForegroundColor Yellow }

# --- Final locations ---
Write-Header "Final Locations"
$pwshPath   = (Get-Command pwsh   -ErrorAction SilentlyContinue).Source
$dotnetPath = (Get-Command dotnet -ErrorAction SilentlyContinue).Source
if ($pwshPath)   { Write-Host ("pwsh  : {0}" -f $pwshPath) }
if ($dotnetPath) { Write-Host ("dotnet: {0}" -f $dotnetPath) }

if ($dotnetPath) {
    Write-Host "`ndotnet versions after install/upgrade:"
    & $dotnetPath --info
    Write-Host "`nSDKs:";      & $dotnetPath --list-sdks
    Write-Host "`nRuntimes:";  & $dotnetPath --list-runtimes
}

Write-Host "`nLog written to: $script:LogPath" -ForegroundColor Cyan
Stop-Transcript | Out-Null
