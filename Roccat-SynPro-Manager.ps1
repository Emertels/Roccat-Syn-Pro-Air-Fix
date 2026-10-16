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
    foreach ($target in @($configFile, $configDataFile)) {
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
            IMMDeviceEnumerator enumerator = null;
            IMMDevice device = null;
            try {
                enumerator = CreateEnumerator();
                int hr = enumerator.GetDefaultAudioEndpoint(EDataFlow.Render, role, out device);
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
            $driverComplete = (-not (Test-Path $regPath) -or ($null -ne $existing.DriverStart -and $null -ne $existing.DriverRunning))
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
    if (($RequireDriver -or (Test-Path $regPath)) -and ($null -eq $driverStart -or $null -eq $driverRunning)) {
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

    if ($null -ne $snapshot.DriverStart -and $null -ne $snapshot.DriverRunning -and (Test-Path $regPath)) {
        try {
            Set-ItemProperty -Path $regPath -Name Start -Value ([int]$snapshot.DriverStart) -ErrorAction Stop
            if ($snapshot.DriverRunning) { sc.exe start $driverName 2>&1 | Out-Null }
            else { sc.exe stop $driverName 2>&1 | Out-Null }
            Start-Sleep -Seconds 2
            $restoredStart = (Get-ItemProperty -Path $regPath -Name Start -ErrorAction Stop).Start
            $restoredRunning = Get-WavesDriverRunning
            if ([int]$restoredStart -ne [int]$snapshot.DriverStart) { $ok = $false }
            if ($null -eq $restoredRunning -or [bool]$restoredRunning -ne [bool]$snapshot.DriverRunning) { $ok = $false }
        } catch { $ok = $false }
    } elseif ((Test-Path $regPath) -or $null -ne $snapshot.DriverStart -or $null -ne $snapshot.DriverRunning) {
        $ok = $false
    }

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
    foreach ($serviceName in @('Audiosrv','AudioEndpointBuilder')) {
        try { $service = Get-Service -Name $serviceName -ErrorAction Stop; $lines.Add("$serviceName = $($service.Status)") }
        catch { $lines.Add("$serviceName = nao consultado") }
    }

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
    $info = Get-SystemAudioInfo

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

function Invoke-OutputGuard {
    Write-Host ""
    Write-Host ">>> $((Get-Text 'Opt1Title'))..." -ForegroundColor Cyan
    if (-not (Initialize-CoreAudioApi)) {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    $endpoints = @()
    try { $endpoints = @([RoccatSynProAudioFix.CoreAudio]::GetActiveRenderEndpoints()) }
    catch {
        Write-Host " $((Get-Text 'AudioApiFailed' 'Nao foi possivel enumerar as saidas de audio.')) $($_.Exception.Message)" -ForegroundColor Red
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    if ($endpoints.Count -eq 0) {
        Write-Host " $((Get-Text 'OutputNoEndpoints' 'Nenhuma saida de audio ativa foi encontrada.'))" -ForegroundColor Red
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    $initialDefaults = Get-DefaultRenderEndpointSnapshot
    Write-Host " $((Get-Text 'OutputChooseHeading' 'Escolha a saida que deve continuar como padrao:'))" -ForegroundColor White
    for ($i = 0; $i -lt $endpoints.Count; $i++) {
        $endpoint = $endpoints[$i]
        $isDefault = $initialDefaults -and ($endpoint.Id -eq $initialDefaults.Console -or $endpoint.Id -eq $initialDefaults.Multimedia -or $endpoint.Id -eq $initialDefaults.Communications)
        $tag = if ($isDefault) { Get-Text 'OutputDefaultTag' '[padrao atual]' } else { '' }
        Write-Host ("  [{0}] {1} {2}" -f ($i + 1), $endpoint.Name, $tag) -ForegroundColor $(if ($isDefault) { 'Yellow' } else { 'Gray' })
    }
    $selection = Read-MenuChoice (Get-Text 'OutputSelectPrompt' 'Numero da saida desejada (ESC cancela):')
    if ($selection -eq '__ESC__') { return }
    $selectedIndex = 0
    if (-not [int]::TryParse([string]$selection, [ref]$selectedIndex) -or $selectedIndex -lt 1 -or $selectedIndex -gt $endpoints.Count) {
        Write-Host " $((Get-Text 'InvalidOption' 'Opcao invalida.'))" -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    $target = $endpoints[$selectedIndex - 1]
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

function Invoke-SwarmAutoPilot {
    Write-Host ""
    Write-Host ">>> $((Get-Text 'Opt2Title'))..." -ForegroundColor Yellow
    $swarmExe = Find-SwarmExecutable
    if (-not $swarmExe) {
        Write-Host " $((Get-Text 'SwarmNotFound' 'ROCCAT Swarm nao foi encontrado nos caminhos padrao.'))" -ForegroundColor Red
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    if (-not (Save-SystemBackup -RequireDriver)) {
        Write-Host " $((Get-Text 'BackupRequired' 'Nao foi possivel confirmar a copia de seguranca; nenhuma alteracao foi feita.'))" -ForegroundColor Red
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    $priorDriverStart = $null
    $priorDriverRunning = Get-WavesDriverRunning
    try { $priorDriverStart = (Get-ItemProperty -Path $regPath -Name 'Start' -ErrorAction Stop).Start } catch {}
    if ($null -eq $priorDriverStart -or $null -eq $priorDriverRunning) {
        Write-Host " $((Get-Text 'DriverStateUnknown' 'Nao foi possivel ler o estado anterior do driver; nenhuma alteracao foi feita.'))" -ForegroundColor Red
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    $swarmWasRunning = @(Get-RoccatSwarmUiProcesses).Count -gt 0
    try {
        Set-WavesDriverMode 3 -StartNow
        $wavesExe = Find-WavesExecutable
        if ($wavesExe -and -not (Get-Process -Name 'ROCCAT_Waves_Driver' -ErrorAction SilentlyContinue)) { Start-Process -FilePath $wavesExe -ErrorAction Stop }
        if (-not $swarmWasRunning) { Start-Process -FilePath $swarmExe -ErrorAction Stop }

        # Aguarda a interface principal. O Monitor auxiliar pode estar sempre
        # residente e nao deve impedir a restauracao apos fechar o Swarm.
        $launchTimer = [System.Diagnostics.Stopwatch]::StartNew()
        while (@(Get-RoccatSwarmUiProcesses).Count -eq 0 -and $launchTimer.ElapsedMilliseconds -lt 8000) {
            Start-Sleep -Milliseconds 250
        }
        if (@(Get-RoccatSwarmUiProcesses).Count -eq 0) {
            $restored = Restore-WavesDriverState $priorDriverStart $priorDriverRunning
            Write-Host " $((Get-Text 'SwarmStartTimeout' 'O processo do Swarm nao apareceu em 8 segundos; a configuracao anterior do driver sera restaurada.'))" -ForegroundColor Red
            if ($restored) { Write-Host " $((Get-Text 'DriverStateRestored' 'Estado anterior do driver restaurado e verificado.'))" -ForegroundColor Yellow }
            else { Write-Host " $((Get-Text 'DriverRestoreFailed' 'Nao foi possivel confirmar a restauracao do estado anterior do driver.'))" -ForegroundColor Red }
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return
        }
    } catch {
        $restored = Restore-WavesDriverState $priorDriverStart $priorDriverRunning
        Write-Host " $((Get-Text 'ActionFailed' 'Falha ao iniciar o Swarm/driver.')) $($_.Exception.Message)" -ForegroundColor Red
        if ($restored) { Write-Host " $((Get-Text 'DriverStateRestored' 'Configuracao anterior do driver restaurada.'))" -ForegroundColor Yellow }
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    Write-Host " $((Get-Text 'SwarmAutopilotRunning' 'Modo temporario apenas para configurar EQ/microfone; nao corrige o audio. Saia totalmente do Swarm ou pressione ESC para restaurar o driver.'))" -ForegroundColor Cyan
    Write-Host ""

    $oldTreatControlC = $false
    $monitorCancelled = $false
    $swarmClosed = $false
    try { $oldTreatControlC = [Console]::TreatControlCAsInput; [Console]::TreatControlCAsInput = $true } catch {}
    try {
        while ($true) {
            try {
                if ([Console]::KeyAvailable) {
                    $pressed = [Console]::ReadKey($true)
                    $isCtrlC = ($pressed.Key -eq [ConsoleKey]::C -and (([int]$pressed.Modifiers -band [int][ConsoleModifiers]::Control) -ne 0))
                    if ($pressed.Key -eq [ConsoleKey]::Escape -or $isCtrlC) {
                        $monitorCancelled = $true
                        break
                    }
                }
            } catch {}
            if (@(Get-RoccatSwarmUiProcesses).Count -eq 0) {
                $swarmClosed = $true
                break
            }
            Start-Sleep -Milliseconds 750
        }
    } finally { try { [Console]::TreatControlCAsInput = $oldTreatControlC } catch {} }
    if ($swarmClosed -or $monitorCancelled) {
        if (Restore-WavesDriverState $priorDriverStart $priorDriverRunning) {
            $messageKey = if ($monitorCancelled) { 'SwarmWatchEscape' } else { 'DriverStateRestored' }
            $fallback = if ($monitorCancelled) { 'Monitoramento encerrado; o estado anterior do driver foi restaurado. O Swarm continua aberto e pode perder recursos Waves.' } else { 'Swarm fechado; estado anterior do driver restaurado e confirmado.' }
            Write-Host " $((Get-Text $messageKey $fallback))" -ForegroundColor Green
        } else {
            Write-Host " $((Get-Text 'DriverRestoreFailed' 'Nao foi possivel confirmar a restauracao do estado anterior do driver.'))" -ForegroundColor Red
        }
    }
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
        $outputs = @(Get-SynOutputEndpoints)
        $microphone = Get-SynMicrophoneEndpoint
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
        '1' { Invoke-OutputGuard }
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
