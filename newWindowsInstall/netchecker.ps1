# netchecker.ps1

$Host.UI.RawUI.WindowTitle = "NetChecker Launcher"

$routerHost = "speedport.ip"
$fallbackRouterIp = "192.168.2.1"
$routerIp = $null
$openedWindows = @()

$routerWindowTitle   = "NetChecker - Check Connection to Router"
$internetWindowTitle = "NetChecker - Check Connection to Internet"
$wlanWindowTitle     = "NetChecker - WLAN Interface Status"

function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )

    $timestamp = Get-Date -Format "HH:mm:ss"

    switch ($Level.ToUpper()) {
        "INFO"  { $color = "Cyan" }
        "OK"    { $color = "Green" }
        "WARN"  { $color = "Yellow" }
        "ERROR" { $color = "Red" }
        default { $color = "White" }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-ProcessExists {
    param(
        [int]$ProcessId
    )

    $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    return ($null -ne $process)
}

function Start-CmdWindow {
    param(
        [string]$Title,
        [string]$Command
    )

    try {
        $process = Start-Process cmd.exe -ArgumentList "/k", "title $Title && $Command" -PassThru -ErrorAction Stop
        $script:openedWindows += [PSCustomObject]@{
            Title     = $Title
            ProcessId = $process.Id
        }

        Start-Sleep -Milliseconds 300

        if (Test-ProcessExists -ProcessId $process.Id) {
            Write-Log "OK" "Fenster '$Title' geöffnet (PID: $($process.Id))"
        }
        else {
            Write-Log "WARN" "Fenster '$Title' wurde gestartet, hat sich aber direkt wieder geschlossen (PID: $($process.Id))"
        }
    }
    catch {
        Write-Log "ERROR" "Fenster '$Title' konnte nicht geöffnet werden: $($_.Exception.Message)"
    }
}

function Close-CmdWindowByProcessId {
    param(
        [int]$ProcessId,
        [string]$Title
    )

    try {
        $displayName = if ($Title) { "'$Title' (PID: $ProcessId)" } else { "PID $ProcessId" }

        if (-not (Test-ProcessExists -ProcessId $ProcessId)) {
            Write-Log "WARN" "Fenster $displayName wurde nicht gefunden oder ist bereits geschlossen"
            return $true
        }

        Write-Log "INFO" "Schliesse Fenster $displayName..."

        & taskkill.exe /F /T /PID $ProcessId | Out-Null

        Start-Sleep -Milliseconds 700

        if (Test-ProcessExists -ProcessId $ProcessId) {
            Write-Log "ERROR" "Fenster $displayName ist noch offen"
            return $false
        }
        else {
            Write-Log "OK" "Fenster $displayName erfolgreich geschlossen"
            return $true
        }
    }
    catch {
        Write-Log "ERROR" "Fehler beim Schliessen von PID ${ProcessId}: $($_.Exception.Message)"
        return $false
    }
}

Write-Host ""
Write-Log "INFO" "Starting NetChecker..."
Write-Log "INFO" "Step 1/5: Resolving router host '$routerHost'"

try {
    $routerIp = Resolve-DnsName -Name $routerHost -Type A -ErrorAction Stop |
        Where-Object { $_.IPAddress } |
        Select-Object -First 1 -ExpandProperty IPAddress

    if ($routerIp) {
        Write-Log "OK" "Resolved '$routerHost' to $routerIp using Resolve-DnsName"
    }
}
catch {
    Write-Log "WARN" "Resolve-DnsName failed: $($_.Exception.Message)"
    Write-Log "INFO" "Trying alternative DNS lookup..."

    try {
        $routerIp = [System.Net.Dns]::GetHostAddresses($routerHost) |
            Where-Object { $_.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork } |
            Select-Object -First 1 -ExpandProperty IPAddressToString

        if ($routerIp) {
            Write-Log "OK" "Resolved '$routerHost' to $routerIp using .NET DNS lookup"
        }
    }
    catch {
        Write-Log "WARN" "Alternative DNS lookup failed: $($_.Exception.Message)"
    }
}

if (-not $routerIp) {
    $routerIp = $fallbackRouterIp
    Write-Log "WARN" "Could not resolve '$routerHost'. Using fallback router IP: $routerIp"
}

Write-Log "INFO" "Step 2/5: Opening router ping window..."
Start-CmdWindow -Title $routerWindowTitle -Command "ping -t $routerIp"

Write-Log "INFO" "Step 3/5: Opening internet ping window..."
Start-CmdWindow -Title $internetWindowTitle -Command "ping -t 1.1.1.1"

Write-Log "INFO" "Step 4/5: Opening WLAN status window..."
Start-CmdWindow -Title $wlanWindowTitle -Command "netsh wlan show interfaces"

Write-Log "INFO" "Step 5/5: Done"
Write-Host ""
Write-Log "INFO" "Summary:"
Write-Log "INFO" "Router host: $routerHost"
Write-Log "INFO" "Router IP in use: $routerIp"
Write-Log "OK" "NetChecker finished launching all tasks"

Write-Host ""
Write-Host "============================================" -ForegroundColor DarkGray
Write-Host "[1] Nur dieses Fenster schliessen" -ForegroundColor White
Write-Host "[2] Alle von NetChecker geoeffneten Fenster schliessen" -ForegroundColor White
Write-Host "[Andere Taste] Fenster offen lassen" -ForegroundColor White
Write-Host "============================================" -ForegroundColor DarkGray
Write-Host ""

$key = [System.Console]::ReadKey($true)

switch ($key.KeyChar) {
    '1' {
        Write-Log "INFO" "Closing only launcher window..."
        exit
    }

    '2' {
        Write-Log "WARN" "Trying to close all NetChecker windows..."
        $closeFailed = $false

        foreach ($window in ($openedWindows | Sort-Object -Property ProcessId -Unique)) {
            $success = Close-CmdWindowByProcessId -ProcessId $window.ProcessId -Title $window.Title
            if (-not $success) {
                $closeFailed = $true
            }
        }

        if ($closeFailed) {
            Write-Log "WARN" "Not all windows could be closed. Launcher will stay open."
            Write-Host ""
            Read-Host "Enter druecken zum Fortfahren" | Out-Null
        }
        else {
            Write-Log "OK" "All NetChecker windows closed successfully."
            Write-Log "INFO" "Closing launcher window..."
            exit
        }
    }

    default {
        Write-Log "INFO" "No close action selected. Launcher stays open."
        Write-Host ""
        Read-Host "Enter druecken zum Fortfahren" | Out-Null
    }
}
