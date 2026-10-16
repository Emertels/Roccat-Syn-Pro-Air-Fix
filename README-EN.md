# ROCCAT Syn Pro Air — audio diagnostics and manager

A portable utility for investigating ROCCAT Syn Pro Air audio endpoint changes and applying selected reversible settings on Windows 10 and 11.

[![Version 1.2.0](https://img.shields.io/badge/version-1.2.0-blue)](https://github.com/Emertels/Roccat-Syn-Pro-Air-Fix/releases/tag/v1.2.0) · [Português (Brasil)](README.md) · [Changelog](CHANGELOG-EN.md)

> **Important limitation:** this release improves diagnostics and makes the panel's actions more careful. It does not prove the cause of disconnects or promise a permanent fix. Windows Audio event 65 records a state change; by itself, it does not identify which program, driver, or component initiated it.

## What the available evidence says

In the reported case, the USB dongle remains connected while Windows removes and re-enumerates the headset/microphone endpoint. That points to a Windows audio endpoint state change, but a dongle with PnP status `OK` does not prove that the wireless headset is powered on, that its radio link is stable, or that audio is working. Possible areas to compare include the `WavesTBVirtual` driver, Swarm, the USB path, and Windows audio services.

The panel does not select the Syn Pro Air as the default output. It cannot detect whether the wireless headset itself is powered on when only the dongle is connected.

## Menu

| Option | What it does | Effects and limits |
|---|---|---|
| **1 — Stable mode** | Saves or checks a snapshot, then attempts to stop `WavesTBVirtual`, set its startup type to disabled, and verify the result. | May disable Swarm Waves audio features. It does not select a default output or guarantee stability. Option 4 can restore the saved state. |
| **2 — Temporary Swarm** | Captures the driver's prior state, enables/starts Waves, and opens Swarm. When Swarm closes, it attempts to restore the prior state. | `ESC` or `Ctrl+C` stops monitoring and also attempts to restore the driver; Swarm remains open and may lose Waves features. Force-closing the console/process can prevent automatic restoration. |
| **3 — Passive monitoring** | Watches event 65 in `Microsoft-Windows-Audio/Operational` and the PnP states of the output and microphone endpoints. | Does not change the driver, endpoints, or default output. `ESC` or `Ctrl+C` returns to the menu. The log is `%LOCALAPPDATA%\RoccatSynProManager\diagnostics\sentinela.log`. |
| **4 — USB power and communications** | Saves a snapshot and adjusts USB selective suspend across power plans, the current user's communications ducking preference, and—when WMI exposes it—Root Hub power saving. | Verified settings and the snapshot are stored in `%LOCALAPPDATA%\RoccatSynProManager\system-backup.json`. `R` restores the snapshot, `Enter` applies/reapplies, and `Q` cancels. It may not resolve the disconnects. |
| **5 — Diagnostics and Sound panel** | Writes a report with PnP endpoints, driver details, recent audio/USB events, and opens `mmsys.cpl`. | The report is saved under `diagnostics`. Review it before sharing: it includes the computer name, device IDs, and local events. |
| **6 — Language** | Selects one of ten languages; automatic detection is used initially. | Translations in the portable release are embedded in the `.ps1`; the selected language is stored in the user's local profile. |

Option 1 changes the Waves driver service configuration in the Registry and stops the driver service. The saved state can be restored, but EQ, surround, mic monitoring, or other Swarm features may be affected. Check playback, microphone, and Swarm after changing settings. This utility does not guarantee LEDs or other controls.

## Start the tool

1. Download `Roccat-Syn-Pro-Air-Fix-v1.2.0-Portable.zip` from the [release page](https://github.com/Emertels/Roccat-Syn-Pro-Air-Fix/releases/tag/v1.2.0) and extract both files into one folder.
2. Open **`Roccat-SynPro-Manager.vbs`**. It requests elevation through UAC and starts PowerShell without an intermediate CMD window.
3. Read each prompt before choosing an option. `ESC` in the main menu closes the panel; `ESC` in a monitoring option returns to the menu.

This is a portable package, not an installer. It contains only the PowerShell script and the VBS launcher. Administrator privileges are required for options that change the driver or system settings. Windows may show a security prompt for downloaded scripts; verify the source and contents before allowing it to run.

## Data and restore

Configuration, backups, and diagnostics are stored in `%LOCALAPPDATA%\RoccatSynProManager` (with a fallback to the script folder if the user profile is unavailable). Options that modify settings verify them before/after whenever Windows exposes a query path. Option 4 can restore the snapshot; do not delete `system-backup.json` before restoring.

Monitoring is read-only. An endpoint event does not identify the cause; compare report timestamps with PnP and USB/Kernel-PnP events for more evidence. To investigate the original issue, run option 3 before and during the instability, then generate the option 5 report.

## Repository files

- `Roccat-SynPro-Manager.ps1`: panel source. In the repository, translations are edited in `i18n.json`; packaging embeds them into the distributed script.
- `Roccat-SynPro-Manager.vbs`: elevated launcher without an intermediate CMD window.
- `tools/New-PortablePackage.ps1`: builds and inspects a ZIP containing only the `.ps1` and `.vbs`.
- `AGENTS-PT-BR.md` / `AGENTS-EN.md`: architecture and maintenance guidance.

## Credits

Developed with **Antigravity and Codex** and distributed under the MIT license; see [LICENSE](LICENSE).
