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
# i18n.json como fonte de edicao quando o marcador ainda nao foi compilado.
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
        Write-Host " $((Get-Text 'InvalidOption' 'Idioma invalido.'))" -ForegroundColor Yellow
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
    Write-Host " $((Get-Text 'ActionFailed' 'Nao foi possivel salvar o idioma.'))" -ForegroundColor Red
    return $false
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
        default { Write-Host " $((Get-Text 'InvalidOption' 'Opcao invalida.'))" -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
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
            IMMDeviceEnumerator enumerator = null;
            IMMDeviceCollection collection = null;
            List<EndpointInfo> result = new List<EndpointInfo>();
            try {
                enumerator = CreateEnumerator();
                int hr = enumerator.EnumAudioEndpoints(EDataFlow.Render, 1, out collection);
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
        Write-Host " $((Get-Text 'AudioApiFailed' 'A API de audio do Windows nao ficou disponivel.')) $($_.Exception.Message)" -ForegroundColor Red
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
    if (-not $endpointId) { return (Get-Text 'NoDefaultOutput' 'nenhuma saida padrao') }
    if ($null -eq $endpointList) {
        try { $endpointList = [RoccatSynProAudioFix.CoreAudio]::GetActiveRenderEndpoints() } catch { $endpointList = @() }
    }
    $match = @($endpointList | Where-Object { $_.Id -eq $endpointId } | Select-Object -First 1)
    if ($match.Count -gt 0) { return [string]$match[0].Name }
    return [string]$endpointId
}

function Set-PreferredRenderEndpoint($endpointId) {
    if (-not (Initialize-CoreAudioApi)) { return $false }
    try {
        if (-not [RoccatSynProAudioFix.CoreAudio]::IsRenderEndpointActive([string]$endpointId)) { return $false }
        $hr = [RoccatSynProAudioFix.CoreAudio]::SetDefaultRenderEndpoint([string]$endpointId)
        if ($hr -lt 0) { return $false }
        $actual = Get-DefaultRenderEndpointSnapshot
        return ($actual -and $actual.Console -eq $endpointId -and $actual.Multimedia -eq $endpointId -and $actual.Communications -eq $endpointId)
    } catch { return $false }
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

function Get-FixStatus {
    $usbOk = $false
    $activeGuid = $null
    try {
        $activeText = (powercfg.exe /getactivescheme 2>&1 | Out-String)
        $activeMatch = [regex]::Match($activeText, '(?i)\b[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\b')
        if ($activeMatch.Success) { $activeGuid = $activeMatch.Value }
    } catch {}
    if ($activeGuid) {
        $values = Get-UsbSuspendValues $activeGuid
        $usbOk = ($values -and $values.AC -eq 0 -and $values.DC -eq 0)
    }

    $isDuckingDisabled = $false
    try {
        $duck = (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio' -Name UserDuckingPreference -ErrorAction Stop).UserDuckingPreference
        $isDuckingDisabled = ($duck -eq 3)
    } catch {}

    return ($usbOk -and $isDuckingDisabled)
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
        FixApplied      = (Get-FixStatus)
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

    return $state
}

function Save-SystemBackup([switch]$RequireCompletePower, [switch]$RequireDriver) {
    if (Test-Path $stateBackupFile) {
        try {
            $existing = Get-Content -LiteralPath $stateBackupFile -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if (-not $existing.SavedAt) { throw 'Formato de copia invalido.' }
            $driverComplete = (-not $RequireDriver -or -not (Test-Path $regPath) -or ($null -ne $existing.DriverStart -and $null -ne $existing.DriverRunning))
            $powerComplete = $true
            if ($RequireCompletePower) {
                $savedSchemes = @($existing.PowerSchemes)
                $currentGuids = @(Get-PowerSchemeGuids)
                $savedByGuid = @{}
                foreach ($scheme in $savedSchemes) {
                    if ($scheme.Guid -and $null -ne $scheme.AC -and $null -ne $scheme.DC) { $savedByGuid[[string]$scheme.Guid] = $scheme }
                }
                $hasDuckingSnapshot = $existing.PSObject.Properties.Name -contains 'DuckKeyExisted'
                $powerComplete = ($hasDuckingSnapshot -and $currentGuids.Count -gt 0 -and @($currentGuids | Where-Object { -not $savedByGuid.ContainsKey([string]$_) }).Count -eq 0)
            }
            if ($driverComplete -and (-not $RequireCompletePower -or $powerComplete)) { return $true }
        } catch {}
        Write-Host " $((Get-Text 'BackupIncomplete' 'A copia existente nao contem o estado necessario para restaurar; nenhuma alteracao foi feita.'))" -ForegroundColor Red
        return $false
    }

    $schemeGuids = @(Get-PowerSchemeGuids)
    $schemes = @()
    foreach ($guid in $schemeGuids) {
        $values = Get-UsbSuspendValues $guid
        if ($values) { $schemes += [pscustomobject]@{ Guid = $guid; AC = $values.AC; DC = $values.DC } }
    }

    $schemeCount = $schemeGuids.Count
    if ($RequireCompletePower -and ($schemeCount -eq 0 -or $schemes.Count -ne $schemeCount)) {
        Write-Host " $((Get-Text 'BackupIncomplete' 'Nao consegui ler todos os planos de energia; nenhuma alteracao foi feita.'))" -ForegroundColor Red
        return $false
    }

    $duckValue = $null
    $duckKeyExisted = Test-Path 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio'
    try { $duckValue = (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio' -Name UserDuckingPreference -ErrorAction Stop).UserDuckingPreference } catch {}

    $hubStates = @()
    try {
        $hubStates = @(Get-WmiObject -Namespace root\wmi -Class MSPower_DeviceEnable -ErrorAction Stop |
            Where-Object { $_.InstanceName -match '(?i)ROOT_HUB' } |
            ForEach-Object { [pscustomobject]@{ InstanceName = $_.InstanceName; Enable = [bool]$_.Enable } })
    } catch {}

    $driverStart = $null
    $driverRunning = $null
    try { $driverStart = (Get-ItemProperty -Path $regPath -Name Start -ErrorAction Stop).Start } catch {}
    $driverRunning = Get-WavesDriverRunning
    if ($RequireDriver -and ($null -eq $driverStart -or $null -eq $driverRunning)) {
        Write-Host " $((Get-Text 'BackupIncomplete' 'Nao consegui ler o estado atual do driver; nenhuma alteracao foi feita.'))" -ForegroundColor Red
        return $false
    }

    $snapshot = [pscustomobject]@{
        SavedAt = (Get-Date).ToString('o')
        DriverStart = $driverStart
        DriverRunning = $driverRunning
        PowerSchemes = @($schemes)
        DuckKeyExisted = $duckKeyExisted
        DuckValue = $duckValue
        UsbHubs = @($hubStates)
    }
    try {
        $snapshot | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $stateBackupFile -Encoding UTF8 -ErrorAction Stop
        return $true
    } catch {
        Write-Host " $((Get-Text 'ActionFailed' 'Nao foi possivel salvar a copia das configuracoes.')) $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Restore-SystemBackup {
    if (-not (Test-Path $stateBackupFile)) {
        Write-Host " $((Get-Text 'NoBackup' 'Nenhuma copia anterior foi encontrada.'))" -ForegroundColor Yellow
        return $false
    }

    $ok = $true
    try { $snapshot = Get-Content -LiteralPath $stateBackupFile -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop }
    catch {
        Write-Host " $((Get-Text 'RestoreFailed' 'Nao foi possivel ler a copia das configuracoes.'))" -ForegroundColor Red
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
        Write-Host " $((Get-Text 'RestoreFailed' 'A copia nao inclui todos os valores necessarios; nada foi restaurado.'))" -ForegroundColor Red
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
    if ($ok) { Write-Host " $((Get-Text 'RestoreDone' 'Configuracoes anteriores restauradas.'))" -ForegroundColor Green }
    else { Write-Host " $((Get-Text 'RestoreFailed' 'A restauracao ficou incompleta; confira as mensagens acima.'))" -ForegroundColor Red }
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
        '0' { return (Get-Text 'AudioOutputFlow' 'Saida / render') }
        '1' { return (Get-Text 'AudioCaptureFlow' 'Microfone / captura') }
        default { return "$(Get-Text 'AudioFlowOther' 'Fluxo') $flow" }
    }
}

function Show-DiagnosticReport {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $reportPath = Join-Path $diagnosticDir "Roccat-SynPro-Diagnostico-$stamp.txt"
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Diagnostico ROCCAT Syn Pro Air - $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))")
    $lines.Add("Computador: $env:COMPUTERNAME")
    $lines.Add('')
    $lines.Add('=== Endpoints de audio PnP ===')
    $lines.Add('O status PnP confirma enumeracao do endpoint; nao confirma audio em reproducao ou gravacao.')
    $lines.Add('O script nao consegue ler se o headset sem fio esta ligado; registra somente o estado visto pelo Windows e pelo dongle.')

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
    $lines.Add('=== Saidas de reproducao padrao do Windows ===')
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
        } else { $lines.Add('Nao foi possivel ler os papeis de reproducao.') }
    } else { $lines.Add('API de saida padrao indisponivel.') }

    $lines.Add('')
    $lines.Add('=== Dongle USB ===')
    $dongles = @(Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -like 'USB\VID_1E7D&PID_3A3B*' })
    foreach ($device in $dongles) { $lines.Add("$($device.Status) | $($device.Class) | $($device.FriendlyName) | $($device.InstanceId)") }
    if ($dongles.Count -eq 0) { $lines.Add('Dongle nao encontrado na arvore PnP.') }

    $lines.Add('')
    $lines.Add('=== Driver WavesTBVirtual ===')
    $lines.Add((sc.exe query $driverName 2>&1 | Out-String).TrimEnd())
    $lines.Add((sc.exe qc $driverName 2>&1 | Out-String).TrimEnd())
    try {
        $driver = Get-CimInstance Win32_SystemDriver -Filter "Name='$driverName'" -ErrorAction Stop
        $lines.Add("State=$($driver.State); StartMode=$($driver.StartMode); Path=$($driver.PathName)")
    } catch { $lines.Add('Driver nao encontrado via CIM.') }

    $lines.Add('')
    $lines.Add('=== Servicos de audio ===')
    foreach ($serviceName in @('Audiosrv','AudioEndpointBuilder','WavesTBSvc')) {
        try { $service = Get-Service -Name $serviceName -ErrorAction Stop; $lines.Add("$serviceName = $($service.Status)") }
        catch { $lines.Add("$serviceName = nao consultado") }
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
    $lines.Add('=== Suspensao seletiva USB (plano atual) ===')
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
    } catch { $lines.Add('Log Audio/Operational indisponivel.') }

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
        if ($matchedEvents.Count -eq 0) { $lines.Add('Nenhum evento correspondente nos itens consultados; isso nao exclui uma falha USB.') }
    } catch { $lines.Add('Log System indisponivel ou sem eventos consultaveis.') }

    try {
        $lines | Set-Content -LiteralPath $reportPath -Encoding UTF8 -ErrorAction Stop
        Write-Host " $((Get-Text 'DiagnosticSaved' 'Diagnostico salvo em:')) $reportPath" -ForegroundColor Green
        Write-Host " $((Get-Text 'AudioRouteManual' 'O diagnostico nao altera a saida de audio padrao.'))" -ForegroundColor DarkGray
    } catch {
        Write-Host " $((Get-Text 'ActionFailed' 'Nao foi possivel salvar o diagnostico.')) $($_.Exception.Message)" -ForegroundColor Red
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
    Write-Host " $((Get-Text 'Disclaimer' 'Aviso: o painel diagnostica e altera configuracoes; nao garante a correcao.'))" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host " $((Get-Text 'Session' 'Sessao iniciada em:')) " -NoNewline -ForegroundColor Gray
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

    # Indicador de configuracoes de energia consultadas; nao atesta a saude do audio.
    $fixVal = if ($info.FixApplied) { (Get-Text 'FixPositive' '[ CONFIGURACOES CONSULTADAS ]') } else { (Get-Text 'FixPending' '[ CONFIGURACOES NAO CONFIRMADAS ]') }
    $fixCol = if ($info.FixApplied) { "Green" } else { "Red" }
    Write-AlignedStatus (Get-Text 'FixStatusLabel' 'Status da Blindagem (Fix)') $fixVal $fixCol

    # USB Dongle
    $usbVal = if ($info.UsbDongleStatus) { (Get-Text 'UsbConnected' 'Conectado e Seguro [OK]') } else { (Get-Text 'UsbDisconnected' 'Desconectado ou Inativo') }
    $usbCol = if ($info.UsbDongleStatus) { "Green" } else { "Red" }
    Write-AlignedStatus (Get-Text 'UsbDongle' 'Receptor USB Dongle') $usbVal $usbCol

    # Driver Turtle Beach
    $tbVal = if (-not $info.DriverInstalled) { (Get-Text 'DriverNotInstalled' 'Nao Instalado no Windows') } elseif (-not $info.DriverStateKnown) { (Get-Text 'DriverUnknown' 'ESTADO NAO CONFIRMADO') } elseif ($info.DriverRunning) { (Get-Text 'DriverActive' 'ATIVO [Estado detectado; estabilidade nao confirmada]') } else { (Get-Text 'DriverDisabled' 'DESABILITADO [Estado detectado]') }
    $tbCol = if (-not $info.DriverInstalled) { "DarkGray" } elseif (-not $info.DriverStateKnown) { "Yellow" } elseif ($info.DriverRunning) { "Yellow" } else { "Green" }
    Write-AlignedStatus (Get-Text 'DriverTB' 'Driver Turtle Beach') $tbVal $tbCol

    $service = $info.AudioService
    $serviceValue = if (-not $service) { Get-Text 'DriverUnknown' } elseif ($service.Start -eq 4 -and -not $service.Running) { Get-Text 'ServiceStatusDisabled' } elseif ($service.Running) { Get-Text 'ServiceStatusRunning' } else { Get-Text 'ServiceStatusStopped' }
    Write-AlignedStatus (Get-Text 'ServiceStatusLabel') $serviceValue $(if ($service -and $service.Start -eq 4 -and -not $service.Running) { 'Green' } else { 'Yellow' })

    # Headset
    $hsVal = if ($info.HeadsetStatus -eq 'OK') { (Get-Text 'DeviceOK' 'PnP OK [presente; nao confirma reproducao]') } else { "$((Get-Text 'DeviceInactive' 'Inativo / indisponivel')) [$($info.HeadsetStatus)]" }
    $hsCol = if ($info.HeadsetStatus -eq 'OK') { "Green" } else { "Red" }
    Write-AlignedStatus (Get-Text 'Headset' 'Alto-Falante [Headset]') $hsVal $hsCol

    # Microfone
    $micVal = if ($info.MicStatus -eq 'OK') { (Get-Text 'DeviceOK' 'PnP OK [presente; nao confirma gravacao]') } else { "$((Get-Text 'DeviceInactive' 'Inativo / indisponivel')) [$($info.MicStatus)]" }
    $micCol = if ($info.MicStatus -eq 'OK') { "Green" } else { "Red" }
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

function Select-RenderEndpoint {
    if (-not (Initialize-CoreAudioApi)) { return $null }
    try { $endpoints = @([RoccatSynProAudioFix.CoreAudio]::GetActiveRenderEndpoints()) }
    catch { Write-Host $_.Exception.Message -ForegroundColor Red; return $null }
    if ($endpoints.Count -eq 0) { Write-Host (Get-Text 'OutputNoEndpoints') -ForegroundColor Red; return $null }
    $defaults = Get-DefaultRenderEndpointSnapshot
    Write-Host " $((Get-Text 'OutputChooseHeading'))" -ForegroundColor White
    for ($index = 0; $index -lt $endpoints.Count; $index++) {
        $endpoint = $endpoints[$index]
        $isDefault = $defaults -and $endpoint.Id -in @($defaults.Console,$defaults.Multimedia,$defaults.Communications)
        $tag = if ($isDefault) { Get-Text 'OutputDefaultTag' } else { '' }
        Write-Host ('  [{0}] {1} {2}' -f ($index + 1),$endpoint.Name,$tag) -ForegroundColor $(if($isDefault){'Yellow'}else{'Gray'})
    }
    $choice = Read-MenuChoice (Get-Text 'OutputSelectPrompt')
    if ($choice -eq '__ESC__') { return $null }
    $number = 0
    if (-not [int]::TryParse([string]$choice,[ref]$number) -or $number -lt 1 -or $number -gt $endpoints.Count) {
        Write-Host (Get-Text 'InvalidOption') -ForegroundColor Yellow
        return $null
    }
    return $endpoints[$number - 1]
}

function Measure-DefaultOutputStability([string]$endpointId, [int]$seconds = 30) {
    $started = Get-Date
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $changes = 0; $offTarget = 0; $lastSignature = ''; $cancelled = $false
    $captureBefore = Get-DefaultCaptureEndpointSnapshot
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
            if (-not $current -or $current.Console -ne $endpointId -or $current.Multimedia -ne $endpointId -or $current.Communications -ne $endpointId) { $offTarget++ }
            Write-Progress -Activity (Get-Text 'ServiceObserve') -Status ('{0}/{1} s' -f [int]$watch.Elapsed.TotalSeconds,$seconds) -PercentComplete ([Math]::Min(100,[int](100 * $watch.Elapsed.TotalSeconds / $seconds)))
            Start-Sleep -Milliseconds 500
        }
    } finally {
        Write-Progress -Activity (Get-Text 'ServiceObserve') -Completed
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
    return [pscustomobject]@{ObservedSeconds=[int]$watch.Elapsed.TotalSeconds;Complete=(-not $cancelled);DefaultChanges=$changes;OffTargetSamples=$offTarget;
        EndpointStateEvents=$stateEvents.Count;EventsAvailable=$eventsAvailable;CaptureBefore=$captureBefore;CaptureAfter=$captureAfter;
        CaptureUnchanged=($null -ne $captureBefore -and $null -ne $captureAfter -and
            (($captureBefore | ConvertTo-Json -Compress) -eq ($captureAfter | ConvertTo-Json -Compress)));FinalDefaults=(Get-DefaultRenderEndpointSnapshot)}
}

function Invoke-StableAudioRepair([string]$endpointId, [int]$verificationSeconds = 30) {
    $result = [ordered]@{Applied=$false;Verified=$false;Service=$null;Observation=$null;Error=$null}
    $before = Get-WavesAudioServiceSnapshot
    $renderBefore = Get-DefaultRenderEndpointSnapshot
    $changed = $false
    try {
        if (-not (Test-WavesAudioServiceSnapshot $before)) { throw (Get-Text 'ServiceUnavailable') }
        if (-not [RoccatSynProAudioFix.CoreAudio]::IsRenderEndpointActive($endpointId)) { throw (Get-Text 'OutputNoEndpoints') }
        Write-Host " [1/4] $((Get-Text 'ServiceSaveBackup'))" -ForegroundColor Cyan
        Save-WavesAudioServiceBackup $before
        Write-Host " [2/4] $((Get-Text 'ServiceDisable'))" -ForegroundColor Cyan
        $changed = $true
        Set-WavesAudioServiceState 4 $false
        Write-Host " [3/4] $((Get-Text 'OutputApplying'))" -ForegroundColor Cyan
        if (-not (Set-PreferredRenderEndpoint $endpointId)) { throw (Get-Text 'OutputSetFailed') }
        $result.Applied = $true
        Write-Host " [4/4] $((Get-Text 'ServiceObserve')) ($verificationSeconds s)" -ForegroundColor Cyan
        $result.Observation = Measure-DefaultOutputStability $endpointId $verificationSeconds
        $result.Service = Get-WavesAudioServiceSnapshot
        $observation = $result.Observation
        $result.Verified = ($observation.Complete -and $observation.OffTargetSamples -eq 0 -and $observation.DefaultChanges -eq 0 -and
            $observation.EventsAvailable -and $observation.EndpointStateEvents -eq 0 -and $observation.CaptureUnchanged -and
            $result.Service -and $result.Service.Start -eq 4 -and -not $result.Service.Running -and
            $observation.FinalDefaults.Console -eq $endpointId -and $observation.FinalDefaults.Multimedia -eq $endpointId -and
            $observation.FinalDefaults.Communications -eq $endpointId)
        Write-Host (' ' + ((Get-Text 'ServiceVerifyResult') -f $observation.ObservedSeconds,$observation.DefaultChanges,$observation.EndpointStateEvents)) -ForegroundColor $(if($result.Verified){'Green'}else{'Yellow'})
        Write-Host " $((Get-Text 'ServiceApplied'))" -ForegroundColor Green
        if (-not $result.Verified) { Write-Host (Get-Text 'ServiceNotVerified') -ForegroundColor Yellow }
    } catch {
        $result.Error = $_.Exception.Message
        if ($changed -and -not $result.Applied) {
            $serviceRestored = Restore-WavesAudioServiceSnapshot $before
            $renderRestored = Restore-RenderEndpointSnapshot $renderBefore
            $result.Error += " | rollback: Waves=$serviceRestored; playback=$renderRestored"
        }
        Write-Host " $((Get-Text 'ActionFailed')) $($result.Error)" -ForegroundColor Red
    }
    try { $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $diagnosticDir 'last-system-repair.json') -Encoding UTF8 -ErrorAction Stop } catch {}
    return [pscustomobject]$result
}

function Invoke-StableSystemMode {
    Write-Host "`n>>> $((Get-Text 'Opt1Title'))" -ForegroundColor Cyan
    Write-Host " $((Get-Text 'ServiceEffectsNote'))" -ForegroundColor Yellow
    $choice = Read-MenuChoice (Get-Text 'ServiceRepairPrompt')
    if ($choice -eq '__ESC__') { return }
    if ($choice -match '^[pP]$') { Invoke-OutputGuard; return }
    if ($choice -match '^[rR]$') {
        try {
            if (-not (Test-Path -LiteralPath $wavesServiceBackupFile)) { throw (Get-Text 'ServiceNoBackup') }
            $snapshot = Get-Content -LiteralPath $wavesServiceBackupFile -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if (-not (Restore-WavesAudioServiceSnapshot $snapshot)) { throw (Get-Text 'ActionFailed') }
            Write-Host " $((Get-Text 'ServiceRestored'))" -ForegroundColor Green
        } catch { Write-Host $_.Exception.Message -ForegroundColor Red }
    } elseif ($choice -eq '' -or $choice -eq '1') {
        $target = Select-RenderEndpoint
        if ($target) { $null = Invoke-StableAudioRepair $target.Id 30 }
    } else { Write-Host (Get-Text 'InvalidOption') -ForegroundColor Yellow }
    Write-Host (Get-Text 'PressKey') -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

function Invoke-OutputGuard {
    Write-Host ""
    Write-Host ">>> $((Get-Text 'OutputGuardTitle'))..." -ForegroundColor Cyan
    $target = Select-RenderEndpoint
    if (-not $target) { return }
    $initialDefaults = Get-DefaultRenderEndpointSnapshot
    Write-Host " $((Get-Text 'OutputApplying' 'Aplicando a saida escolhida e confirmando os tres papeis de reproducao...'))" -ForegroundColor Cyan
    if (-not (Set-PreferredRenderEndpoint $target.Id)) {
        $rolledBack = Restore-RenderEndpointSnapshot $initialDefaults
        Write-Host " $((Get-Text 'OutputSetFailed' 'O Windows nao confirmou a saida escolhida. Abrindo o painel classico para selecao manual.'))" -ForegroundColor Red
        if ($rolledBack) { Write-Host " $((Get-Text 'OutputPreviousDefaultRestored' 'O padrao anterior de reproducao foi restaurado.'))" -ForegroundColor Yellow }
        else { Write-Host " $((Get-Text 'OutputPartialChange' 'Nao foi possivel confirmar a restauracao de todos os papeis de reproducao. Confira o painel de som.'))" -ForegroundColor Yellow }
        try { Start-Process -FilePath "$env:SystemRoot\System32\control.exe" -ArgumentList 'mmsys.cpl' -ErrorAction Stop } catch {}
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    $guardLog = Join-Path $diagnosticDir 'default-output-guard.log'
    $targetName = [string]$target.Name
    $startedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -LiteralPath $guardLog -Value "`r`n=== Protecao iniciada: $startedAt | saida='$targetName' | ID='$($target.Id)' ===" -Encoding UTF8 -ErrorAction SilentlyContinue
    Write-Host " $((Get-Text 'OutputMonitorRunning' 'Saida protegida. ESC volta ao menu; a protecao funciona enquanto esta janela permanecer aberta.'))" -ForegroundColor Green
    Write-Host " $((Get-Text 'OutputMicUntouched' 'Somente a reproducao foi alterada; o dispositivo padrao do microfone nao foi modificado.'))" -ForegroundColor Gray
    Write-Host " $((Get-Text 'OutputLogPath' 'Registro de mudancas:')) $guardLog" -ForegroundColor DarkGray
    Write-Host ""

    $oldTreatControlC = $false
    $lastMismatch = $null
    $lastAttempt = [DateTime]::MinValue
    $lastAttemptOutcome = $null
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

            $defaults = Get-DefaultRenderEndpointSnapshot
            $changedRoles = @()
            if ($defaults) {
                foreach ($roleName in @('Console', 'Multimedia', 'Communications')) {
                    if ($defaults.$roleName -ne $target.Id) { $changedRoles += $roleName }
                }
            } else { $changedRoles = @('Console', 'Multimedia', 'Communications') }

            if ($changedRoles.Count -gt 0) {
                $signature = if ($defaults) { ($changedRoles | ForEach-Object { "$_=$($defaults.$_)" }) -join '; ' } else { 'default endpoint unavailable' }
                $now = Get-Date
                if ($signature -ne $lastMismatch) {
                    $detail = "[$($now.ToString('yyyy-MM-dd HH:mm:ss.fff'))] Troca detectada ($signature). Alvo='$targetName'"
                    Write-Host " $detail" -ForegroundColor Red
                    Add-Content -LiteralPath $guardLog -Value $detail -Encoding UTF8 -ErrorAction SilentlyContinue
                    $lastMismatch = $signature
                    $lastAttemptOutcome = $null
                }
                if (($now - $lastAttempt).TotalMilliseconds -ge 1000) {
                    $lastAttempt = $now
                    if (-not [RoccatSynProAudioFix.CoreAudio]::IsRenderEndpointActive([string]$target.Id)) {
                        if ($lastAttemptOutcome -ne 'unavailable') {
                            $detail = "[$($now.ToString('yyyy-MM-dd HH:mm:ss.fff'))] A saida alvo esta temporariamente indisponivel; aguardando reaparecer."
                            Write-Host " $detail" -ForegroundColor Yellow
                            Add-Content -LiteralPath $guardLog -Value $detail -Encoding UTF8 -ErrorAction SilentlyContinue
                        }
                        $lastAttemptOutcome = 'unavailable'
                    } elseif (Set-PreferredRenderEndpoint $target.Id) {
                        $detail = "[$($now.ToString('yyyy-MM-dd HH:mm:ss.fff'))] Saida padrao restabelecida para '$targetName'."
                        Write-Host " $detail" -ForegroundColor Green
                        Add-Content -LiteralPath $guardLog -Value $detail -Encoding UTF8 -ErrorAction SilentlyContinue
                        $lastAttemptOutcome = 'restored'
                    } else {
                        if ($lastAttemptOutcome -ne 'failed') {
                            $detail = "[$($now.ToString('yyyy-MM-dd HH:mm:ss.fff'))] O Windows nao confirmou a troca para '$targetName'; nova tentativa em 1 s."
                            Write-Host " $detail" -ForegroundColor Yellow
                            Add-Content -LiteralPath $guardLog -Value $detail -Encoding UTF8 -ErrorAction SilentlyContinue
                        }
                        $lastAttemptOutcome = 'failed'
                    }
                }
            } else {
                $lastMismatch = $null
                $lastAttemptOutcome = $null
            }
            Start-Sleep -Milliseconds 500
        }
    } finally { try { [Console]::TreatControlCAsInput = $oldTreatControlC } catch {} }

    # Deixa a escolha do usuario como padrao ao sair, mas nao cria tarefa nem servico em segundo plano.
    $leftAsSelected = Set-PreferredRenderEndpoint $target.Id
    if ($leftAsSelected) {
        Write-Host " $((Get-Text 'OutputMonitorStopped' 'Monitor encerrado; a saida escolhida continua como padrao.'))" -ForegroundColor Green
    } else {
        Write-Host " $((Get-Text 'OutputTargetUnavailable' 'Monitor encerrado; nao foi possivel reaplicar a saida escolhida neste momento.'))" -ForegroundColor Yellow
    }
    Add-Content -LiteralPath $guardLog -Value "=== Protecao encerrada: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -Encoding UTF8 -ErrorAction SilentlyContinue
    Write-Host ""
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

function Find-SwarmExecutable {
    $candidates = New-Object System.Collections.Generic.List[string]
    foreach ($root in (Get-SwarmInstallRoots)) {
        $candidates.Add((Join-Path $root 'ROCCAT_Swarm.exe'))
        $candidates.Add((Join-Path $root 'ROCCAT\ROCCAT SWARM\ROCCAT_Swarm.exe'))
        $candidates.Add((Join-Path $root 'ROCCAT SWARM\ROCCAT_Swarm.exe'))
    }
    return $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
}

function Get-RoccatSwarmUiProcesses {
    # ROCCAT_Swarm_Monitor.exe e auxiliar persistente da bandeja e pode ficar
    # aberto sem a interface. Monitore apenas ROCCAT_Swarm.exe para detectar
    # quando o usuario encerrou a janela/aplicativo principal.
    return @(Get-Process -Name 'ROCCAT_Swarm' -ErrorAction SilentlyContinue)
}

function Find-WavesExecutable {
    $candidates = New-Object System.Collections.Generic.List[string]
    foreach ($root in (Get-SwarmInstallRoots)) {
        $candidates.Add((Join-Path $root 'data\waves_driver\ROCCAT_Waves_Driver.exe'))
        $candidates.Add((Join-Path $root 'ROCCAT\ROCCAT SWARM\data\waves_driver\ROCCAT_Waves_Driver.exe'))
        $candidates.Add((Join-Path $root 'ROCCAT SWARM\data\waves_driver\ROCCAT_Waves_Driver.exe'))
    }
    $swarmExe = Find-SwarmExecutable
    if ($swarmExe) { $candidates.Add((Join-Path (Split-Path -Parent $swarmExe) 'data\waves_driver\ROCCAT_Waves_Driver.exe')) }
    return $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
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
    if (-not (Test-Path $regPath)) { throw (Get-Text 'DriverNotInstalled' 'Driver WavesTBVirtual nao instalado.') }
    Set-ItemProperty -Path $regPath -Name 'Start' -Value ([int]$startValue) -ErrorAction Stop
    $actual = (Get-ItemProperty -Path $regPath -Name 'Start' -ErrorAction Stop).Start
    if ([int]$actual -ne [int]$startValue) { throw (Get-Text 'ActionFailed' 'O valor de inicializacao do driver nao foi confirmado.') }

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
        throw "$(Get-Text 'DriverStartFailed' 'O driver nao iniciou; veja o diagnostico.')$detail"
    }
    if (-not $attempt.Confirmed) {
        $detail = if ($attempt.CommandOutput) { " $($attempt.CommandOutput)" } else { '' }
        throw "$(Get-Text 'DriverStopFailed' 'O driver continua ativo ou a parada nao foi confirmada.')$detail"
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

function Save-SwarmSession($session) {
    $temporary = "$swarmSessionFile.tmp"
    $session | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $temporary -Encoding UTF8 -ErrorAction Stop
    $check = Get-Content -LiteralPath $temporary -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    if ($check.Schema -ne 1 -or $check.DriverRunning -isnot [bool] -or $check.DriverStart -notin @(0,1,2,3,4)) { throw (Get-Text 'BackupIncomplete') }
    Move-Item -LiteralPath $temporary -Destination $swarmSessionFile -Force -ErrorAction Stop
}

function Get-WavesLoopbackExecutable {
    $snapshot = Get-WavesAudioServiceSnapshot
    if (-not $snapshot) { return $null }
    $match = [regex]::Match($snapshot.ImagePath, '^\s*"?(.+?\.exe)(?:"|\s|$)', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not $match.Success) { return $null }
    $servicePath = [Environment]::ExpandEnvironmentVariables($match.Groups[1].Value)
    if ($servicePath.StartsWith('\SystemRoot\',[StringComparison]::OrdinalIgnoreCase)) { $servicePath = Join-Path $env:SystemRoot $servicePath.Substring(12) }
    $path = Join-Path (Split-Path -Parent $servicePath) 'WavesLoopback64.exe'
    if (Test-Path -LiteralPath $path -PathType Leaf) { return $path }
    return $null
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

function Invoke-SwarmAutoPilot {
    Write-Host "`n>>> $((Get-Text 'Opt2Title'))" -ForegroundColor Yellow
    if (-not (Restore-PendingSwarmSession)) { $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); return }
    $swarmExe = Find-SwarmExecutable
    if (-not $swarmExe) { Write-Host (Get-Text 'SwarmNotFound') -ForegroundColor Red; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); return }
    $driverRunning = Get-WavesDriverRunning
    $driverStart = $null
    try { $driverStart = (Get-ItemProperty -LiteralPath $regPath -Name Start -ErrorAction Stop).Start } catch {}
    if ($null -eq $driverRunning -or $null -eq $driverStart) {
        Write-Host (Get-Text 'DriverStateUnknown') -ForegroundColor Red
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); return
    }
    $session = [pscustomobject]@{Schema=1;SavedAt=(Get-Date).ToString('o');DriverStart=[int]$driverStart;DriverRunning=[bool]$driverRunning;
        Service=(Get-WavesAudioServiceSnapshot);RenderDefaults=(Get-DefaultRenderEndpointSnapshot);OwnedProcesses=@()}
    try { Save-SwarmSession $session }
    catch { Write-Host "$(Get-Text 'BackupRequired') $($_.Exception.Message)" -ForegroundColor Red; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); return }
    $oldControlC = $false
    try {
        Write-Host " [1/3] $((Get-Text 'ServiceTemporaryStart'))" -ForegroundColor Cyan
        if ($session.Service) { Set-WavesAudioServiceState 3 $true }
        Set-WavesDriverMode 3 -StartNow
        foreach ($candidate in @((Find-WavesExecutable),(Get-WavesLoopbackExecutable))) {
            if (-not $candidate) { continue }
            $name = [IO.Path]::GetFileNameWithoutExtension($candidate)
            if (-not (Get-Process -Name $name -ErrorAction SilentlyContinue)) {
                $started = Start-Process -FilePath $candidate -WorkingDirectory (Split-Path -Parent $candidate) -WindowStyle Hidden -PassThru -ErrorAction Stop
                try {
                    $session.OwnedProcesses += [pscustomobject]@{Id=$started.Id;Path=$candidate;StartTimeUtc=$started.StartTime.ToUniversalTime().ToString('o')}
                    Save-SwarmSession $session
                } catch { throw "Cannot record started component: $candidate" }
            }
        }
        Write-Host " [2/3] $((Get-Text 'SwarmAutopilotRunning'))" -ForegroundColor Cyan
        if (@(Get-RoccatSwarmUiProcesses).Count -eq 0) { Start-Process -FilePath $swarmExe -WorkingDirectory (Split-Path -Parent $swarmExe) -ErrorAction Stop }
        $timer = [Diagnostics.Stopwatch]::StartNew()
        while (@(Get-RoccatSwarmUiProcesses).Count -eq 0 -and $timer.ElapsedMilliseconds -lt 8000) { Start-Sleep -Milliseconds 250 }
        if (@(Get-RoccatSwarmUiProcesses).Count -eq 0) { throw (Get-Text 'SwarmStartTimeout') }
        try { $oldControlC = [Console]::TreatControlCAsInput; [Console]::TreatControlCAsInput = $true } catch {}
        while (@(Get-RoccatSwarmUiProcesses).Count -gt 0) {
            try {
                if ([Console]::KeyAvailable) {
                    $key = [Console]::ReadKey($true)
                    if ($key.Key -eq [ConsoleKey]::Escape -or ($key.Key -eq [ConsoleKey]::C -and ([int]$key.Modifiers -band [int][ConsoleModifiers]::Control))) { break }
                }
            } catch {}
            Start-Sleep -Milliseconds 500
        }
    } catch { Write-Host "$(Get-Text 'ActionFailed') $($_.Exception.Message)" -ForegroundColor Red }
    finally {
        try { [Console]::TreatControlCAsInput = $oldControlC } catch {}
        Write-Host " [3/3] $((Get-Text 'SwarmSessionRecovery'))" -ForegroundColor Cyan
        if (Restore-SwarmSession $session) { Write-Host (Get-Text 'DriverStateRestored') -ForegroundColor Green }
        else { Write-Host (Get-Text 'DriverRestoreFailed') -ForegroundColor Red }
    }
    Write-Host (Get-Text 'PressKey') -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}



function Invoke-SentinelaAtiva {
    Write-Host ""
    Write-Host "==============================================================================" -ForegroundColor Magenta
    Write-Host "                         $((Get-Text 'Opt3Title'))                            " -ForegroundColor White
    Write-Host "==============================================================================" -ForegroundColor Magenta
    Write-Host " $((Get-Text 'SentinelStop' 'Pressione ESC para voltar ao menu.'))" -ForegroundColor DarkYellow
    Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkCyan

    Write-Host " $((Get-Text 'SentinelRunning' 'Modo somente leitura: nenhum driver, endpoint ou dispositivo padrao sera alterado.'))" -ForegroundColor Green
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
        $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] API de saida padrao indisponivel; monitorando apenas eventos Audio e estados PnP."
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
                        $stateLabel = if ($state -match '^\d+$') { Get-AudioStateLabel $state } else { 'Estado nao interpretado' }
                        $flowLabel = Get-AudioFlowLabel $flow
                        $eventLine = "[$($event.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss.fff'))] Audio/Operational ID 65 | fluxo=$flow ($flowLabel) | estado=$state ($stateLabel) | $rawData"
                        $eventColor = if ($state -eq '2' -or $state -eq '4' -or $state -eq '8') { 'Red' } elseif ($state -eq '1') { 'Green' } else { 'Yellow' }
                        Write-Host " $eventLine" -ForegroundColor $eventColor
                        Add-Content -LiteralPath $sentinelLog -Value $eventLine -Encoding UTF8 -ErrorAction SilentlyContinue
                    }
                }
            } catch {
                $audioLogUnavailableReported = $true
                $eventLine = "[$now] Log Audio/Operational indisponivel; continuando apenas com o estado PnP."
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

        # A transicao PnP e a selecao da saida padrao sao eventos diferentes.
        # Registra os tres papeis de reproducao para mostrar quando o Windows
        # volta de fato para o headset; endpoints de captura nao sao modificados.
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

function Invoke-FixGlobal {
    Write-Host ""
    Write-Host ">>> $((Get-Text 'Opt4Title'))..." -ForegroundColor Cyan
    if (Test-Path $stateBackupFile) {
        $answer = Read-MenuChoice (Get-Text 'RestorePrompt' 'R restaura a copia; Enter aplica; Q cancela; ESC fecha')
        if ($answer -eq '__ESC__') { [System.Environment]::Exit(0) }
        if ($answer -match '(?i)^q$') { return }
        if ($answer -match '(?i)^r$') {
            Restore-SystemBackup | Out-Null
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return
        }
    }

    if (-not (Save-SystemBackup -RequireCompletePower)) {
        Write-Host " $((Get-Text 'BackupRequired' 'Nao foi possivel confirmar a copia completa; nenhuma alteracao foi feita.'))" -ForegroundColor Red
        Write-Host "$((Get-Text 'PressKey' 'Pressione qualquer tecla para voltar...'))" -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    $failed = $false
    $schemes = Get-PowerSchemeGuids
    if ($schemes.Count -eq 0) { $failed = $true }
    foreach ($guid in $schemes) {
        powercfg.exe /setacvalueindex $guid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { $failed = $true }
        powercfg.exe /setdcvalueindex $guid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { $failed = $true }
    }
    try {
        if (-not (Test-Path 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio')) { New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio' -Force | Out-Null }
        New-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio' -Name UserDuckingPreference -Value 3 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
    } catch { $failed = $true; Write-Host " $($_.Exception.Message)" -ForegroundColor Red }

    $hubCount = 0
    $hubTotal = 0
    $hubQueryAvailable = $false
    $hubSnapshotReady = $false
    try {
        $usbHubs = @(Get-WmiObject -Namespace root\wmi -Class MSPower_DeviceEnable -ErrorAction Stop | Where-Object { $_.InstanceName -match '(?i)ROOT_HUB' })
        $hubQueryAvailable = $true
        $hubTotal = $usbHubs.Count
        if ($hubTotal -gt 0) {
            try {
                $savedSnapshot = Get-Content -LiteralPath $stateBackupFile -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
                $savedHubStates = @($savedSnapshot.UsbHubs)
                $savedHubByName = @{}
                foreach ($savedHub in $savedHubStates) {
                    if ($savedHub.InstanceName -and $null -ne $savedHub.Enable) { $savedHubByName[[string]$savedHub.InstanceName] = $savedHub }
                }
                $hubSnapshotReady = (@($usbHubs | Where-Object { -not $savedHubByName.ContainsKey([string]$_.InstanceName) }).Count -eq 0)
            } catch {}

            if ($hubSnapshotReady) {
                foreach ($hub in $usbHubs) {
                    if ($hub.Enable) {
                        $hub.Enable = $false
                        $null = $hub.Put()
                        $hubCount++
                    }
                }
            } else {
                Write-Host " $((Get-Text 'HubBackupMissing' 'O estado dos Root Hubs nao esta totalmente salvo; eles nao foram alterados.'))" -ForegroundColor Yellow
            }
        }
    } catch { Write-Host " $((Get-Text 'HubPowerNotChanged' 'A consulta de economia dos hubs nao esta disponivel neste computador.'))" -ForegroundColor Yellow }

    $verified = $true
    if ($schemes.Count -eq 0) { $verified = $false }
    foreach ($guid in $schemes) {
        $values = Get-UsbSuspendValues $guid
        if (-not $values -or $values.AC -ne 0 -or $values.DC -ne 0) { $verified = $false }
    }
    try { if ((Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio' -Name UserDuckingPreference -ErrorAction Stop).UserDuckingPreference -ne 3) { $verified = $false } } catch { $verified = $false }
    if ($hubQueryAvailable -and $hubTotal -gt 0 -and -not $hubSnapshotReady) { $verified = $false }
    if ($hubQueryAvailable) {
        if ($hubTotal -eq 0) {
            Write-Host " $((Get-Text 'HubPowerNotFound' 'Nenhum Root Hub foi exposto por essa consulta; o ajuste de energia dos hubs nao foi confirmado.'))" -ForegroundColor Yellow
        } elseif ($hubSnapshotReady) {
            try {
                $remainingEnabled = @(Get-WmiObject -Namespace root\wmi -Class MSPower_DeviceEnable -ErrorAction Stop |
                    Where-Object { $_.InstanceName -match '(?i)ROOT_HUB' -and $_.Enable })
                if ($remainingEnabled.Count -gt 0) { $verified = $false }
            } catch { $verified = $false }
        }
    }
    Write-Host " Hubs USB alterados: $hubCount" -ForegroundColor Gray
    if (-not $failed -and $verified) { Write-Host " $((Get-Text 'SettingsVerified' 'Configuracoes aplicadas e verificadas em todos os planos.'))" -ForegroundColor Green }
    else { Write-Host " $((Get-Text 'ActionFailed' 'Algumas configuracoes nao foram aplicadas ou verificadas.'))" -ForegroundColor Red }
    Write-Host ""
    Write-Host "$((Get-Text 'PressKey'))" -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# --- LOOP PRINCIPAL DO MENU ---
if (-not (Restore-PendingSwarmSession)) {
    Write-Host (Get-Text 'PressKey') -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
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
    
    $choice = Read-MenuChoice (Get-Text 'Prompt' 'Escolha uma opcao (ESC para sair):')
    
    switch ($choice) {
        '1' { Invoke-StableSystemMode }
        '2' { Invoke-SwarmAutoPilot }
        '3' { Invoke-SentinelaAtiva }
        '4' { Invoke-FixGlobal }
        '5' { Show-DiagnosticReport }
        '6' { Show-LanguageSelector }
        '0' { [System.Environment]::Exit(0) }
        'Q' { [System.Environment]::Exit(0) }
        'q' { [System.Environment]::Exit(0) }
        '__ESC__' { [System.Environment]::Exit(0) }
        default { Write-Host " $((Get-Text 'InvalidOption' 'Opcao invalida. Escolha um numero do menu.'))" -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
    }
}
