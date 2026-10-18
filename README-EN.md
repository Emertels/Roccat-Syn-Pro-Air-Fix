# ROCCAT Syn Pro Air — audio management and diagnostics

[Version 1.2.0](https://github.com/Emertels/Roccat-Syn-Pro-Air-Fix/releases/tag/v1.2.0) · [Português](README-PT-BR.md) · [Changelog](CHANGELOG-EN.md)

Portable Windows 10/11 panel with ten languages, reversible Waves service mitigation, preservation of audio devices and current defaults and SYN Pro Air endpoint diagnostics.

## Investigation findings

On October 18, 2026, the SYN Pro Air render and capture endpoints repeatedly changed between disabled and active while the dongle remained present. Playback also switched back to the headset after selecting speakers. Stopping Swarm/Waves GUI helpers alone did not stop this cycle.

In controlled observations, stopping **Waves Audio Services (`WavesTBSvc`)** stopped the cycle; starting that same service reproduced it. Applying the new mitigation produced **60 seconds with no default-output changes, no off-target samples and no SYN Pro Air state-change events**, with all three capture defaults unchanged. The service was subsequently restored at the user's request to test from the panel; the user reported the fault returning.

This isolates an implicated Waves component on this computer. It does not identify the internal faulty instruction or establish a universal cause for disconnections. The script supplies a persistent, reversible mitigation without patching vendor binaries. Reboot persistence still requires user confirmation; vendor updates or repair tools may re-enable the service.

## Main workflow

1. Extract both files from the [v1.2.0 ZIP](https://github.com/Emertels/Roccat-Syn-Pro-Air-Fix/releases/tag/v1.2.0).
2. Open **`Roccat-SynPro-Manager.vbs`** and accept UAC. It starts PowerShell directly without an intermediate CMD window.
3. Select **1**, then press **Enter** to apply. No device selection is required; current defaults are preserved.
4. Follow four stages: service backup, disable/stop Waves Audio Services, check headset, microphone and previously active device availability, observe for 30 seconds.
5. Review the result. Keeping the panel open is unnecessary for the service mitigation. To undo it, use **R → W** in the main menu.

The mitigation does not change defaults or disable endpoints. Observation checks existing defaults and device availability. If the headset, microphone or a previously active device becomes unavailable, it attempts to restore the previous service state and records the outcome. Device availability does not prove audible audio. Interrupted observation, unavailable events or further changes mean stability remains **unconfirmed**. See `diagnostics\last-system-repair.json` in the data folder for the complete result.

## Menu functions

- **1 — Fix automatic audio switching (disable Waves):** type **1 and Enter** in the main menu. Starts directly without another confirmation or device selection. Preserves the original state, disables/stops only `WavesTBSvc`, checks headset/microphone and previously active devices, then observes for 30 seconds. Does not disable endpoints or `WavesTBVirtual`, and never writes render/capture defaults. Unavailability attempts service rollback and reports failure. The percentage bar appears inline below the step.
- **2 — Passive monitor:** records audio event 65, PnP states, render defaults and Waves service state. Read only. ESC/Ctrl+C returns to the menu.
- **3 — Diagnostics and sound panel:** saves a report and opens `mmsys.cpl`. Choose headset or speakers manually in Windows.
- **4 — Language:** ten embedded translations, accented Portuguese, user-profile preference.
- **R — Restore settings:** **W** restores the Waves service; **E** restores legacy power/communications settings if their backup exists. Re-enabling Waves can reproduce the fault.
- **0 or ESC:** exits the panel.

Temporary Swarm and new USB/power adjustments were removed from the menu to focus on the identified mitigation. Legacy power restoration and recovery of pending temporary sessions from older versions remain available. Swarm can still be opened normally outside the script.

## Headset and Swarm impact

Option 1 leaves playback/capture devices enabled, preserves capture defaults and does not close Swarm or its monitor. Disabling Waves Audio Services can make dependent EQ, effects and advanced processing unavailable. Swarm opening does not prove all its effects are active.

The user observed headset and Swarm operation during mitigation. Audible playback, microphone quality, LEDs and individual Swarm controls still require physical confirmation; the script checks Windows states and defaults. Use R → W to restore the service; this can bring cycling back.

## Data and recovery

Data lives in `%LOCALAPPDATA%\RoccatSynProManager`, falling back to the script folder:

- `config.json`: language preference.
- `waves-service-backup.json`: original service configuration for R → W; reapplying does not replace this baseline.
- `swarm-session.json`: pending session from older versions, removed after verified service and driver restoration. Render restoration is also attempted and any failure is reported separately.
- `system-backup.json`: power and communications backup.
- `diagnostics`: reports and observation logs.

Keep backups needed to undo changes. The portable folder needs no separate translation JSON; runtime data JSON files serve a different purpose. Reports can include computer names, device IDs and local events; review before sharing.

## Technical basis and packaging

Windows distinguishes [default-device changes](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immnotificationclient-ondefaultdevicechanged) from [endpoint-state changes](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immnotificationclient-ondevicestatechanged). Event 65 alone does not identify an initiating process. Defaults are queried by [direction and role](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdeviceenumerator-getdefaultaudioendpoint). Legacy session restoration may use the nonpublic `IPolicyConfig` interface; failures offer the classic sound panel as a manual fallback. Per-application output overrides are not changed.

Repository translations remain editable in `i18n.json`. `tools/New-PortablePackage.ps1` embeds them into a UTF-8 BOM PS1 for Windows PowerShell 5.1. The ZIP contains **only PS1 and VBS**, without documentation, BAT or standalone JSON. This is a portable package, not an installer. See [AGENTS-EN.md](AGENTS-EN.md) for maintenance guidance.

## Credits

Developed with **Antigravity and Codex**. [MIT license](LICENSE).
