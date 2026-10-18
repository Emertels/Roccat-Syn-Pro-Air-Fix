# ==============================================================================
#  ROCCAT SYN PRO AIR - MULTILINGUAL MASTER MANAGER (v1.2.0)
#  Auto-detects Windows language from 10 native supported languages
#  Developed with Antigravity & Codex
# ==============================================================================

# Auto-elevacao transparente para Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $elevatedArguments = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process -FilePath powershell.exe -ArgumentList $elevatedArguments -Verb RunAs
    exit
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$host.UI.RawUI.WindowTitle = "ROCCAT Syn Pro Air - Master Manager (Antigravity & Codex)"

$driverName = "WavesTBVirtual"
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$driverName"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configFile = Join-Path $scriptDir "config.json"
$i18nFile = Join-Path $scriptDir "i18n.json"
$managerDataDir = Join-Path $env:LOCALAPPDATA "RoccatSynProManager"
$configDataFile = Join-Path $managerDataDir 'config.json'
$stateBackupFile = Join-Path $managerDataDir "system-backup.json"
$diagnosticDir = Join-Path $managerDataDir "diagnostics"
$sessionStart = Get-Date -Format "dd/MM/yyyy 'as' HH:mm:ss"

try {
    New-Item -ItemType Directory -Path $managerDataDir -Force -ErrorAction Stop | Out-Null
    New-Item -ItemType Directory -Path $diagnosticDir -Force -ErrorAction Stop | Out-Null
} catch {
    $managerDataDir = $scriptDir
    $stateBackupFile = Join-Path $managerDataDir "system-backup.json"
    $configDataFile = Join-Path $managerDataDir 'config.json'
    $diagnosticDir = Join-Path $managerDataDir "diagnostics"
    try { New-Item -ItemType Directory -Path $diagnosticDir -Force -ErrorAction Stop | Out-Null } catch {}
}

$wavesServiceBackupFile = Join-Path $managerDataDir 'waves-service-backup.json'
$swarmSessionFile = Join-Path $managerDataDir 'swarm-session.json'

# As versoes do ZIP recebem o JSON embutido neste ponto; no repositorio, usa-se
# i18n.json como fonte de edicao quando o marcador ainda não foi compilado.
$embeddedTranslationsJson = @'
@@ROCCAT_I18N_JSON_EMBED@@
'@
$translations = $null
try { $translations = $embeddedTranslationsJson | ConvertFrom-Json -ErrorAction Stop } catch {}
if (-not $translations -and (Test-Path $i18nFile)) {
    try { $translations = Get-Content -LiteralPath $i18nFile -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop } catch {}
}

function Get-CurrentLanguage {
    # A escolha salva no perfil do usuario precisa prevalecer sobre um arquivo
    # antigo na pasta portatil, que pode ser somente leitura.
    foreach ($path in @($configDataFile, $configFile)) {
        if (Test-Path $path) {
            try {
                $cfg = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($cfg.Language -in @('pt-BR','en-US','es-ES','fr-FR','de-DE','it-IT','ru-RU','ja-JP','zh-CN','ko-KR')) { return $cfg.Language }
            } catch {}
        }
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

$script:currentLanguage = Get-CurrentLanguage

function Get-Text($key, $defaultText = "") {
    $lang = $script:currentLanguage
    if ($translations -and $translations.$lang -and $translations.$lang.$key) {
        return $translations.$lang.$key
    }
    if ($translations -and $translations.'pt-BR' -and $translations.'pt-BR'.$key) {
        return $translations.'pt-BR'.$key
    }
    return $defaultText
}

function Set-CurrentLanguage($lang) {
    if ($lang -notin @('pt-BR','en-US','es-ES','fr-FR','de-DE','it-IT','ru-RU','ja-JP','zh-CN','ko-KR')) {
        Write-Host " $((Get-Text 'InvalidOption' 'Idioma inválido.'))" -ForegroundColor Yellow
        return $false
    }
    $json = @{ Language = $lang } | ConvertTo-Json
    foreach ($target in @($configDataFile, $configFile)) {
        $temp = "$target.tmp"
        try {
            $parent = Split-Path -Parent $target
            if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null }
            Set-Content -LiteralPath $temp -Value $json -Encoding UTF8 -ErrorAction Stop
            Move-Item -LiteralPath $temp -Destination $target -Force -ErrorAction Stop
            $script:currentLanguage = $lang
            return $true
        } catch { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
    }
    Write-Host " $((Get-Text 'ActionFailed' 'Não foi possível salvar o idioma.'))" -ForegroundColor Red
    return $false
}

function Show-LanguageSelector {
    Clear-Host
    Write-Host "==============================================================================" -ForegroundColor DarkCyan
    Write-Host "                     SELECT LANGUAGE / SELECIONE O IDIOMA                     " -ForegroundColor Cyan
    Write-Host "==============================================================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  [1] Português (Brasil)     - pt-BR" -ForegroundColor White
    Write-Host "  [2] English (US)           - en-US" -ForegroundColor White
    Write-Host "  [3] Español                - es-ES" -ForegroundColor White
    Write-Host "  [4] Français               - fr-FR" -ForegroundColor White
    Write-Host "  [5] Deutsch                - de-DE" -ForegroundColor White
    Write-Host "  [6] Italiano               - it-IT" -ForegroundColor White
    Write-Host "  [7] Russian (ru-RU)" -ForegroundColor White
    Write-Host "  [8] Japanese (ja-JP)" -ForegroundColor White
    Write-Host "  [9] Chinese (zh-CN)" -ForegroundColor White
    Write-Host "  [10] Korean (ko-KR)" -ForegroundColor White
    Write-Host ""
    Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkCyan
    $sel = Read-MenuChoice 'Choose option [1-10] (ESC: back to menu)'
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
        '__ESC__' { return }
        default { Write-Host " $((Get-Text 'InvalidOption' 'Opção inválida.'))" -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
    }
}

function Get-PowerSchemeGuids {
    $raw = powercfg.exe /list 2>&1
    $matches = [regex]::Matches(($raw -join "`n"), '(?i)\b[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\b')
    return @($matches | ForEach-Object { $_.Value } | Select-Object -Unique)
}

function Get-UsbSuspendValues($schemeGuid) {
    $raw = powercfg.exe /query $schemeGuid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 2>&1
    if ($LASTEXITCODE -ne 0) { return $null }
    $matches = [regex]::Matches(($raw -join "`n"), '(?i)0x([0-9a-f]{8})')
    if ($matches.Count -lt 2) { return $null }
    $ac = [Convert]::ToUInt32($matches[$matches.Count - 2].Groups[1].Value, 16)
    $dc = [Convert]::ToUInt32($matches[$matches.Count - 1].Groups[1].Value, 16)
    return [pscustomobject]@{ AC = $ac; DC = $dc }
}

function Get-SynOutputEndpoints($audioDevices = $null) {
    $pattern = '(?i)(SYN.*PRO.*AIR|HEADSET.*SYN|SYN.*HEADSET)'
    $micPattern = '(?i)(MIC|MICROPHONE|MICROFONE|MIKROFON|マイク|麦克风|마이크)'
    try {
        if ($null -eq $audioDevices) { $audioDevices = @(Get-PnpDevice -Class 'AudioEndpoint' -ErrorAction Stop) }
        return @($audioDevices | Where-Object {
            $_.FriendlyName -match $pattern -and $_.FriendlyName -notmatch $micPattern
        })
    } catch { return @() }
}

function Get-SynMicrophoneEndpoint($audioDevices = $null) {
    $pattern = '(?i)(SYN.*PRO.*AIR|MICROFONE.*SYN|MICROPHONE.*SYN|SYN.*MIC)'
    try {
        if ($null -eq $audioDevices) { $audioDevices = @(Get-PnpDevice -Class 'AudioEndpoint' -ErrorAction Stop) }
        return $audioDevices | Where-Object {
            $_.FriendlyName -match $pattern -and $_.FriendlyName -match '(?i)(MIC|MICROPHONE|MICROFONE|MIKROFON|マイク|麦克风|마이크)'
        } | Select-Object -First 1
    } catch { return $null }
}

function Get-EndpointProblemCode($instanceId) {
    try {
        $property = Get-PnpDeviceProperty -InstanceId $instanceId -KeyName 'DEVPKEY_Device_ProblemCode' -ErrorAction Stop
        return [int]$property.Data
    } catch { return $null }
}

function Initialize-CoreAudioApi {
    if ('RoccatSynProAudioFix.CoreAudio' -as [type]) { return $true }
    $source = @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace RoccatSynProAudioFix {
    public enum EDataFlow { Render = 0, Capture = 1, All = 2 }
    public enum ERole { Console = 0, Multimedia = 1, Communications = 2 }

    [StructLayout(LayoutKind.Sequential)]
    public struct PropertyKey { public Guid FormatId; public uint PropertyId; }

    [StructLayout(LayoutKind.Explicit, Size = 24)]
    public struct PropVariant { [FieldOffset(0)] public ushort VariantType; [FieldOffset(8)] public IntPtr PointerValue; }

    public sealed class EndpointInfo {
        public string Id;
        public string Name;
        public int State;
    }

    [ComImport, Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IMMDeviceEnumerator {
        [PreserveSig] int EnumAudioEndpoints(EDataFlow flow, int stateMask, out IMMDeviceCollection devices);
        [PreserveSig] int GetDefaultAudioEndpoint(EDataFlow flow, ERole role, out IMMDevice device);
        [PreserveSig] int GetDevice([MarshalAs(UnmanagedType.LPWStr)] string id, out IMMDevice device);
        [PreserveSig] int RegisterEndpointNotificationCallback(IntPtr callback);
        [PreserveSig] int UnregisterEndpointNotificationCallback(IntPtr callback);
    }

    [ComImport, Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IMMDevice {
        [PreserveSig] int Activate(ref Guid iid, int clsctx, IntPtr activationParams, out IntPtr instance);
        [PreserveSig] int OpenPropertyStore(int access, out IPropertyStore properties);
        [PreserveSig] int GetId([MarshalAs(UnmanagedType.LPWStr)] out string id);
        [PreserveSig] int GetState(out int state);
    }

    [ComImport, Guid("0BD7A1BE-7A1A-44DB-8397-CC5392387B5E"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IMMDeviceCollection {
        [PreserveSig] int GetCount(out uint count);
        [PreserveSig] int Item(uint index, out IMMDevice device);
    }

    [ComImport, Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IPropertyStore {
        [PreserveSig] int GetCount(out uint count);
        [PreserveSig] int GetAt(uint index, out PropertyKey key);
        [PreserveSig] int GetValue(ref PropertyKey key, out PropVariant value);
        [PreserveSig] int SetValue(ref PropertyKey key, ref PropVariant value);
        [PreserveSig] int Commit();
    }

    [ComImport, Guid("F8679F50-850A-41CF-9C72-430F290290C8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IPolicyConfig {
        [PreserveSig] int GetMixFormat([MarshalAs(UnmanagedType.LPWStr)] string id, IntPtr format);
        [PreserveSig] int GetDeviceFormat([MarshalAs(UnmanagedType.LPWStr)] string id, int defaultFormat, IntPtr format);
        [PreserveSig] int ResetDeviceFormat([MarshalAs(UnmanagedType.LPWStr)] string id);
        [PreserveSig] int SetDeviceFormat([MarshalAs(UnmanagedType.LPWStr)] string id, IntPtr endpointFormat, IntPtr mixFormat);
        [PreserveSig] int GetProcessingPeriod([MarshalAs(UnmanagedType.LPWStr)] string id, int defaultPeriod, IntPtr defaultValue, IntPtr minimumValue);
        [PreserveSig] int SetProcessingPeriod([MarshalAs(UnmanagedType.LPWStr)] string id, IntPtr period);
        [PreserveSig] int GetShareMode([MarshalAs(UnmanagedType.LPWStr)] string id, IntPtr mode);
        [PreserveSig] int SetShareMode([MarshalAs(UnmanagedType.LPWStr)] string id, IntPtr mode);
        [PreserveSig] int GetPropertyValue([MarshalAs(UnmanagedType.LPWStr)] string id, ref PropertyKey key, IntPtr value);
        [PreserveSig] int SetPropertyValue([MarshalAs(UnmanagedType.LPWStr)] string id, ref PropertyKey key, IntPtr value);
        [PreserveSig] int SetDefaultEndpoint([MarshalAs(UnmanagedType.LPWStr)] string id, ERole role);
        [PreserveSig] int SetEndpointVisibility([MarshalAs(UnmanagedType.LPWStr)] string id, int visible);
    }

    public static class CoreAudio {
        private static readonly Guid EnumeratorClass = new Guid("BCDE0395-E52F-467C-8E3D-C4579291692E");
        private static readonly Guid PolicyConfigClass = new Guid("870AF99C-171D-4F9E-AF0D-E63DF40C2BC9");
        private static readonly Guid FriendlyNameFormat = new Guid("A45C254E-DF1C-4EFD-8020-67D146A850E0");

        private static IMMDeviceEnumerator CreateEnumerator() {
            return (IMMDeviceEnumerator)Activator.CreateInstance(Type.GetTypeFromCLSID(EnumeratorClass, true));
        }

        private static string GetFriendlyName(IMMDevice device) {
            IPropertyStore store = null;
            PropVariant value = new PropVariant();
            try {
                int hr = device.OpenPropertyStore(0, out store);
                if (hr < 0) Marshal.ThrowExceptionForHR(hr);
                PropertyKey key = new PropertyKey { FormatId = FriendlyNameFormat, PropertyId = 14 };
                hr = store.GetValue(ref key, out value);
                if (hr < 0) Marshal.ThrowExceptionForHR(hr);
                if (value.VariantType == 31 && value.PointerValue != IntPtr.Zero) return Marshal.PtrToStringUni(value.PointerValue);
                return "(unnamed audio endpoint)";
            } finally {
                PropVariantClear(ref value);
                if (store != null && Marshal.IsComObject(store)) Marshal.FinalReleaseComObject(store);
            }
        }

        [DllImport("ole32.dll")]
        private static extern int PropVariantClear(ref PropVariant value);

        public static EndpointInfo[] GetActiveRenderEndpoints() {
            return GetEndpoints(EDataFlow.Render, 1);
        }

        public static EndpointInfo[] GetAllAudioEndpoints() {
            return GetEndpoints(EDataFlow.All, 15);
        }

        private static EndpointInfo[] GetEndpoints(EDataFlow flow, int mask) {
            IMMDeviceEnumerator enumerator = null;
            IMMDeviceCollection collection = null;
            List<EndpointInfo> result = new List<EndpointInfo>();
            try {
                enumerator = CreateEnumerator();
                int hr = enumerator.EnumAudioEndpoints(flow, mask, out collection);
                if (hr < 0) Marshal.ThrowExceptionForHR(hr);
                uint count = 0;
                hr = collection.GetCount(out count);
                if (hr < 0) Marshal.ThrowExceptionForHR(hr);
                for (uint i = 0; i < count; i++) {
                    IMMDevice device = null;
                    try {
                        hr = collection.Item(i, out device);
                        if (hr < 0 || device == null) continue;
                        string id;
                        int state;
                        hr = device.GetId(out id);
                        if (hr < 0) continue;
                        hr = device.GetState(out state);
                        if (hr < 0) continue;
                        result.Add(new EndpointInfo { Id = id, Name = GetFriendlyName(device), State = state });
                    } finally { if (device != null && Marshal.IsComObject(device)) Marshal.FinalReleaseComObject(device); }
                }
                return result.ToArray();
            } finally {
                if (collection != null && Marshal.IsComObject(collection)) Marshal.FinalReleaseComObject(collection);
                if (enumerator != null && Marshal.IsComObject(enumerator)) Marshal.FinalReleaseComObject(enumerator);
            }
        }

        public static string GetDefaultRenderEndpointId(ERole role) {
            return GetDefaultEndpointId(EDataFlow.Render, role);
        }

        public static string GetDefaultCaptureEndpointId(ERole role) {
            return GetDefaultEndpointId(EDataFlow.Capture, role);
        }

        private static string GetDefaultEndpointId(EDataFlow flow, ERole role) {
            IMMDeviceEnumerator enumerator = null;
            IMMDevice device = null;
            try {
                enumerator = CreateEnumerator();
                int hr = enumerator.GetDefaultAudioEndpoint(flow, role, out device);
                if (hr < 0 || device == null) return null;
                string id;
                hr = device.GetId(out id);
                if (hr < 0) Marshal.ThrowExceptionForHR(hr);
                return id;
            } finally {
                if (device != null && Marshal.IsComObject(device)) Marshal.FinalReleaseComObject(device);
                if (enumerator != null && Marshal.IsComObject(enumerator)) Marshal.FinalReleaseComObject(enumerator);
            }
        }

        public static bool IsRenderEndpointActive(string id) {
            IMMDeviceEnumerator enumerator = null;
            IMMDevice device = null;
            try {
                enumerator = CreateEnumerator();
                int hr = enumerator.GetDevice(id, out device);
                if (hr < 0 || device == null) return false;
                int state;
                hr = device.GetState(out state);
                return hr >= 0 && (state & 1) == 1;
            } finally {
                if (device != null && Marshal.IsComObject(device)) Marshal.FinalReleaseComObject(device);
                if (enumerator != null && Marshal.IsComObject(enumerator)) Marshal.FinalReleaseComObject(enumerator);
            }
        }

        public static int SetDefaultRenderEndpoint(string id) {
            object policyObject = null;
            IPolicyConfig policy = null;
            try {
                policyObject = Activator.CreateInstance(Type.GetTypeFromCLSID(PolicyConfigClass, true));
                policy = (IPolicyConfig)policyObject;
                foreach (ERole role in new ERole[] { ERole.Console, ERole.Multimedia, ERole.Communications }) {
                    int hr = policy.SetDefaultEndpoint(id, role);
                    if (hr < 0) return hr;
                }
                return 0;
            } finally { if (policyObject != null && Marshal.IsComObject(policyObject)) Marshal.FinalReleaseComObject(policyObject); }
        }

        public static int SetDefaultRenderEndpointForRole(string id, ERole role) {
            object policyObject = null;
            IPolicyConfig policy = null;
            try {
                policyObject = Activator.CreateInstance(Type.GetTypeFromCLSID(PolicyConfigClass, true));
                policy = (IPolicyConfig)policyObject;
                return policy.SetDefaultEndpoint(id, role);
            } finally { if (policyObject != null && Marshal.IsComObject(policyObject)) Marshal.FinalReleaseComObject(policyObject); }
        }
    }
}
'@
    try {
        Add-Type -TypeDefinition $source -Language CSharp -ErrorAction Stop
        return $true
    } catch {
        Write-Host " $((Get-Text 'AudioApiFailed' 'A API de áudio do Windows não ficou disponível.')) $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Get-DefaultRenderEndpointSnapshot {
    if (-not (Initialize-CoreAudioApi)) { return $null }
    $roles = [ordered]@{}
    foreach ($roleName in @('Console', 'Multimedia', 'Communications')) {
        try {
            $role = [Enum]::Parse([RoccatSynProAudioFix.ERole], $roleName)
            $id = [RoccatSynProAudioFix.CoreAudio]::GetDefaultRenderEndpointId($role)
            $roles[$roleName] = $id
        } catch { $roles[$roleName] = $null }
    }
    return [pscustomobject]$roles
}

function Get-RenderEndpointName($endpointId, $endpointList = $null) {
    if (-not $endpointId) { return (Get-Text 'NoDefaultOutput' 'nenhuma saída padrão') }
    if ($null -eq $endpointList) {
        try { $endpointList = [RoccatSynProAudioFix.CoreAudio]::GetActiveRenderEndpoints() } catch { $endpointList = @() }
    }
    $match = @($endpointList | Where-Object { $_.Id -eq $endpointId } | Select-Object -First 1)
    if ($match.Count -gt 0) { return [string]$match[0].Name }
    return [string]$endpointId
}


function Restore-RenderEndpointSnapshot($snapshot) {
    if (-not $snapshot -or -not (Initialize-CoreAudioApi)) { return $false }
    $ok = $true
    foreach ($roleName in @('Console', 'Multimedia', 'Communications')) {
        $id = $snapshot.$roleName
        if (-not $id) { $ok = $false; continue }
        try {
            $role = [Enum]::Parse([RoccatSynProAudioFix.ERole], $roleName)
            $hr = [RoccatSynProAudioFix.CoreAudio]::SetDefaultRenderEndpointForRole([string]$id, $role)
            if ($hr -lt 0) { $ok = $false }
        } catch { $ok = $false }
    }
    $actual = Get-DefaultRenderEndpointSnapshot
    foreach ($roleName in @('Console', 'Multimedia', 'Communications')) {
        if ($snapshot.$roleName -and $actual.$roleName -ne $snapshot.$roleName) { $ok = $false }
    }
    return $ok
}

function Get-WavesDriverRunning {
    # sc.exe devolve o estado rapidamente e também funciona em Windows onde a
    # consulta CIM demora ou falha. O campo pode ter rótulo localizado; o estado
    # RUNNING/STOPPED continua identificável pelo número e pelo token final.
    try {
        $serviceText = (sc.exe query $driverName 2>&1 | Out-String)
        $scExitCode = $LASTEXITCODE
        if ($scExitCode -eq 0 -and $serviceText -match '(?im):\s*\d+\s+RUNNING\b') { return $true }
        if ($scExitCode -eq 0 -and $serviceText -match '(?im):\s*\d+\s+STOPPED\b') { return $false }
    } catch {}

    # CIM permanece como fallback quando sc.exe não consegue informar o estado.
    try {
        $driver = Get-CimInstance Win32_SystemDriver -Filter "Name='$driverName'" -ErrorAction Stop
        if ($driver -and $driver.State -eq 'Running') { return $true }
        if ($driver -and $driver.State -eq 'Stopped') { return $false }
    } catch {}
    return $null
}


function Get-SystemAudioInfo {
    $state = @{
        DriverInstalled = (Test-Path $regPath)
        DriverRunning   = $false
        DriverStateKnown = $false
        DriverStartMode = "N/A"
        UsbDongleStatus = $false
        HeadsetStatus   = "Não encontrado"
        MicStatus       = "Não encontrado"
        HeadsetDevId    = ""
        HeadsetProblem  = $null
        HeadsetAudioActive = $false
        MicAudioActive = $false
        AudioService    = (Get-WavesAudioServiceSnapshot)
    }

    if ($state.DriverInstalled) {
        $driverRunning = Get-WavesDriverRunning
        if ($null -ne $driverRunning) {
            $state.DriverRunning = [bool]$driverRunning
            $state.DriverStateKnown = $true
        }
        try { $state.DriverStartMode = (Get-ItemProperty -Path $regPath -Name 'Start' -ErrorAction Stop).Start } catch {}
    }

    try {
        $dongleNodes = @(Get-PnpDevice -Class 'USB' -PresentOnly -ErrorAction Stop | Where-Object { $_.InstanceId -like 'USB\VID_1E7D&PID_3A3B*' })
        $state.UsbDongleStatus = [bool]($dongleNodes | Where-Object { $_.Status -eq 'OK' } | Select-Object -First 1)
    } catch {}

    $audioDevices = @(Get-PnpDevice -Class 'AudioEndpoint' -ErrorAction SilentlyContinue)
    $headset = Get-SynOutputEndpoints $audioDevices | Select-Object -First 1
    if ($headset) {
        $state.HeadsetStatus = $headset.Status
        $state.HeadsetDevId = $headset.InstanceId
        $state.HeadsetProblem = Get-EndpointProblemCode $headset.InstanceId
    }

    $mic = Get-SynMicrophoneEndpoint $audioDevices
    if ($mic) { $state.MicStatus = $mic.Status }

    $availability = Get-AudioAvailability
    $state.HeadsetAudioActive = @($availability.Endpoints | Where-Object { $_.Name -match '(?i)SYN.*PRO.*AIR' -and $_.Id -match '^\{0\.0\.0\.' -and ($_.State -band 1) -eq 1 }).Count -gt 0
    $state.MicAudioActive = @($availability.Endpoints | Where-Object { $_.Name -match '(?i)SYN.*PRO.*AIR' -and $_.Name -notmatch '(?i)Sidetone' -and $_.Id -match '^\{0\.0\.1\.' -and ($_.State -band 1) -eq 1 }).Count -gt 0

    return $state
}


function Restore-SystemBackup {
    if (-not (Test-Path $stateBackupFile)) {
        Write-Host " $((Get-Text 'NoBackup' 'Nenhuma cópia anterior foi encontrada.'))" -ForegroundColor Yellow
        return $false
    }

    $ok = $true
    try { $snapshot = Get-Content -LiteralPath $stateBackupFile -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop }
    catch {
        Write-Host " $((Get-Text 'RestoreFailed' 'Não foi possível ler a cópia das configurações.'))" -ForegroundColor Red
        return $false
    }

    $savedPowerSchemes = @($snapshot.PowerSchemes)
    $currentPowerGuids = @(Get-PowerSchemeGuids)
    $savedByGuid = @{}
    foreach ($scheme in $savedPowerSchemes) {
        if ($scheme.Guid -and $null -ne $scheme.AC -and $null -ne $scheme.DC) { $savedByGuid[[string]$scheme.Guid] = $scheme }
    }
    $missingPower = @($currentPowerGuids | Where-Object { -not $savedByGuid.ContainsKey([string]$_) })
    if ($currentPowerGuids.Count -eq 0 -or $missingPower.Count -gt 0 -or
        ($snapshot.PSObject.Properties.Name -notcontains 'DuckKeyExisted')) {
        Write-Host " $((Get-Text 'RestoreFailed' 'A cópia não inclui todos os valores necessários; nada foi restaurado.'))" -ForegroundColor Red
        return $false
    }
    foreach ($scheme in $savedPowerSchemes) {
        if ($null -eq $scheme.AC -or $null -eq $scheme.DC) { $ok = $false; continue }
        powercfg.exe /setacvalueindex $scheme.Guid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 ([int]$scheme.AC) 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { $ok = $false }
        powercfg.exe /setdcvalueindex $scheme.Guid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 ([int]$scheme.DC) 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { $ok = $false }
        $restoredValues = Get-UsbSuspendValues $scheme.Guid
        if (-not $restoredValues -or $restoredValues.AC -ne [int]$scheme.AC -or $restoredValues.DC -ne [int]$scheme.DC) { $ok = $false }
    }

    try {
        if ($null -ne $snapshot.DuckValue) {
            if (-not (Test-Path 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio')) { New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio' -Force | Out-Null }
            Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio' -Name UserDuckingPreference -Value ([int]$snapshot.DuckValue) -Type DWord -ErrorAction Stop
        } else {
            Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio' -Name UserDuckingPreference -ErrorAction SilentlyContinue
        }
        $currentDuck = $null
        try { $currentDuck = (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio' -Name UserDuckingPreference -ErrorAction Stop).UserDuckingPreference } catch {}
        if ($null -ne $snapshot.DuckValue -and $currentDuck -ne [int]$snapshot.DuckValue) { $ok = $false }
        if ($null -eq $snapshot.DuckValue -and $null -ne $currentDuck) { $ok = $false }
    } catch { $ok = $false }

    foreach ($savedHub in @($snapshot.UsbHubs)) {
        try {
            $hub = Get-WmiObject -Namespace root\wmi -Class MSPower_DeviceEnable -ErrorAction Stop |
                Where-Object { $_.InstanceName -eq $savedHub.InstanceName } | Select-Object -First 1
            if ($hub) {
                $hub.Enable = [bool]$savedHub.Enable
                $null = $hub.Put()
                $checkHub = Get-WmiObject -Namespace root\wmi -Class MSPower_DeviceEnable -ErrorAction Stop |
                    Where-Object { $_.InstanceName -eq $savedHub.InstanceName } | Select-Object -First 1
                if (-not $checkHub -or [bool]$checkHub.Enable -ne [bool]$savedHub.Enable) { $ok = $false }
            } else { $ok = $false }
        } catch { $ok = $false }
    }

    # Energy restoration is independent of the driver/service session backups.
    if ($ok) { Write-Host " $((Get-Text 'RestoreDone' 'Configurações anteriores restauradas.'))" -ForegroundColor Green }
    else { Write-Host " $((Get-Text 'RestoreFailed' 'A restauração ficou incompleta; confira as mensagens acima.'))" -ForegroundColor Red }
    return $ok
}

function Get-AudioStateLabel($state) {
    switch ([int]$state) {
        1 { return (Get-Text 'AudioStateActive' 'Ativo') }
        2 { return (Get-Text 'AudioStateDisabled' 'Desativado') }
        4 { return (Get-Text 'AudioStateAbsent' 'Ausente') }
        8 { return (Get-Text 'AudioStateDisconnected' 'Desconectado') }
        default { return "$(Get-Text 'AudioStateOther' 'Estado') $state" }
    }
}

function Get-AudioFlowLabel($flow) {
    switch ([string]$flow) {
        '0' { return (Get-Text 'AudioOutputFlow' 'Saída / render') }
        '1' { return (Get-Text 'AudioCaptureFlow' 'Microfone / captura') }
        default { return "$(Get-Text 'AudioFlowOther' 'Fluxo') $flow" }
    }
}

function Show-DiagnosticReport {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $reportPath = Join-Path $diagnosticDir "Roccat-SynPro-Diagnóstico-$stamp.txt"
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Diagnóstico ROCCAT Syn Pro Air - $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))")
    $lines.Add("Computador: $env:COMPUTERNAME")
    $lines.Add('')
    $lines.Add('=== Endpoints de áudio PnP ===')
    $lines.Add('O status PnP confirma enumeracao do endpoint; não confirma áudio em reprodução ou gravacao.')
    $lines.Add('O script não consegue ler se o headset sem fio esta ligado; registra somente o estado visto pelo Windows e pelo dongle.')

    $audioDevices = @(Get-PnpDevice -Class AudioEndpoint -ErrorAction SilentlyContinue | Where-Object {
        $_.FriendlyName -match '(?i)(SYN.*PRO.*AIR|HEADSET.*SYN|SYN.*HEADSET)'
    })
    foreach ($device in $audioDevices) {
        $problem = Get-EndpointProblemCode $device.InstanceId
        $parent = ''
        try { $parent = (Get-PnpDeviceProperty -InstanceId $device.InstanceId -KeyName 'DEVPKEY_Device_Parent' -ErrorAction Stop).Data } catch {}
        $lines.Add("Nome: $($device.FriendlyName) | Status: $($device.Status) | ProblemCode: $problem")
        $lines.Add("InstanceId: $($device.InstanceId)")
        $lines.Add("Parent: $parent")
    }
    if ($audioDevices.Count -eq 0) { $lines.Add('Nenhum endpoint SYN Pro Air localizado.') }

    $lines.Add('')
    $lines.Add('=== Saidas de reprodução padrão do Windows ===')
    if (Initialize-CoreAudioApi) {
        $defaultSnapshot = Get-DefaultRenderEndpointSnapshot
        $activeRender = @()
        try { $activeRender = @([RoccatSynProAudioFix.CoreAudio]::GetActiveRenderEndpoints()) } catch {}
        if ($defaultSnapshot) {
            foreach ($roleName in @('Console', 'Multimedia', 'Communications')) {
                $id = $defaultSnapshot.$roleName
                $name = Get-RenderEndpointName $id $activeRender
                $lines.Add("$roleName = $name | ID: $id")
            }
        } else { $lines.Add('Não foi possível ler os papéis de reprodução.') }
    } else { $lines.Add('API de saída padrão indisponível.') }

    $lines.Add('')
    $lines.Add('=== Dongle USB ===')
    $dongles = @(Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -like 'USB\VID_1E7D&PID_3A3B*' })
    foreach ($device in $dongles) { $lines.Add("$($device.Status) | $($device.Class) | $($device.FriendlyName) | $($device.InstanceId)") }
    if ($dongles.Count -eq 0) { $lines.Add('Dongle não encontrado na arvore PnP.') }

    $lines.Add('')
    $lines.Add('=== Driver WavesTBVirtual ===')
    $lines.Add((sc.exe query $driverName 2>&1 | Out-String).TrimEnd())
    $lines.Add((sc.exe qc $driverName 2>&1 | Out-String).TrimEnd())
    try {
        $driver = Get-CimInstance Win32_SystemDriver -Filter "Name='$driverName'" -ErrorAction Stop
        $lines.Add("State=$($driver.State); StartMode=$($driver.StartMode); Path=$($driver.PathName)")
    } catch { $lines.Add('Driver não encontrado via CIM.') }

    $lines.Add('')
    $lines.Add('=== Servicos de áudio ===')
    foreach ($serviceName in @('Audiosrv','AudioEndpointBuilder','WavesTBSvc')) {
        try { $service = Get-Service -Name $serviceName -ErrorAction Stop; $lines.Add("$serviceName = $($service.Status)") }
        catch { $lines.Add("$serviceName = não consultado") }
    }

    $wavesService = Get-WavesAudioServiceSnapshot
    $lines.Add('Waves Audio Services startup/runtime: ' + ($wavesService | ConvertTo-Json -Compress))
    $captureDefaults = Get-DefaultCaptureEndpointSnapshot
    $lines.Add('Default capture roles (read only): ' + ($captureDefaults | ConvertTo-Json -Compress))
    foreach ($process in @(Get-Process -Name ROCCAT_Swarm,ROCCAT_Swarm_Monitor,ROCCAT_Waves_Driver,WavesLoopback64 -ErrorAction SilentlyContinue)) {
        $lines.Add("Observed process: $($process.ProcessName) | PID=$($process.Id)")
    }
    $lines.Add('Process presence and event 65 alone do not identify the initiator of a change.')

    $lines.Add('')
    $lines.Add('=== Suspensão seletiva USB (plano atual) ===')
    $lines.Add((powercfg.exe /query SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 2>&1 | Out-String).TrimEnd())

    $lines.Add('')
    $lines.Add('=== Eventos Audio 65 recentes: estado 1=Ativo, 2=Desativado ===')
    try {
        $events = @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Audio/Operational'; Id = 65; StartTime = (Get-Date).AddHours(-2) } -MaxEvents 60 -ErrorAction SilentlyContinue | Sort-Object TimeCreated)
        foreach ($event in $events) {
            $data = @($event.Properties | ForEach-Object { $_.Value })
            if ($data.Count -ge 4 -and $data[0] -match '(?i)SYN') {
                $lines.Add("$($event.TimeCreated.ToString('HH:mm:ss.fff')) | $($data[0]) | fluxo=$($data[2]) ($(Get-AudioFlowLabel $data[2])) | estado=$($data[3]) ($(Get-AudioStateLabel $data[3])) | $($data[1])")
            }
        }
        if ($events.Count -eq 0) { $lines.Add('Nenhum evento Audio 65 foi encontrado nas ultimas duas horas.') }
    } catch { $lines.Add('Log Audio/Operational indisponível.') }

    $lines.Add('')
    $lines.Add('=== Eventos recentes de USB/PnP relacionados ao dongle ===')
    try {
        $systemEvents = Get-WinEvent -FilterHashtable @{ LogName = 'System'; StartTime = (Get-Date).AddHours(-2) } -MaxEvents 250 -ErrorAction Stop |
            Where-Object { $_.ProviderName -match '(?i)(Kernel-PnP|USB|UserPnp|DriverFrameworks)' } |
            Sort-Object TimeCreated
        $matchedEvents = @($systemEvents | ForEach-Object {
            $message = $_.Message
            if ($message -match '(?i)(VID_1E7D|PID_3A3B|SYN.?PRO.?AIR|WavesTBVirtual)') {
                [pscustomobject]@{ Event = $_; Message = ($message -replace '[\r\n]+', ' ') }
            }
        })
        foreach ($item in ($matchedEvents | Select-Object -Last 50)) {
            $event = $item.Event
            $lines.Add("$($event.TimeCreated.ToString('HH:mm:ss.fff')) | ID=$($event.Id) | $($event.ProviderName) | $($item.Message)")
        }
        if ($matchedEvents.Count -eq 0) { $lines.Add('Nenhum evento correspondente nos itens consultados; isso não exclui uma falha USB.') }
    } catch { $lines.Add('Log System indisponível ou sem eventos consultaveis.') }

    try {
        $lines | Set-Content -LiteralPath $reportPath -Encoding UTF8 -ErrorAction Stop
        Write-Host " $((Get-Text 'DiagnosticSaved' 'Diagnóstico salvo em:')) $reportPath" -ForegroundColor Green
        Write-Host " $((Get-Text 'AudioRouteManual' 'O diagnóstico não altera a saída de áudio padrão.'))" -ForegroundColor DarkGray
    } catch {
        Write-Host " $((Get-Text 'ActionFailed' 'Não foi possível salvar o diagnóstico.')) $($_.Exception.Message)" -ForegroundColor Red
    }
    try { Start-Process -FilePath "$env:SystemRoot\System32\control.exe" -ArgumentList 'mmsys.cpl' -ErrorAction Stop } catch {}
    Write-Host ""
    Write-Host "$((Get-Text 'PressKey' 'Pressione qualquer tecla para voltar...'))" -ForegroundColor Gray
    try { $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') } catch { Read-Host | Out-Null }
}

function Read-MenuChoice($prompt) {
    Write-Host " $prompt " -NoNewline -ForegroundColor White
    $buffer = ''
    while ($true) {
        try { $key = [Console]::ReadKey($true) }
        catch { return (Read-Host) }
        if ($key.Key -eq [ConsoleKey]::Escape) { Write-Host ''; return '__ESC__' }
        if ($key.Key -eq [ConsoleKey]::Enter) { Write-Host ''; return $buffer }
        if ($key.Key -eq [ConsoleKey]::Backspace) {
            if ($buffer.Length -gt 0) {
                $buffer = $buffer.Substring(0, $buffer.Length - 1)
                Write-Host "`b `b" -NoNewline
            }
            continue
        }
        if (-not [char]::IsControl($key.KeyChar)) {
            $buffer += $key.KeyChar
            Write-Host $key.KeyChar -NoNewline
        }
    }
}

function Show-Header {
    Clear-Host

    Write-Host "==============================================================================" -ForegroundColor DarkCyan
    Write-Host "             $((Get-Text 'Title' 'ROCCAT SYN PRO AIR - MASTER MANAGER'))      " -ForegroundColor Cyan
    Write-Host "==============================================================================" -ForegroundColor DarkCyan
    Write-Host " $((Get-Text 'Credit' 'Desenvolvido com Antigravity e Codex'))" -ForegroundColor DarkGray
    Write-Host " $((Get-Text 'Disclaimer' 'Aviso: o painel diagnostica e altera configurações; não garante a correção.'))" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host " $((Get-Text 'Session' 'Sessão iniciada em:')) " -NoNewline -ForegroundColor Gray
    Write-Host "$sessionStart" -ForegroundColor White
    Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkCyan

    Write-Host " [$((Get-Text 'SystemStatus' 'STATUS DO SISTEMA'))]" -ForegroundColor Yellow
    $info = Get-SystemAudioInfo

    function Write-AlignedStatus($label, $value, $color) {
        $prefix = "  * " + $label
        $padded = if ($prefix.Length -lt 32) { $prefix.PadRight(32) } else { $prefix }
        Write-Host "${padded}: " -NoNewline -ForegroundColor Gray
        Write-Host $value -ForegroundColor $color
    }

    # Indicador de configurações de energia consultadas; não atesta a saude do áudio.

    # USB Dongle
    $usbVal = if ($info.UsbDongleStatus) { (Get-Text 'UsbConnected' 'Conectado e Seguro [OK]') } else { (Get-Text 'UsbDisconnected' 'Desconectado ou Inativo') }
    $usbCol = if ($info.UsbDongleStatus) { "Green" } else { "Red" }
    Write-AlignedStatus (Get-Text 'UsbDongle' 'Receptor USB Dongle') $usbVal $usbCol

    # Driver Turtle Beach
    $tbVal = if (-not $info.DriverInstalled) { (Get-Text 'DriverNotInstalled' 'Não Instalado no Windows') } elseif (-not $info.DriverStateKnown) { (Get-Text 'DriverUnknown' 'ESTADO NÃO CONFIRMADO') } elseif ($info.DriverRunning) { (Get-Text 'DriverActive' 'ATIVO [Estado detectado; estabilidade não confirmada]') } else { (Get-Text 'DriverDisabled' 'DESABILITADO [Estado detectado]') }
    $tbCol = if (-not $info.DriverInstalled) { "DarkGray" } elseif (-not $info.DriverStateKnown) { "Yellow" } elseif ($info.DriverRunning) { "Yellow" } else { "Green" }
    Write-AlignedStatus (Get-Text 'DriverTB' 'Driver Turtle Beach') $tbVal $tbCol

    $service = $info.AudioService
    $serviceValue = if (-not $service) { Get-Text 'DriverUnknown' } elseif ($service.Start -eq 4 -and -not $service.Running) { Get-Text 'ServiceStatusDisabled' } elseif ($service.Running) { Get-Text 'ServiceStatusRunning' } else { Get-Text 'ServiceStatusStopped' }
    Write-AlignedStatus (Get-Text 'ServiceStatusLabel') $serviceValue $(if ($service -and $service.Start -eq 4 -and -not $service.Running) { 'Green' } else { 'Yellow' })

    # Headset
    $hsVal = if ($info.HeadsetAudioActive) { Get-Text 'DeviceAudioActive' } elseif ($info.HeadsetStatus -eq 'OK') { (Get-Text 'DeviceOK' 'PnP OK [presente; não confirma reprodução]') } else { "$((Get-Text 'DeviceInactive' 'Inativo / indisponível')) [$($info.HeadsetStatus)]" }
    $hsCol = if ($info.HeadsetAudioActive) { 'Green' } else { 'Yellow' }
    Write-AlignedStatus (Get-Text 'Headset' 'Alto-Falante [Headset]') $hsVal $hsCol

    # Microfone
    $micVal = if ($info.MicAudioActive) { Get-Text 'DeviceAudioActive' } elseif ($info.MicStatus -eq 'OK') { (Get-Text 'DeviceOK' 'PnP OK [presente; não confirma gravacao]') } else { "$((Get-Text 'DeviceInactive' 'Inativo / indisponível')) [$($info.MicStatus)]" }
    $micCol = if ($info.MicAudioActive) { 'Green' } else { 'Yellow' }
    Write-AlignedStatus (Get-Text 'Microphone' 'Microfone SYN Pro Air') $micVal $micCol

    Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkCyan
}

function Get-DefaultCaptureEndpointSnapshot {
    if (-not (Initialize-CoreAudioApi)) { return $null }
    $roles = [ordered]@{}
    foreach ($name in @('Console','Multimedia','Communications')) {
        try { $roles[$name] = [RoccatSynProAudioFix.CoreAudio]::GetDefaultCaptureEndpointId([Enum]::Parse([RoccatSynProAudioFix.ERole], $name)) }
        catch { $roles[$name] = $null }
    }
    return [pscustomobject]$roles
}

function Get-WavesAudioServiceSnapshot {
    $key = 'HKLM:\SYSTEM\CurrentControlSet\Services\WavesTBSvc'
    try {
        $properties = Get-ItemProperty -LiteralPath $key -ErrorAction Stop
        if ([string]$properties.ImagePath -notmatch '(?i)WavesTBSvc64\.exe(?:["\s]|$)') { return $null }
        $service = Get-Service -Name WavesTBSvc -ErrorAction Stop
        if ($service.Status -notin @('Running','Stopped')) { return $null }
        return [pscustomobject]@{
            Schema = 1; ServiceName = 'WavesTBSvc'; SavedAt = (Get-Date).ToString('o')
            Start = [int]$properties.Start; Running = ($service.Status -eq 'Running')
            ImagePath = [string]$properties.ImagePath
            DelayedStartExisted = ($properties.PSObject.Properties.Name -contains 'DelayedAutoStart')
            DelayedStart = $properties.DelayedAutoStart
        }
    } catch { return $null }
}

function Test-WavesAudioServiceSnapshot($snapshot) {
    return ($snapshot -and $snapshot.Schema -eq 1 -and $snapshot.ServiceName -eq 'WavesTBSvc' -and
        $snapshot.Start -in @(2,3,4) -and $snapshot.Running -is [bool] -and
        $snapshot.DelayedStartExisted -is [bool] -and
        (-not $snapshot.DelayedStartExisted -or $snapshot.DelayedStart -in @(0,1)) -and
        [string]$snapshot.ImagePath -match '(?i)WavesTBSvc64\.exe(?:["\s]|$)')
}

function Save-WavesAudioServiceBackup($snapshot) {
    if (-not (Test-WavesAudioServiceSnapshot $snapshot)) { throw (Get-Text 'ServiceBackupInvalid') }
    if (Test-Path -LiteralPath $wavesServiceBackupFile) {
        $existing = Get-Content -LiteralPath $wavesServiceBackupFile -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if (-not (Test-WavesAudioServiceSnapshot $existing)) { throw (Get-Text 'ServiceBackupInvalid') }
        return
    }
    $temporary = "$wavesServiceBackupFile.tmp"
    $snapshot | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $temporary -Encoding UTF8 -ErrorAction Stop
    $saved = Get-Content -LiteralPath $temporary -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    if (-not (Test-WavesAudioServiceSnapshot $saved)) { throw (Get-Text 'ServiceBackupInvalid') }
    Move-Item -LiteralPath $temporary -Destination $wavesServiceBackupFile -ErrorAction Stop
}

function Set-WavesAudioServiceState([int]$start, [bool]$running) {
    if ($start -notin @(2,3,4) -or -not (Get-WavesAudioServiceSnapshot)) { throw (Get-Text 'ServiceUnavailable') }
    $startup = @{2='Automatic';3='Manual';4='Disabled'}
    if ($running) {
        # A disabled service must be enabled before it can be started. Its
        # original startup type is reapplied after the runtime state is restored.
        Set-Service -Name WavesTBSvc -StartupType Manual -ErrorAction Stop
        $serviceCommand = & "$env:SystemRoot\System32\sc.exe" start WavesTBSvc 2>&1
        if ($LASTEXITCODE -notin @(0,1056)) { throw ($serviceCommand -join ' ') }
        (Get-Service WavesTBSvc).WaitForStatus('Running',[TimeSpan]::FromSeconds(10))
        Set-Service -Name WavesTBSvc -StartupType $startup[$start] -ErrorAction Stop
    } else {
        Set-Service -Name WavesTBSvc -StartupType $startup[$start] -ErrorAction Stop
        $serviceCommand = & "$env:SystemRoot\System32\sc.exe" stop WavesTBSvc 2>&1
        if ($LASTEXITCODE -notin @(0,1062)) { throw ($serviceCommand -join ' ') }
        (Get-Service WavesTBSvc).WaitForStatus('Stopped',[TimeSpan]::FromSeconds(10))
    }
    $actual = Get-WavesAudioServiceSnapshot
    if (-not $actual -or $actual.Start -ne $start -or $actual.Running -ne $running) { throw (Get-Text 'ActionFailed') }
}

function Restore-WavesAudioServiceSnapshot($snapshot) {
    if (-not (Test-WavesAudioServiceSnapshot $snapshot)) { return $false }
    try {
        Set-WavesAudioServiceState ([int]$snapshot.Start) ([bool]$snapshot.Running)
        if ($snapshot.DelayedStartExisted) {
            Set-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\WavesTBSvc' -Name DelayedAutoStart -Type DWord -Value ([int]$snapshot.DelayedStart) -ErrorAction Stop
        }
        $actual = Get-WavesAudioServiceSnapshot
        return ($actual -and $actual.Start -eq $snapshot.Start -and $actual.Running -eq $snapshot.Running -and
            (-not $snapshot.DelayedStartExisted -or $actual.DelayedStart -eq $snapshot.DelayedStart))
    } catch { return $false }
}


function Write-InlineObservationProgress([double]$elapsed, [int]$total, [switch]$Completed) {
    $total = [Math]::Max(1, $total)
    $percent = [Math]::Min(99, [Math]::Max(0, [int][Math]::Floor(100 * $elapsed / $total)))
    if ($Completed) { $percent = 100 }
    $shownSeconds = [Math]::Min($total, [int][Math]::Floor($elapsed))
    if ($Completed) { $shownSeconds = $total }
    $width = 78
    try { $width = [Math]::Max(1, [Console]::WindowWidth - 1) } catch {}
    $suffix = ' {0,3}%  {1}/{2} s' -f $percent, $shownSeconds, $total
    $barWidth = [Math]::Min(40, [Math]::Max(0, $width - $suffix.Length - 5))
    if ($barWidth -ge 4) {
        $filled = [int][Math]::Floor($barWidth * $percent / 100)
        $line = '  [' + ('#' * $filled) + ('-' * ($barWidth - $filled)) + ']' + $suffix
    } else { $line = $suffix.TrimStart() }
    if ($line.Length -gt $width) { $line = $line.Substring(0, $width) }
    # Carriage return redraws only this line, below the current step.
    Write-Host ("`r" + $line.PadRight($width)) -NoNewline -ForegroundColor Cyan
}

function Get-AudioAvailability([object[]]$protectedEndpoints = @()) {
    try {
        if (-not (Initialize-CoreAudioApi)) { throw (Get-Text 'AudioApiFailed') }
        $endpoints = @([RoccatSynProAudioFix.CoreAudio]::GetAllAudioEndpoints())
        $activeIds = @($endpoints | Where-Object { ($_.State -band 1) -eq 1 } | ForEach-Object { $_.Id })
        $synRender = @($endpoints | Where-Object { $_.Name -match '(?i)SYN.*PRO.*AIR' -and $_.Id -match '^\{0\.0\.0\.' -and ($_.State -band 1) -eq 1 })
        $synCapture = @($endpoints | Where-Object { $_.Name -match '(?i)SYN.*PRO.*AIR' -and $_.Name -notmatch '(?i)Sidetone' -and $_.Id -match '^\{0\.0\.1\.' -and ($_.State -band 1) -eq 1 })
        $lost = @($protectedEndpoints | Where-Object { $_.Id -notin $activeIds })
        return [pscustomobject]@{Available=($synRender.Count -gt 0 -and $synCapture.Count -gt 0 -and $lost.Count -eq 0);
            Endpoints=$endpoints;LostEndpoints=$lost;Error=$null}
    } catch { return [pscustomobject]@{Available=$false;Endpoints=@();LostEndpoints=@();Error=$_.Exception.Message} }
}

function Measure-DefaultOutputStability($expectedDefaults, [int]$seconds = 30, $captureBefore = $null, [object[]]$protectedEndpoints = @()) {
    $started = Get-Date
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $changes = 0; $offTarget = 0; $lastSignature = ''; $cancelled = $false
    if ($null -eq $captureBefore) { $captureBefore = Get-DefaultCaptureEndpointSnapshot }
    $expectedSignature = $expectedDefaults | ConvertTo-Json -Compress
    $unavailableSamples = 0
    $oldControlC = $false
    try { $oldControlC = [Console]::TreatControlCAsInput; [Console]::TreatControlCAsInput = $true } catch {}
    try {
        while ($watch.Elapsed.TotalSeconds -lt $seconds) {
            try {
                if ([Console]::KeyAvailable) {
                    $key = [Console]::ReadKey($true)
                    if ($key.Key -eq [ConsoleKey]::Escape -or ($key.Key -eq [ConsoleKey]::C -and ([int]$key.Modifiers -band [int][ConsoleModifiers]::Control))) { $cancelled = $true; break }
                }
            } catch {}
            $current = Get-DefaultRenderEndpointSnapshot
            $signature = $current | ConvertTo-Json -Compress
            if ($lastSignature -and $signature -ne $lastSignature) { $changes++ }
            $lastSignature = $signature
            if (-not $current -or $signature -ne $expectedSignature) { $offTarget++ }
            if (-not (Get-AudioAvailability $protectedEndpoints).Available) { $unavailableSamples++ }
            Write-InlineObservationProgress $watch.Elapsed.TotalSeconds $seconds
            Start-Sleep -Milliseconds 500
        }
    } finally {
        Write-InlineObservationProgress $watch.Elapsed.TotalSeconds $seconds -Completed:((-not $cancelled) -and $watch.Elapsed.TotalSeconds -ge $seconds)
        Write-Host ''
        try { [Console]::TreatControlCAsInput = $oldControlC } catch {}
    }
    $eventsAvailable = $false; $stateEvents = @()
    try {
        $log = Get-WinEvent -ListLog 'Microsoft-Windows-Audio/Operational' -ErrorAction Stop
        $eventsAvailable = [bool]$log.IsEnabled
        if ($eventsAvailable) {
            $eventErrors = @()
            $stateEvents = @(Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Audio/Operational';Id=65;StartTime=$started} -MaxEvents 250 -ErrorAction SilentlyContinue -ErrorVariable eventErrors |
                Where-Object { $_.Properties.Count -ge 4 -and [string]$_.Properties[0].Value -match '(?i)SYN.*PRO.*AIR' })
            if (@($eventErrors | Where-Object { $_.FullyQualifiedErrorId -notmatch '^NoMatchingEventsFound' }).Count -gt 0) { $eventsAvailable = $false }
        }
    } catch {}
    $captureAfter = Get-DefaultCaptureEndpointSnapshot
    return [pscustomobject]@{ObservedSeconds=[int]$watch.Elapsed.TotalSeconds;Complete=(-not $cancelled);DefaultChanges=$changes;DefaultMismatchSamples=$offTarget;
        UnavailableDeviceSamples=$unavailableSamples;FinalAvailability=(Get-AudioAvailability $protectedEndpoints);
        EndpointStateEvents=$stateEvents.Count;EventsAvailable=$eventsAvailable;CaptureBefore=$captureBefore;CaptureAfter=$captureAfter;
        CaptureUnchanged=($null -ne $captureBefore -and $null -ne $captureAfter -and
            (($captureBefore | ConvertTo-Json -Compress) -eq ($captureAfter | ConvertTo-Json -Compress)));FinalDefaults=(Get-DefaultRenderEndpointSnapshot)}
}

function Invoke-StableAudioRepair([int]$verificationSeconds = 30) {
    $result = [ordered]@{Applied=$false;Verified=$false;RolledBack=$false;Service=$null;Observation=$null;Error=$null}
    $before = Get-WavesAudioServiceSnapshot
    $renderBefore = Get-DefaultRenderEndpointSnapshot
    $captureBefore = Get-DefaultCaptureEndpointSnapshot
    $devicesBefore = Get-AudioAvailability
    $protectedEndpoints = @($devicesBefore.Endpoints | Where-Object { ($_.State -band 1) -eq 1 })
    $changed = $false
    try {
        if (-not (Test-WavesAudioServiceSnapshot $before)) { throw (Get-Text 'ServiceUnavailable') }
        if ($devicesBefore.Error -or -not $renderBefore -or -not $captureBefore) { throw (Get-Text 'AudioApiFailed') }
        Write-Host " [1/4] $((Get-Text 'ServiceSaveBackup'))" -ForegroundColor Cyan
        Save-WavesAudioServiceBackup $before
        Write-Host " [2/4] $((Get-Text 'ServiceDisable'))" -ForegroundColor Cyan
        $changed = $true
        Set-WavesAudioServiceState 4 $false
        Write-Host " [3/4] $((Get-Text 'ServiceCheckDevices'))" -ForegroundColor Cyan
        $settle = [Diagnostics.Stopwatch]::StartNew()
        do {
            $availability = Get-AudioAvailability $protectedEndpoints
            if ($availability.Available) { break }
            Start-Sleep -Milliseconds 250
        } while ($settle.Elapsed.TotalSeconds -lt 5)
        if (-not $availability.Available) { throw (Get-Text 'ServiceDevicesUnavailable') }
        $result.Applied = $true
        Write-Host " [4/4] $((Get-Text 'ServiceObserve')) ($verificationSeconds s)" -ForegroundColor Cyan
        $result.Observation = Measure-DefaultOutputStability $renderBefore $verificationSeconds $captureBefore $protectedEndpoints
        $result.Service = Get-WavesAudioServiceSnapshot
        $observation = $result.Observation
        if (-not $observation.FinalAvailability.Available -or $observation.UnavailableDeviceSamples -gt 0) { throw (Get-Text 'ServiceDevicesUnavailable') }
        $result.Verified = ($observation.Complete -and $observation.DefaultMismatchSamples -eq 0 -and $observation.DefaultChanges -eq 0 -and
            $observation.EventsAvailable -and $observation.EndpointStateEvents -eq 0 -and $observation.CaptureUnchanged -and
            $result.Service -and $result.Service.Start -eq 4 -and -not $result.Service.Running -and
            (($observation.FinalDefaults | ConvertTo-Json -Compress) -eq ($renderBefore | ConvertTo-Json -Compress)))
        Write-Host (' ' + ((Get-Text 'ServiceVerifyResult') -f $observation.ObservedSeconds,$observation.DefaultChanges,$observation.EndpointStateEvents)) -ForegroundColor $(if($result.Verified){'Green'}else{'Yellow'})
        Write-Host " $((Get-Text 'ServiceApplied'))" -ForegroundColor Green
        if (-not $result.Verified) { Write-Host (Get-Text 'ServiceNotVerified') -ForegroundColor Yellow }
    } catch {
        $result.Error = $_.Exception.Message
        if ($changed) {
            $result.RolledBack = Restore-WavesAudioServiceSnapshot $before
            $result.Applied = -not $result.RolledBack
            $result.Verified = $false
            $result.Service = Get-WavesAudioServiceSnapshot
            Write-Host (Get-Text 'ServiceRollbackResult') -ForegroundColor Yellow
            $result.Error += " | rollback Waves=$($result.RolledBack)"
        }
        Write-Host " $((Get-Text 'ActionFailed')) $($result.Error)" -ForegroundColor Red
    }
    try { $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $diagnosticDir 'last-system-repair.json') -Encoding UTF8 -ErrorAction Stop } catch {}
    return [pscustomobject]$result
}

function Invoke-StableSystemMode {
    Write-Host "`n>>> $((Get-Text 'Opt1Title'))" -ForegroundColor Cyan
    Write-Host " $((Get-Text 'ServiceEffectsNote'))" -ForegroundColor Yellow
    $null = Invoke-StableAudioRepair 30
    Write-Host (Get-Text 'PressKey') -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

function Invoke-RestorationMenu {
    Write-Host "`n>>> $((Get-Text 'RestoreMenuTitle'))" -ForegroundColor Cyan
    $choice = Read-MenuChoice (Get-Text 'RestoreMenuPrompt')
    if ($choice -eq '__ESC__') { return }
    if ($choice -match '^[wW]$') {
        try {
            if (-not (Test-Path -LiteralPath $wavesServiceBackupFile)) { throw (Get-Text 'ServiceNoBackup') }
            $snapshot = Get-Content -LiteralPath $wavesServiceBackupFile -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if (-not (Restore-WavesAudioServiceSnapshot $snapshot)) { throw (Get-Text 'ActionFailed') }
            Write-Host " $((Get-Text 'ServiceRestored'))" -ForegroundColor Green
        } catch { Write-Host $_.Exception.Message -ForegroundColor Red }
    } elseif ($choice -match '^[eE]$') {
        $null = Restore-SystemBackup
    } else { Write-Host (Get-Text 'InvalidOption') -ForegroundColor Yellow }
    Write-Host (Get-Text 'PressKey') -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}


function Get-SwarmInstallRoots {
    $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    $roots = New-Object System.Collections.Generic.List[string]
    foreach ($root in @($env:ProgramFiles, $programFilesX86)) { if ($root) { $roots.Add($root) } }
    $uninstallPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($uninstallPath in $uninstallPaths) {
        try {
            foreach ($app in (Get-ItemProperty -Path $uninstallPath -ErrorAction Stop | Where-Object { $_.DisplayName -match '(?i)ROCCAT.*SWARM' })) {
                if ($app.InstallLocation) { $roots.Add([string]$app.InstallLocation) }
                if ($app.DisplayIcon) {
                    $iconPath = [regex]::Match([string]$app.DisplayIcon, '^\s*"?(.+?\.exe)(?:"|,|$)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                    if ($iconPath.Success -and (Test-Path $iconPath.Groups[1].Value)) { $roots.Add((Split-Path -Parent $iconPath.Groups[1].Value)) }
                }
            }
        } catch {}
    }
    return @($roots | Where-Object { $_ } | Select-Object -Unique)
}


function Wait-WavesDriverState([bool]$desiredRunning, [int]$timeoutMs = 5000) {
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    do {
        $running = Get-WavesDriverRunning
        if ($null -ne $running -and [bool]$running -eq $desiredRunning) { return $true }
        if ($timer.ElapsedMilliseconds -ge $timeoutMs) { break }
        Start-Sleep -Milliseconds 250
    } while ($timer.ElapsedMilliseconds -lt $timeoutMs)
    return $false
}

function Invoke-WavesDriverMode($startValue, [bool]$desiredRunning, [int]$timeoutMs = 5000) {
    if (-not (Test-Path $regPath)) { throw (Get-Text 'DriverNotInstalled' 'Driver WavesTBVirtual não instalado.') }
    Set-ItemProperty -Path $regPath -Name 'Start' -Value ([int]$startValue) -ErrorAction Stop
    $actual = (Get-ItemProperty -Path $regPath -Name 'Start' -ErrorAction Stop).Start
    if ([int]$actual -ne [int]$startValue) { throw (Get-Text 'ActionFailed' 'O valor de inicialização do driver não foi confirmado.') }

    $commandOutput = ''
    $commandExitCode = 0
    $currentRunning = Get-WavesDriverRunning
    if ($null -eq $currentRunning -or [bool]$currentRunning -ne $desiredRunning) {
        $verb = if ($desiredRunning) { 'start' } else { 'stop' }
        $commandOutput = (sc.exe $verb $driverName 2>&1 | Out-String).Trim()
        $commandExitCode = $LASTEXITCODE
    }

    $confirmed = Wait-WavesDriverState $desiredRunning $timeoutMs
    $observedRunning = Get-WavesDriverRunning
    return [pscustomobject]@{
        StartValue = [int]$actual
        DesiredRunning = $desiredRunning
        Running = $observedRunning
        Confirmed = $confirmed
        CommandExitCode = $commandExitCode
        CommandOutput = $commandOutput
    }
}

function Set-WavesDriverMode($startValue, [switch]$StartNow, [int]$TimeoutMs = 5000) {
    $desiredRunning = [bool]$StartNow
    $attempt = Invoke-WavesDriverMode $startValue $desiredRunning $TimeoutMs
    if (-not $attempt.Confirmed -and $desiredRunning) {
        $detail = if ($attempt.CommandOutput) { " $($attempt.CommandOutput)" } else { '' }
        throw "$(Get-Text 'DriverStartFailed' 'O driver não iniciou; veja o diagnóstico.')$detail"
    }
    if (-not $attempt.Confirmed) {
        $detail = if ($attempt.CommandOutput) { " $($attempt.CommandOutput)" } else { '' }
        throw "$(Get-Text 'DriverStopFailed' 'O driver continua ativo ou a parada não foi confirmada.')$detail"
    }
}

function Restore-WavesDriverState($startValue, $wasRunning) {
    try {
        if ($null -eq $startValue -or $null -eq $wasRunning -or -not (Test-Path $regPath)) { return $false }
        if ([bool]$wasRunning) { Set-WavesDriverMode ([int]$startValue) -StartNow }
        else { Set-WavesDriverMode ([int]$startValue) }
        return $true
    } catch { return $false }
}


function Restore-SwarmSession($session) {
    if (-not $session -or $session.Schema -ne 1 -or $session.DriverStart -notin @(0,1,2,3,4) -or $session.DriverRunning -isnot [bool]) { return $false }
    if ($session.Service -and -not (Test-WavesAudioServiceSnapshot $session.Service)) { return $false }
    $serviceOk = $true; $driverOk = $false
    foreach ($owned in @($session.OwnedProcesses)) {
        try {
            if (-not $owned -or [IO.Path]::GetFileName($owned.Path) -notin @('ROCCAT_Waves_Driver.exe','WavesLoopback64.exe')) { continue }
            $process = Get-Process -Id ([int]$owned.Id) -ErrorAction Stop
            if ($process.Path -eq $owned.Path -and $process.StartTime.ToUniversalTime().ToString('o') -eq $owned.StartTimeUtc) {
                Stop-Process -Id $process.Id -ErrorAction Stop
            }
        } catch {}
    }
    try {
        # Release the user service before restoring a stopped kernel driver.
        if ($session.Service) { Set-WavesAudioServiceState 3 $false }
        $driverOk = Restore-WavesDriverState $session.DriverStart $session.DriverRunning
    } catch { $driverOk = $false }
    finally {
        if ($session.Service) { $serviceOk = Restore-WavesAudioServiceSnapshot $session.Service }
    }
    if ($session.RenderDefaults) {
        $outputOk = Restore-RenderEndpointSnapshot $session.RenderDefaults
        if (-not $outputOk) { Write-Host (Get-Text 'OutputPartialChange') -ForegroundColor Yellow }
    }
    if ($serviceOk -and $driverOk) {
        # Only the verified, completed temporary session is removed.
        if (Test-Path -LiteralPath $swarmSessionFile) { [IO.File]::Delete($swarmSessionFile) }
        return $true
    }
    return $false
}

function Restore-PendingSwarmSession {
    if (-not (Test-Path -LiteralPath $swarmSessionFile)) { return $true }
    Write-Host (Get-Text 'SwarmSessionRecovery') -ForegroundColor Yellow
    try {
        $session = Get-Content -LiteralPath $swarmSessionFile -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if (Restore-SwarmSession $session) { Write-Host (Get-Text 'DriverStateRestored') -ForegroundColor Green; return $true }
    } catch { Write-Host $_.Exception.Message -ForegroundColor Red }
    Write-Host (Get-Text 'DriverRestoreFailed') -ForegroundColor Red
    return $false
}


function Invoke-SentinelaAtiva {
    Write-Host ""
    Write-Host "==============================================================================" -ForegroundColor Magenta
    Write-Host "                         $((Get-Text 'Opt3Title'))                            " -ForegroundColor White
    Write-Host "==============================================================================" -ForegroundColor Magenta
    Write-Host " $((Get-Text 'SentinelStop' 'Pressione ESC para voltar ao menu.'))" -ForegroundColor DarkYellow
    Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkCyan

    Write-Host " $((Get-Text 'SentinelRunning' 'Modo somente leitura: nenhum driver, endpoint ou dispositivo padrão será alterado.'))" -ForegroundColor Green
    Write-Host ""

    $lastSignature = $null
    $lastDefaultSignature = $null
    $lastServiceSignature = $null
    $sentinelLog = Join-Path $diagnosticDir 'sentinela.log'
    $sentinelStartedAt = Get-Date
    $lastAudioEventRecord = 0
    $audioLogUnavailableReported = $false
    $defaultApiReady = Initialize-CoreAudioApi
    if (-not $defaultApiReady) {
        $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] API de saída padrão indisponível; monitorando apenas eventos Audio e estados PnP."
        Add-Content -LiteralPath $sentinelLog -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    try {
        $audioLog = Get-WinEvent -ListLog 'Microsoft-Windows-Audio/Operational' -ErrorAction Stop
        if (-not $audioLog.IsEnabled) { $audioLogUnavailableReported = $true }
        $latestAudioEvent = Get-WinEvent -LogName 'Microsoft-Windows-Audio/Operational' -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($latestAudioEvent) { $lastAudioEventRecord = [long]$latestAudioEvent.RecordId }
    } catch { $audioLogUnavailableReported = $true }
    Add-Content -LiteralPath $sentinelLog -Value "`r`n=== Monitoramento iniciado: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -Encoding UTF8 -ErrorAction SilentlyContinue
    $oldTreatControlC = $false
    try { $oldTreatControlC = [Console]::TreatControlCAsInput; [Console]::TreatControlCAsInput = $true } catch {}
    try {
    while ($true) {
        try {
            if ([Console]::KeyAvailable) {
                $pressed = [Console]::ReadKey($true)
                $isCtrlC = ($pressed.Key -eq [ConsoleKey]::C -and (([int]$pressed.Modifiers -band [int][ConsoleModifiers]::Control) -ne 0))
                if ($pressed.Key -eq [ConsoleKey]::Escape -or $isCtrlC) { break }
            }
        } catch {}

        $now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        if (-not $audioLogUnavailableReported) {
            try {
                $newEvents = @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Audio/Operational'; Id = 65; StartTime = $sentinelStartedAt } -MaxEvents 100 -ErrorAction SilentlyContinue |
                    Where-Object { [long]$_.RecordId -gt $lastAudioEventRecord } | Sort-Object RecordId)
                foreach ($event in $newEvents) {
                    $lastAudioEventRecord = [long]$event.RecordId
                    $data = @($event.Properties | ForEach-Object { [string]$_.Value })
                    $rawData = $data -join ' | '
                    if ($rawData -match '(?i)(SYN|VID_1E7D|3A3B)') {
                        $flow = if ($data.Count -gt 2) { $data[2] } else { '?' }
                        $state = if ($data.Count -gt 3) { $data[3] } else { '?' }
                        $stateLabel = if ($state -match '^\d+$') { Get-AudioStateLabel $state } else { 'Estado não interpretado' }
                        $flowLabel = Get-AudioFlowLabel $flow
                        $eventLine = "[$($event.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss.fff'))] Audio/Operational ID 65 | fluxo=$flow ($flowLabel) | estado=$state ($stateLabel) | $rawData"
                        $eventColor = if ($state -eq '2' -or $state -eq '4' -or $state -eq '8') { 'Red' } elseif ($state -eq '1') { 'Green' } else { 'Yellow' }
                        Write-Host " $eventLine" -ForegroundColor $eventColor
                        Add-Content -LiteralPath $sentinelLog -Value $eventLine -Encoding UTF8 -ErrorAction SilentlyContinue
                    }
                }
            } catch {
                $audioLogUnavailableReported = $true
                $eventLine = "[$now] Log Audio/Operational indisponível; continuando apenas com o estado PnP."
                Write-Host " $eventLine" -ForegroundColor Yellow
                Add-Content -LiteralPath $sentinelLog -Value $eventLine -Encoding UTF8 -ErrorAction SilentlyContinue
            }
        }
        $audioDevices = @(Get-PnpDevice -Class AudioEndpoint -ErrorAction SilentlyContinue)
        $outputs = @(Get-SynOutputEndpoints $audioDevices)
        $microphone = Get-SynMicrophoneEndpoint $audioDevices
        $parts = @()
        foreach ($endpoint in $outputs) { $parts += "OUT:$($endpoint.Status):$($endpoint.InstanceId)" }
        if ($microphone) { $parts += "MIC:$($microphone.Status):$($microphone.InstanceId)" } else { $parts += 'MIC:ABSENT' }
        if ($parts.Count -eq 1) { $parts += 'OUT:ABSENT' }
        $signature = $parts -join ' | '
        if ($signature -ne $lastSignature) {
            $codes = @()
            foreach ($endpoint in $outputs) { $codes += "OUT=$((Get-EndpointProblemCode $endpoint.InstanceId))" }
            if ($microphone) { $codes += "MIC=$((Get-EndpointProblemCode $microphone.InstanceId))" }
            $line = "[$now] $signature | ProblemCode: $($codes -join ', ')"
            $color = if ($signature -match ':(OK):') { 'Green' } else { 'Red' }
            Write-Host " $line" -ForegroundColor $color
            Add-Content -LiteralPath $sentinelLog -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
            $lastSignature = $signature
        }

        # A transicao PnP e a seleção da saída padrão sao eventos diferentes.
        # Registra os três papéis de reprodução para mostrar quando o Windows
        # volta de fato para o headset; endpoints de captura não sao modificados.
        if ($defaultApiReady) {
            $defaultSnapshot = Get-DefaultRenderEndpointSnapshot
            if ($defaultSnapshot) {
                $defaultSignature = "Console=$($defaultSnapshot.Console)|Multimedia=$($defaultSnapshot.Multimedia)|Communications=$($defaultSnapshot.Communications)"
                if ($defaultSignature -ne $lastDefaultSignature) {
                    $activeRender = @()
                    try { $activeRender = @([RoccatSynProAudioFix.CoreAudio]::GetActiveRenderEndpoints()) } catch {}
                    $defaultLine = "[$now] DEFAULT_RENDER: Console=$(Get-RenderEndpointName $defaultSnapshot.Console $activeRender) | Multimedia=$(Get-RenderEndpointName $defaultSnapshot.Multimedia $activeRender) | Communications=$(Get-RenderEndpointName $defaultSnapshot.Communications $activeRender) | IDs: $defaultSignature"
                    Write-Host " $defaultLine" -ForegroundColor Yellow
                    Add-Content -LiteralPath $sentinelLog -Value $defaultLine -Encoding UTF8 -ErrorAction SilentlyContinue
                    $lastDefaultSignature = $defaultSignature
                }
            }
        }
        $serviceSnapshot = Get-WavesAudioServiceSnapshot
        $serviceSignature = if ($serviceSnapshot) { "Start=$($serviceSnapshot.Start); Running=$($serviceSnapshot.Running)" } else { 'unavailable' }
        if ($serviceSignature -ne $lastServiceSignature) {
            $serviceLine = "[$now] WAVES_SERVICE: $serviceSignature"
            Write-Host " $serviceLine" -ForegroundColor Cyan
            Add-Content -LiteralPath $sentinelLog -Value $serviceLine -Encoding UTF8 -ErrorAction SilentlyContinue
            $lastServiceSignature = $serviceSignature
        }
        Start-Sleep -Seconds 1
    }
    } finally { try { [Console]::TreatControlCAsInput = $oldTreatControlC } catch {} }
    Add-Content -LiteralPath $sentinelLog -Value "=== Monitoramento encerrado: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -Encoding UTF8 -ErrorAction SilentlyContinue
    Write-Host " $((Get-Text 'SentinelStopped' 'Monitoramento encerrado.'))" -ForegroundColor Gray
}


# --- LOOP PRINCIPAL DO MENU ---
if (-not (Restore-PendingSwarmSession)) {
    Write-Host (Get-Text 'PressKey') -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
while ($true) {
    Show-Header

    Write-Host " $((Get-Text 'MenuTitle' 'MENU DE OPÇÕES:'))" -ForegroundColor White
    Write-Host ""

    Write-Host "  $((Get-Text 'Opt1Title'))" -ForegroundColor Green
    Write-Host "      * $((Get-Text 'Opt1Desc'))" -ForegroundColor Gray
    Write-Host "      * $((Get-Text 'Opt1Tip'))" -ForegroundColor DarkGray
    Write-Host ""


    Write-Host "  $((Get-Text 'Opt3Title'))" -ForegroundColor Magenta
    Write-Host "      * $((Get-Text 'Opt3Desc'))" -ForegroundColor Gray
    Write-Host "      * $((Get-Text 'Opt3Tip'))" -ForegroundColor DarkGray
    Write-Host ""


    Write-Host "  $((Get-Text 'Opt5Title'))" -ForegroundColor White
    Write-Host "      * $((Get-Text 'Opt5Desc'))" -ForegroundColor Gray
    Write-Host ""

    Write-Host "  $((Get-Text 'Opt6Title'))" -ForegroundColor DarkCyan
    Write-Host "      * $((Get-Text 'Opt6Desc'))" -ForegroundColor Gray
    Write-Host ""

    Write-Host "  $((Get-Text 'RestoreMenuTitle'))" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  $((Get-Text 'OptQTitle'))" -ForegroundColor DarkGray
    Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkCyan
    
    $choice = Read-MenuChoice (Get-Text 'Prompt' 'Escolha uma opção (ESC para sair):')
    
    switch ($choice) {
        '1' { Invoke-StableSystemMode }
        '2' { Invoke-SentinelaAtiva }
        '3' { Show-DiagnosticReport }
        '4' { Show-LanguageSelector }
        'R' { Invoke-RestorationMenu }
        '0' { [System.Environment]::Exit(0) }
        'Q' { [System.Environment]::Exit(0) }
        'q' { [System.Environment]::Exit(0) }
        '__ESC__' { [System.Environment]::Exit(0) }
        default { Write-Host " $((Get-Text 'InvalidOption' 'Opção inválida. Escolha um número do menu.'))" -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
    }
}
