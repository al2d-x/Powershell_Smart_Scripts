<#
.SYNOPSIS
  Disables web/Bing search in the Start Menu (HKCU) and then validates
  the settings, printing "desired vs. actual" values.

  cd "C:\VS CODE\Powershell_Handy_Scripts"
  powershell -ExecutionPolicy Bypass -File ".\Disable-WebSearch_Validate.ps1" -RestartExplorer

#>

[CmdletBinding()]
param (
    [string]$LogFile = "$([Environment]::GetFolderPath('UserProfile'))\Downloads\websearch.log",
    [switch]$RestartExplorer
)

# ___ Helpers ______________________________________________________________
function Write-Log {
    param([string]$Message,[string]$Level="INFO")
    $ts   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "$ts [$Level] $Message"
    Write-Host $line
    if ($LogFile) { $line | Out-File -FilePath $LogFile -Encoding utf8 -Append }
}

function Ensure-Elevation {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        Write-Log "Not elevated, relaunching elevated..." "WARN"
        try {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName  = (Get-Process -Id $PID).Path
            $psi.Arguments = "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`" $($MyInvocation.UnboundArguments)"
            $psi.Verb      = "runas"
            [Diagnostics.Process]::Start($psi) | Out-Null
            exit 0
        } catch {
            Write-Log "Elevation failed or cancelled: $_" "ERROR"
            exit 2
        }
    }
}

function Get-RegistryValue {
    param([string]$Path,[string]$Name)
    if (Test-Path $Path) {
        try { (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name }
        catch { $null }
    } else { $null }
}

function Set-RegistryValueSafely {
    param([string]$Path,[string]$Name,[int]$Value)

    try {
        if (-not (Test-Path $Path)) {
            Write-Log "Creating missing key: $Path"
            New-Item -Path $Path -Force | Out-Null
        }

        $current = Get-RegistryValue -Path $Path -Name $Name
        if ($current -ne $Value) {
            $prev = if ($null -eq $current) { 'null' } else { $current }
            Write-Log "Setting $Name = $Value under $Path (was: $prev)"
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type DWord -Force
        } else {
            Write-Log "$Name already set to desired value ($Value) under $Path"
        }
    } catch {
        Write-Log "Failed to set $Name at $Path : $_" "ERROR"
        throw
    }
}

# ___ Main ________________________________________________________________
try {
    Ensure-Elevation

    $explorerPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
    $searchPath   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"

    $desired = @{
        "$explorerPath|DisableSearchBoxSuggestions" = 1
        "$searchPath|BingSearchEnabled"             = 0
        "$searchPath|CortanaConsent"                = 0
    }

    Write-Log "---- Applying desired settings ----"
    foreach ($item in $desired.GetEnumerator()) {
        $k = $item.Key.Split('|')
        Set-RegistryValueSafely -Path $k[0] -Name $k[1] -Value $item.Value
    }

    if ($RestartExplorer.IsPresent) {
        Write-Log "Restarting explorer.exe to apply changes_"
        Stop-Process -Name explorer -Force
    }

    # Validation
    Write-Log "---- Desired vs. Actual ----"
    $mismatch = $false
    foreach ($item in $desired.GetEnumerator()) {
        $k       = $item.Key.Split('|')
        $actual  = Get-RegistryValue -Path $k[0] -Name $k[1]
        $display = if ($null -eq $actual) { 'null' } else { $actual }
        $msg     = "{0,-45}  SHOULD: {1}  ACTUAL: {2}" -f $k[1], $item.Value, $display
        if ($actual -ne $item.Value) { Write-Log $msg "WARN"; $mismatch = $true }
        else                         { Write-Log $msg }
    }

    if ($mismatch) { Write-Log "One or more values did NOT match." "WARN"; exit 1 }
    else           { Write-Log "All values match the desired state. _";  exit 0 }
}
catch {
    Write-Log "SCRIPT TERMINATED WITH ERRORS." "ERROR"
    Write-Host "`nPress Enter to exit..."
    Read-Host
    exit 2
}
