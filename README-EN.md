# ROCCAT Syn Pro Air — audio diagnostics and manager

A portable utility for holding the user's chosen playback output, investigating ROCCAT Syn Pro Air endpoint changes, and applying selected reversible settings on Windows 10 and 11.

[![Version 1.2.0](https://img.shields.io/badge/version-1.2.0-blue)](https://github.com/Emertels/Roccat-Syn-Pro-Air-Fix/releases/tag/v1.2.0) · [Português (Brasil)](README.md) · [Changelog](CHANGELOG-EN.md)

> **Important limitation:** option 1 is a temporary guard. While the panel stays open, it reapplies the playback output you choose if Windows switches to another device. This works around the automatic switch but does not identify or repair the cause of the headset endpoint disappearing and returning. Audio event 65 records a state change but does not identify who initiated it.

## What the available evidence says

In the reported case, the log showed the output and microphone endpoints cycling between disabled and active with `ProblemCode=0`, while the dongle remained listed. This confirms audio endpoint state changes, but does not identify whether they began in the driver, Swarm, USB path, wireless link, or Windows audio services. The updated trace separately records when Windows changes the default playback device.

The panel never selects the headset automatically: in option 1, you explicitly choose the output to hold. The guard changes only the three Windows playback roles; it leaves the default capture/microphone device untouched. It runs only while the panel is open. After ESC, the selected output remains the default, but Windows or an application may change it again later.

Changing the playback default uses a Windows policy interface that is not publicly documented. If Windows does not confirm the change, the script restores the previous roles when possible and opens `mmsys.cpl` for manual selection. Per-app outputs are not overridden by this guard.

## Technical basis

Windows Core Audio queries the default endpoint by direction and role (`Console`, `Multimedia`, or `Communications`). Its documentation treats a default-endpoint change and an endpoint-state change as separate notifications. The report therefore records these signals separately; neither alone identifies which program initiated the change. Endpoint IDs are treated as opaque identifiers, as Microsoft documents.

References: [querying the default endpoint](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdeviceenumerator-getdefaultaudioendpoint), [default-device-change notification](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immnotificationclient-ondefaultdevicechanged), [endpoint-state notification](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immnotificationclient-ondevicestatechanged), and [endpoint state values](https://learn.microsoft.com/en-us/windows/win32/coreaudio/device-state-xxx-constants). The private interface used to set the default is not part of the documented public API; compatibility depends on the Windows implementation.

## Menu

| Option | What it does | Effects and limits |
|---|---|---|
| **1 — Pin default output** | Lists active outputs; you choose one. The panel sets it as default for Console, Multimedia, and Communications and reapplies it if it changes while monitoring is open. | Does not change the microphone or Waves driver. The guard stops on ESC/Ctrl+C; the chosen output remains default afterward. Changes are logged in `default-output-guard.log`. |
| **2 — Temporary Swarm** | Captures the driver's prior state, enables/starts Waves, and opens Swarm. It waits for the `ROCCAT_Swarm.exe` interface process and ignores `ROCCAT_Swarm_Monitor.exe`, which can stay resident in the background. | For EQ/microphone setup only; it does not fix output switching. Exit Swarm fully from its tray icon or use ESC/Ctrl+C to restore the driver. Cancelling leaves Swarm open. |
| **3 — Passive monitoring** | Watches event 65, endpoint PnP states, and the Console, Multimedia, and Communications playback defaults. | Read-only: does not change the driver, endpoints, microphone, or default output. ESC/Ctrl+C returns to the menu. The log is `%LOCALAPPDATA%\RoccatSynProManager\diagnostics\sentinela.log`. |
| **4 — USB power and communications** | Saves a snapshot and adjusts USB selective suspend across power plans, the current user's communications ducking preference, and—when WMI exposes it—Root Hub power saving. | Verified settings and the snapshot are stored in `%LOCALAPPDATA%\RoccatSynProManager\system-backup.json`. `R` restores the snapshot, `Enter` applies/reapplies, and `Q` cancels. It may not resolve the disconnects. |
| **5 — Diagnostics and Sound panel** | Writes a report with PnP endpoints, driver details, recent audio/USB events, playback defaults by role, and opens `mmsys.cpl`. | The report is saved under `diagnostics`. Review it before sharing: it includes the computer name, device IDs, and local events. |
| **6 — Language** | Selects one of ten languages; automatic detection is used initially. | Translations in the portable release are embedded in the `.ps1`; the selected language is stored in the user's local profile. |

To protect your speakers, choose them in option 1 and leave the panel open while using the PC. If the selected output becomes unavailable, the script waits for it to return and logs the state. Option 2 may temporarily change the Waves driver and affect Swarm effects. Option 1 does not change capture/microphone; no option guarantees LEDs or other controls.

## Start the tool

1. Download `Roccat-Syn-Pro-Air-Fix-v1.2.0-Portable.zip` from the [release page](https://github.com/Emertels/Roccat-Syn-Pro-Air-Fix/releases/tag/v1.2.0) and extract both files into one folder.
2. Open **`Roccat-SynPro-Manager.vbs`**. It requests elevation through UAC and starts PowerShell without an intermediate CMD window.
3. To keep playback from switching back to the headset during a session, choose **1**, select your speakers, and leave the panel open. `ESC` stops the guard and returns to the menu; `ESC` in the main menu closes the panel.

This is a portable package, not an installer. It contains only the PowerShell script and the VBS launcher. Administrator privileges are required for options that change the driver or system settings. Windows may show a security prompt for downloaded scripts; verify the source and contents before allowing it to run.

## Data and restore

Configuration, backups, and diagnostics are stored in `%LOCALAPPDATA%\RoccatSynProManager` (with a fallback to the script folder if the user profile is unavailable). Options that modify settings verify them before/after whenever Windows exposes a query path. Option 4 can restore the snapshot; do not delete `system-backup.json` before restoring.

Option 3 is read-only and separates endpoint reactivation from an actual default-output change. An event still does not identify the responsible program; compare report timestamps with PnP and USB/Kernel-PnP events. Logs and backups are under `%LOCALAPPDATA%\RoccatSynProManager`.

## Repository files

- `Roccat-SynPro-Manager.ps1`: panel source. In the repository, translations are edited in `i18n.json`; packaging embeds them into the distributed script.
- `Roccat-SynPro-Manager.vbs`: elevated launcher without an intermediate CMD window.
- `tools/New-PortablePackage.ps1`: builds and inspects a ZIP containing only the `.ps1` and `.vbs`.
- `AGENTS-PT-BR.md` / `AGENTS-EN.md`: architecture and maintenance guidance.

## Credits

Developed with **Antigravity and Codex** and distributed under the MIT license; see [LICENSE](LICENSE).
