<#
  new-pc-setup.ps1
  - Requires Administrator
  - Disables Bing web search in Windows Search for the current user
  - Installs or upgrades:
      * PowerShell 7
      * .NET Runtime 8
      * .NET SDK 8
      * Everything
      * WizTree
  - Logs to %ProgramData%\SetupLogs
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Info([string]$Message) {
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Success([string]$Message) {
    Write-Host $Message -ForegroundColor Green
}

function Write-WarnMsg([string]$Message) {
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Fail([string]$Message) {
    Write-Host $Message -ForegroundColor Red
}

function Ensure-Admin-OrExit {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = [Security.Principal.WindowsPrincipal]::new($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-WarnMsg 'Not elevated. Please run this script in PowerShell as Administrator.'
        exit 1
    }
}

function Start-SetupLogging {
    $logDir = Join-Path $env:ProgramData 'SetupLogs'
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $script:LogPath = Join-Path $logDir ('new-pc-setup_{0}.log' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    Start-Transcript -Path $script:LogPath -Append | Out-Null
}

function Stop-SetupLogging {
    try {
        Stop-Transcript | Out-Null
    }
    catch {
        # Ignore if transcript is not active.
    }
}

function Require-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget not found. Install Microsoft App Installer, then re-run this script.'
    }
}

function Start-Step([string]$Name) {
    Write-Host ''
    Write-Info ("Starting: {0} ..." -f $Name)
}

function Complete-Step([string]$Name) {
    Write-Success ("Step successful: {0}" -f $Name)
}

function Test-WingetPackageInstalled([string]$Id) {
    $output = & winget list --id $Id --exact --source winget --accept-source-agreements 2>&1
    $text = ($output | Out-String)

    if ($LASTEXITCODE -ne 0) {
        return $false
    }

    return ($text -match [Regex]::Escape($Id))
}

function Invoke-Winget([string[]]$Arguments) {
    & winget @Arguments
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw ("winget failed with exit code {0}. Args: {1}" -f $exitCode, ($Arguments -join ' '))
    }
}

function Ensure-WingetPackage {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $Id
    )

    Start-Step $Name

    $baseArgs = @(
        '--id', $Id,
        '--exact',
        '--source', 'winget',
        '--accept-package-agreements',
        '--accept-source-agreements',
        '--silent'
    )

    $wasInstalled = Test-WingetPackageInstalled -Id $Id

    if ($wasInstalled) {
        Write-Host ("Detected installed package: {0} ({1})" -f $Name, $Id)
        try {
            Invoke-Winget -Arguments @('upgrade') + $baseArgs
        }
        catch {
            Write-WarnMsg ("Upgrade attempt did not complete cleanly for {0}. Trying install to repair/ensure presence..." -f $Name)
            Invoke-Winget -Arguments @('install') + $baseArgs
        }
    }
    else {
        Write-Host ("Package not currently installed: {0} ({1})" -f $Name, $Id)
        Invoke-Winget -Arguments @('install') + $baseArgs
    }

    if (-not (Test-WingetPackageInstalled -Id $Id)) {
        throw ("Package verification failed after install/upgrade: {0} ({1})" -f $Name, $Id)
    }

    Complete-Step $Name
}

function Set-BingSearchDisabled {
    $regPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
    $valueName = 'BingSearchEnabled'

    Start-Step 'Disable Bing web search in Start/Search'

    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }

    New-ItemProperty -Path $regPath -Name $valueName -PropertyType DWord -Value 0 -Force | Out-Null

    $actual = (Get-ItemProperty -Path $regPath -Name $valueName).$valueName
    if ($actual -ne 0) {
        throw ("Registry verification failed. {0} is {1}, expected 0." -f $valueName, $actual)
    }

    Complete-Step 'Disable Bing web search in Start/Search'
}

function Show-FinalStatus {
    Start-Step 'Final status summary'

    $pwshCmd   = Get-Command pwsh   -ErrorAction SilentlyContinue
    $dotnetCmd = Get-Command dotnet -ErrorAction SilentlyContinue

    if ($pwshCmd) {
        $pwshVersion = & $pwshCmd.Source -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
        Write-Host ("pwsh   : {0} (version {1})" -f $pwshCmd.Source, $pwshVersion)
    }
    else {
        Write-WarnMsg 'pwsh was not found in PATH after installation.'
    }

    if ($dotnetCmd) {
        Write-Host ("dotnet : {0}" -f $dotnetCmd.Source)
        Write-Host ''
        Write-Host '.NET --info'
        & $dotnetCmd.Source --info
        Write-Host ''
        Write-Host 'Installed SDKs:'
        & $dotnetCmd.Source --list-sdks
        Write-Host ''
        Write-Host 'Installed Runtimes:'
        & $dotnetCmd.Source --list-runtimes
    }
    else {
        Write-WarnMsg 'dotnet was not found in PATH after installation.'
    }

    $searchValue = (Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -ErrorAction Stop).BingSearchEnabled
    Write-Host ''
    Write-Host ("Registry check: HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\BingSearchEnabled = {0}" -f $searchValue)

    Complete-Step 'Final status summary'
}

Ensure-Admin-OrExit
Start-SetupLogging

try {
    Write-Info 'Starting: New PC setup script'
    Require-Winget
    Complete-Step 'winget availability check'

    Set-BingSearchDisabled

    Ensure-WingetPackage -Name 'PowerShell 7'      -Id 'Microsoft.PowerShell'
    Ensure-WingetPackage -Name '.NET Runtime 8'    -Id 'Microsoft.DotNet.Runtime.8'
    Ensure-WingetPackage -Name '.NET SDK 8'        -Id 'Microsoft.DotNet.SDK.8'
    Ensure-WingetPackage -Name 'Everything'        -Id 'voidtools.Everything'
    Ensure-WingetPackage -Name 'WizTree'           -Id 'AntibodySoftware.WizTree'

    Show-FinalStatus

    Write-Host ''
    Write-Success 'All requested steps completed successfully.'
    Write-Info ("Log written to: {0}" -f $script:LogPath)
    exit 0
}
catch {
    Write-Host ''
    Write-Fail ("Script failed: {0}" -f $_.Exception.Message)
    if ($script:LogPath) {
        Write-Info ("Check the log here: {0}" -f $script:LogPath)
    }
    exit 1
}
finally {
    Stop-SetupLogging
}
