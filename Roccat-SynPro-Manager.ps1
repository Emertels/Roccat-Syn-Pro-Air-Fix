# ==============================================================================
#  ROCCAT SYN PRO AIR - MULTILINGUAL MASTER MANAGER (v3.6)
#  Auto-detects Windows language from 10 native supported languages
#  Developed by Emerson Teles & Antigravity (Google DeepMind)
# ==============================================================================

# Auto-elevacao transparente para Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-NoExit", "-File", $PSCommandPath) -Verb RunAs
    exit
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$host.UI.RawUI.WindowTitle = "ROCCAT Syn Pro Air - Master Manager (By Emerson Teles & Antigravity)"

$driverName = "WavesTBVirtual"
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$driverName"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configFile = Join-Path $scriptDir "config.json"
$i18nFile = Join-Path $scriptDir "i18n.json"
$sessionStart = Get-Date -Format "dd/MM/yyyy 'as' HH:mm:ss"

# Helper C# nativo para travar audio no Windows CoreAudio
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

[Guid("870C3566-265F-4D2A-8991-6101216C68FB"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IPolicyConfigVista {
    int MaskKernelEndpoint();
    int SetLargePageMinimum();
    int SetNumericProperty();
    int SetCurrentFormat();
    int PreserveDeviceFormat();
    int SetDefaultEndpoint(string wszDeviceId, int eRole);
    int SetEndpointVisibility();
}

[ComImport, Guid("294935CE-F637-4E7C-A41B-AB255460B862")]
public class PolicyConfigVistaClient { }

public class AudioController {
    public static void SetDefaultAudio(string deviceId) {
        try {
            var client = (IPolicyConfigVista)(new PolicyConfigVistaClient());
            client.SetDefaultEndpoint(deviceId, 0);
            client.SetDefaultEndpoint(deviceId, 2);
        } catch {}
    }
}
"@ -ErrorAction SilentlyContinue

# Carregar dicionario i18n
$translations = $null
if (Test-Path $i18nFile) {
    try {
        $jsonRaw = Get-Content $i18nFile -Raw -Encoding UTF8
        $translations = $jsonRaw | ConvertFrom-Json
    } catch {}
}

function Get-CurrentLanguage {
    if (Test-Path $configFile) {
        try {
            $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
            if ($cfg.Language) { return $cfg.Language }
        } catch {}
    }
    
    $culture = (Get-Culture).Name.ToLower()
    $uiCulture = (Get-UICulture).Name.ToLower()
    
    foreach ($cand in @($culture, $uiCulture)) {
        if ($cand.StartsWith("pt")) { return "pt-BR" }
        if ($cand.StartsWith("es")) { return "es-ES" }
        if ($cand.StartsWith("fr")) { return "fr-FR" }
        if ($cand.StartsWith("de")) { return "de-DE" }
        if ($cand.StartsWith("it")) { return "it-IT" }
        if ($cand.StartsWith("ru")) { return "ru-RU" }
        if ($cand.StartsWith("ja")) { return "ja-JP" }
        if ($cand.StartsWith("zh")) { return "zh-CN" }
        if ($cand.StartsWith("ko")) { return "ko-KR" }
        if ($cand.StartsWith("en")) { return "en-US" }
    }
    
    return "pt-BR"
}

function Get-Text($key, $defaultText = "") {
    $lang = Get-CurrentLanguage
    if ($translations -and $translations.$lang -and $translations.$lang.$key) {
        return $translations.$lang.$key
    }
    if ($translations -and $translations.'pt-BR' -and $translations.'pt-BR'.$key) {
        return $translations.'pt-BR'.$key
    }
    return $defaultText
}

function Set-CurrentLanguage($lang) {
    @{ Language = $lang } | ConvertTo-Json | Set-Content $configFile -Encoding UTF8
}

function Show-LanguageSelector {
    Clear-Host
    Write-Host "==============================================================================" -ForegroundColor DarkCyan
    Write-Host "                     SELECT LANGUAGE / SELECIONE O IDIOMA                     " -ForegroundColor Cyan
    Write-Host "==============================================================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  [1] Portugues (Brasil)     - pt-BR" -ForegroundColor White
    Write-Host "  [2] English (US)           - en-US" -ForegroundColor White
    Write-Host "  [3] Espanol                - es-ES" -ForegroundColor White
    Write-Host "  [4] Francais               - fr-FR" -ForegroundColor White
    Write-Host "  [5] Deutsch                - de-DE" -ForegroundColor White
    Write-Host "  [6] Italiano               - it-IT" -ForegroundColor White
    Write-Host "  [7] Russian (ru-RU)" -ForegroundColor White
    Write-Host "  [8] Japanese (ja-JP)" -ForegroundColor White
    Write-Host "  [9] Chinese (zh-CN)" -ForegroundColor White
    Write-Host "  [10] Korean (ko-KR)" -ForegroundColor White
    Write-Host ""
    Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkCyan
    $sel = Read-Host "Choose option [1-10]"
    switch ($sel) {
        '1' { Set-CurrentLanguage "pt-BR" }
        '2' { Set-CurrentLanguage "en-US" }
        '3' { Set-CurrentLanguage "es-ES" }
        '4' { Set-CurrentLanguage "fr-FR" }
        '5' { Set-CurrentLanguage "de-DE" }
        '6' { Set-CurrentLanguage "it-IT" }
        '7' { Set-CurrentLanguage "ru-RU" }
        '8' { Set-CurrentLanguage "ja-JP" }
        '9' { Set-CurrentLanguage "zh-CN" }
        '10'{ Set-CurrentLanguage "ko-KR" }
    }
}

function Get-FixStatus {
    $isUsbDisabled = $false
    try {
        $p = powercfg /query SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 2>$null
        if ($p -match "0x00000000") { $isUsbDisabled = $true }
    } catch {}

    $isDuckingDisabled = $false
    try {
        $duck = (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio' -ErrorAction SilentlyContinue).UserDuckingPreference
        if ($duck -eq 3) { $isDuckingDisabled = $true }
    } catch {}

    return ($isUsbDisabled -and $isDuckingDisabled)
}

function Get-SystemAudioInfo {
    $state = @{
        DriverInstalled = (Test-Path $regPath)
        DriverRunning   = $false
        DriverStartMode = "N/A"
        UsbDongleStatus = $false
        HeadsetStatus   = "Inativo"
        MicStatus       = "Inativo"
        HeadsetDevId    = ""
        FixApplied      = (Get-FixStatus)
    }

    if ($state.DriverInstalled) {
        $driver = Get-WmiObject Win32_SystemDriver | Where-Object { $_.Name -eq $driverName } -ErrorAction SilentlyContinue
        $state.DriverRunning = if ($driver) { $driver.State -eq 'Running' } else { $false }
        $startVal = (Get-ItemProperty -Path $regPath -Name 'Start' -ErrorAction SilentlyContinue).Start
        $state.DriverStartMode = $startVal
    }

    $dongle = Get-PnpDevice -InstanceId 'USB\VID_1E7D&PID_3A3B*' -Status OK -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($dongle) { $state.UsbDongleStatus = $true }

    $headset = Get-PnpDevice -Class 'AudioEndpoint' -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -match 'HEADSET.*SYN' } | Select-Object -First 1
    if ($headset) { 
        $state.HeadsetStatus = $headset.Status
        $state.HeadsetDevId  = $headset.InstanceId
    }

    $mic = Get-PnpDevice -Class 'AudioEndpoint' -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -match 'MICROFONE.*SYN' } | Select-Object -First 1
    if ($mic) { $state.MicStatus = $mic.Status }

    return $state
}

function Show-Header {
    Clear-Host
    $info = Get-SystemAudioInfo

    Write-Host "==============================================================================" -ForegroundColor DarkCyan
    Write-Host "             $((Get-Text 'Title' 'ROCCAT SYN PRO AIR - MASTER MANAGER'))      " -ForegroundColor Cyan
    Write-Host "==============================================================================" -ForegroundColor DarkCyan
    Write-Host " $((Get-Text 'Credit' 'Desenvolvido por Emerson Teles com Antigravity'))" -ForegroundColor DarkGray
    Write-Host " $((Get-Text 'Disclaimer' 'Aviso: Solucao comprovada pelo autor'))" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host " $((Get-Text 'Session' 'Sessao iniciada em:')) " -NoNewline -ForegroundColor Gray
    Write-Host "$sessionStart" -ForegroundColor White
    Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkCyan

    Write-Host " [$((Get-Text 'SystemStatus' 'STATUS DO SISTEMA'))]" -ForegroundColor Yellow

    function Write-AlignedStatus($label, $value, $color) {
        $prefix = "  * " + $label
        $padded = if ($prefix.Length -lt 32) { $prefix.PadRight(32) } else { $prefix }
        Write-Host "${padded}: " -NoNewline -ForegroundColor Gray
        Write-Host $value -ForegroundColor $color
    }

    # Badge do Fix
    $fixVal = if ($info.FixApplied) { (Get-Text 'FixPositive' '[ POSITIVO: FIX ATIVO ]') } else { (Get-Text 'FixPending' '[ PENDENTE: FIX INCOMPLETO ]') }
    $fixCol = if ($info.FixApplied) { "Green" } else { "Red" }
    Write-AlignedStatus (Get-Text 'FixStatusLabel' 'Status da Blindagem (Fix)') $fixVal $fixCol

    # USB Dongle
    $usbVal = if ($info.UsbDongleStatus) { (Get-Text 'UsbConnected' 'Conectado e Seguro [OK]') } else { (Get-Text 'UsbDisconnected' 'Desconectado ou Inativo') }
    $usbCol = if ($info.UsbDongleStatus) { "Green" } else { "Red" }
    Write-AlignedStatus (Get-Text 'UsbDongle' 'Receptor USB Dongle') $usbVal $usbCol

    # Driver Turtle Beach
    $tbVal = if (-not $info.DriverInstalled) { (Get-Text 'DriverNotInstalled' 'Nao Instalado no Windows') } elseif ($info.DriverRunning) { (Get-Text 'DriverActive' 'ATIVO [Risco de Ciclagem]') } else { (Get-Text 'DriverDisabled' 'DESABILITADO [Modo Seguro]') }
    $tbCol = if (-not $info.DriverInstalled) { "DarkGray" } elseif ($info.DriverRunning) { "Yellow" } else { "Green" }
    Write-AlignedStatus (Get-Text 'DriverTB' 'Driver Turtle Beach') $tbVal $tbCol

    # Headset
    $hsVal = if ($info.HeadsetStatus -eq 'OK') { (Get-Text 'DeviceOK' 'Ativo e Estavel [OK]') } else { "$((Get-Text 'DeviceInactive' 'Inativo')) [$($info.HeadsetStatus)]" }
    $hsCol = if ($info.HeadsetStatus -eq 'OK') { "Green" } else { "Red" }
    Write-AlignedStatus (Get-Text 'Headset' 'Alto-Falante [Headset]') $hsVal $hsCol

    # Microfone
    $micVal = if ($info.MicStatus -eq 'OK') { (Get-Text 'DeviceOK' 'Ativo e Estavel [OK]') } else { "$((Get-Text 'DeviceInactive' 'Inativo')) [$($info.MicStatus)]" }
    $micCol = if ($info.MicStatus -eq 'OK') { "Green" } else { "Red" }
    Write-AlignedStatus (Get-Text 'Microphone' 'Microfone SYN Pro Air') $micVal $micCol

    Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkCyan
}

function Invoke-ModoEstavel {
    Write-Host ""
    Write-Host ">>> $((Get-Text 'Opt1Title'))..." -ForegroundColor Cyan
    Stop-Process -Name 'ROCCAT_Waves_Driver' -Force -ErrorAction SilentlyContinue
    sc.exe stop $driverName 2>&1 | Out-Null

    if (Test-Path $regPath) {
        Set-ItemProperty -Path $regPath -Name 'Start' -Value 4 -ErrorAction SilentlyContinue
    }

    $info = Get-SystemAudioInfo
    if ($info.HeadsetDevId) {
        Enable-PnpDevice -InstanceId $info.HeadsetDevId -Confirm:$false -ErrorAction SilentlyContinue
    }

    Start-Sleep -Seconds 1
    Write-Host " $((Get-Text 'Success' 'Concluido com sucesso!'))" -ForegroundColor Green
    Write-Host ""
    Write-Host "$((Get-Text 'PressKey' 'Pressione qualquer tecla para voltar...'))" -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-SwarmAutoPilot {
    Write-Host ""
    Write-Host ">>> $((Get-Text 'Opt2Title'))..." -ForegroundColor Yellow
    
    if (-not (Test-Path $regPath)) {
        Write-Host " [ERROR] $((Get-Text 'DriverNotInstalled'))" -ForegroundColor Red
        Start-Sleep -Seconds 3
        return
    }

    Set-ItemProperty -Path $regPath -Name 'Start' -Value 3 -ErrorAction SilentlyContinue
    sc.exe start $driverName 2>&1 | Out-Null

    $wavesExe = "C:\Program Files (x86)\ROCCAT\ROCCAT SWARM\data\waves_driver\ROCCAT_Waves_Driver.exe"
    if (Test-Path $wavesExe) {
        Start-Process $wavesExe -ErrorAction SilentlyContinue
    }

    $swarmExe = "C:\Program Files (x86)\ROCCAT\ROCCAT SWARM\ROCCAT_Swarm.exe"
    if (Test-Path $swarmExe) {
        Start-Process $swarmExe
    }

    Write-Host " Auto-Pilot Running... Swarm is open." -ForegroundColor Cyan
    Write-Host " Closing Swarm will safely restore Stable Mode." -ForegroundColor DarkGray
    Write-Host ""

    Start-Sleep -Seconds 5
    while ($true) {
        $swarmRunning = Get-Process -Name 'ROCCAT_Swarm' -ErrorAction SilentlyContinue
        if (-not $swarmRunning) {
            Stop-Process -Name 'ROCCAT_Waves_Driver' -Force -ErrorAction SilentlyContinue
            sc.exe stop $driverName 2>&1 | Out-Null
            Set-ItemProperty -Path $regPath -Name 'Start' -Value 4 -ErrorAction SilentlyContinue
            Write-Host " $((Get-Text 'Success'))" -ForegroundColor Green
            Start-Sleep -Seconds 2
            break
        }
        Start-Sleep -Seconds 2
    }
}

function Invoke-SentinelaAtiva {
    Write-Host ""
    Write-Host "==============================================================================" -ForegroundColor Magenta
    Write-Host "                         $((Get-Text 'Opt3Title'))                            " -ForegroundColor White
    Write-Host "==============================================================================" -ForegroundColor Magenta
    Write-Host " Press [Ctrl + C] to return to menu." -ForegroundColor DarkYellow
    Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkCyan

    if (Test-Path $regPath) {
        Set-ItemProperty -Path $regPath -Name 'Start' -Value 3 -ErrorAction SilentlyContinue
        sc.exe start $driverName 2>&1 | Out-Null
    }

    $wavesExe = "C:\Program Files (x86)\ROCCAT\ROCCAT SWARM\data\waves_driver\ROCCAT_Waves_Driver.exe"
    if (Test-Path $wavesExe) {
        $p = Get-Process ROCCAT_Waves_Driver -ErrorAction SilentlyContinue
        if (-not $p) { Start-Process $wavesExe -ErrorAction SilentlyContinue }
    }

    Write-Host " Sentry armed and running (500ms cycle)..." -ForegroundColor Green
    Write-Host ""

    $counter = 0
    $intercepts = 0
    while ($true) {
        $now = Get-Date -Format 'HH:mm:ss'
        $synOut = Get-PnpDevice -Class 'AudioEndpoint' -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -match 'HEADSET.*SYN' }

        if ($synOut -and $synOut.Status -ne 'OK') {
            $intercepts++
            Write-Host " [$now] Intercept #${intercepts}: Audio restore triggered!" -ForegroundColor Red
            Enable-PnpDevice -InstanceId $synOut.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
            [AudioController]::SetDefaultAudio($synOut.InstanceId)
        } else {
            $counter++
            if ($counter % 20 -eq 0) {
                Write-Host " [$now] Audio protected & stable." -ForegroundColor DarkGreen
            }
        }
        Start-Sleep -Milliseconds 500
    }
}

function Invoke-FixGlobal {
    Write-Host ""
    Write-Host ">>> $((Get-Text 'Opt4Title'))..." -ForegroundColor Cyan

    $schemes = powercfg /list 2>&1
    $guids = [regex]::Matches($schemes, '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') | ForEach-Object { $_.Value } | Select-Object -Unique
    foreach ($guid in $guids) {
        powercfg /SETACVALUEINDEX $guid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
        powercfg /SETDCVALUEINDEX $guid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
    }
    powercfg /SETACTIVE SCHEME_CURRENT

    if (-not (Test-Path 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio')) {
        New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio' -Force | Out-Null
    }
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio' -Name 'UserDuckingPreference' -Value 3 -Type DWord

    try {
        $usbHubs = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi -ErrorAction SilentlyContinue | Where-Object { $_.InstanceName -match 'USB' }
        foreach ($hub in $usbHubs) {
            if ($hub.Enable) {
                $hub.Enable = $false
                $hub.Put() | Out-Null
            }
        }
    } catch {}

    Write-Host ""
    Write-Host " $((Get-Text 'Success'))" -ForegroundColor Green
    Write-Host ""
    Write-Host "$((Get-Text 'PressKey'))" -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# --- LOOP PRINCIPAL DO MENU ---
while ($true) {
    Show-Header

    Write-Host " $((Get-Text 'MenuTitle' 'MENU DE OPCOES:'))" -ForegroundColor White
    Write-Host ""

    Write-Host "  $((Get-Text 'Opt1Title'))" -ForegroundColor Green
    Write-Host "      * $((Get-Text 'Opt1Desc'))" -ForegroundColor Gray
    Write-Host "      * $((Get-Text 'Opt1Tip'))" -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  $((Get-Text 'Opt2Title'))" -ForegroundColor Yellow
    Write-Host "      * $((Get-Text 'Opt2Desc'))" -ForegroundColor Gray
    Write-Host "      * $((Get-Text 'Opt2Tip'))" -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  $((Get-Text 'Opt3Title'))" -ForegroundColor Magenta
    Write-Host "      * $((Get-Text 'Opt3Desc'))" -ForegroundColor Gray
    Write-Host "      * $((Get-Text 'Opt3Tip'))" -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  $((Get-Text 'Opt4Title'))" -ForegroundColor Cyan
    Write-Host "      * $((Get-Text 'Opt4Desc'))" -ForegroundColor Gray
    Write-Host "      * $((Get-Text 'Opt4Tip'))" -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  $((Get-Text 'Opt5Title'))" -ForegroundColor White
    Write-Host "      * $((Get-Text 'Opt5Desc'))" -ForegroundColor Gray
    Write-Host ""

    Write-Host "  $((Get-Text 'Opt6Title'))" -ForegroundColor DarkCyan
    Write-Host "      * $((Get-Text 'Opt6Desc'))" -ForegroundColor Gray
    Write-Host ""

    Write-Host "  $((Get-Text 'OptQTitle'))" -ForegroundColor DarkGray
    Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkCyan
    
    $choice = Read-Host " $((Get-Text 'Prompt' 'Escolha uma opcao:'))"
    
    switch ($choice) {
        '1' { Invoke-ModoEstavel }
        '2' { Invoke-SwarmAutoPilot }
        '3' { Invoke-SentinelaAtiva }
        '4' { Invoke-FixGlobal }
        '5' { Start-Process "mmsys.cpl" }
        '6' { Show-LanguageSelector }
        '0' { [System.Environment]::Exit(0) }
        'Q' { [System.Environment]::Exit(0) }
        'q' { [System.Environment]::Exit(0) }
    }
}
