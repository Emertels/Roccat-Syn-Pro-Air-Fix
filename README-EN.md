# ROCCAT Syn Pro Air — audio management and diagnostics

[Version 1.2.0](https://github.com/Emertels/Roccat-Syn-Pro-Air-Fix/releases/tag/v1.2.0) · [Português](README-PT-BR.md) · [Changelog](CHANGELOG-EN.md)

Portable Windows 10/11 panel with ten languages, reversible Waves service mitigation, explicit playback selection and SYN Pro Air endpoint diagnostics.

## Investigation findings

On October 18, 2026, the SYN Pro Air render and capture endpoints repeatedly changed between disabled and active while the dongle remained present. Playback also switched back to the headset after selecting speakers. Stopping Swarm/Waves GUI helpers alone did not stop this cycle.

In controlled observations, stopping **Waves Audio Services (`WavesTBSvc`)** stopped the cycle; starting that same service reproduced it. Applying the new mitigation produced **60 seconds with no default-output changes, no off-target samples and no SYN Pro Air state-change events**, with all three capture defaults unchanged. The service was subsequently restored at the user's request to test from the panel; the user reported the fault returning.

This isolates an implicated Waves component on this computer. It does not identify the internal faulty instruction or establish a universal cause for disconnections. The script supplies a persistent, reversible mitigation without patching vendor binaries. Reboot persistence still requires user confirmation; vendor updates or repair tools may re-enable the service.

## Main workflow

1. Extract both files from the [v1.2.0 ZIP](https://github.com/Emertels/Roccat-Syn-Pro-Air-Fix/releases/tag/v1.2.0).
2. Open **`Roccat-SynPro-Manager.vbs`** and accept UAC. It starts PowerShell directly without an intermediate CMD window.
3. Select **1**, press **Enter** to apply, then choose your playback device from the list.
4. Follow four stages: service backup, disable/stop Waves Audio Services, apply the selected output to all three render roles, observe for 30 seconds.
5. Review the result. Keeping the panel open is unnecessary for the service mitigation. To undo it, select **1**, then **R**.

Observation does not keep reapplying the output. Interrupted observation, unavailable events or further changes mean stability remains **unconfirmed**. See `diagnostics\last-system-repair.json` in the data folder for the complete result.

## Menu functions

- **1 — Waves service mitigation:** preserves the original service state once, disables/stops `WavesTBSvc` and verifies it. Does not disable the `WavesTBVirtual` kernel driver or change capture defaults. **R** restores the service. **P** opens the optional session output guard, which reapplies your chosen render device while the window remains open; ESC/Ctrl+C stops that guard.
- **2 — Temporary Swarm:** snapshots service, kernel driver and render defaults; temporarily enables Waves and launches Swarm. Watches `ROCCAT_Swarm.exe`, ignoring its resident monitor. Fully exiting Swarm or pressing ESC/Ctrl+C restores the previous state. Minimizing to the tray keeps the session active; cancelling the monitor leaves Swarm open. The cycling fault can return while Waves is enabled. A forcibly interrupted session is recovered on the next launch; failed restoration retains the snapshot for another attempt.
- **3 — Passive monitor:** records audio event 65, endpoint PnP states, render defaults and Waves service changes. Makes no corrections. ESC/Ctrl+C returns to the menu.
- **4 — USB power and communications:** backs up, applies and checks USB suspend, communications attenuation and accessible Root Hub power settings. **R** restores that backup independently of Waves driver/service state.
- **5 — Diagnostics and sound panel:** saves endpoint/parent PnP, service, driver, relevant processes, render/capture defaults and recent events; opens `mmsys.cpl`.
- **6 — Language:** ten translations embedded in the portable PS1; preference stored in the user profile.
- **0 or ESC in the main menu:** exits. ESC/Ctrl+C in monitors returns to the menu.

## Headset and Swarm impact

Option 1 leaves playback/capture devices enabled, preserves capture defaults and does not close Swarm or its monitor. Disabling Waves Audio Services can make dependent EQ, effects and advanced processing unavailable. Swarm opening does not prove all its effects are active.

The user observed headset and Swarm operation during mitigation. Audible playback, microphone quality, LEDs and individual Swarm controls still require physical confirmation; the script checks Windows states and defaults. Option 2 offers temporary Waves access with the risk that cycling returns during that session.

## Data and recovery

Data lives in `%LOCALAPPDATA%\RoccatSynProManager`, falling back to the script folder:

- `config.json`: language preference.
- `waves-service-backup.json`: original service configuration for option 1 / R; reapplying does not replace this baseline.
- `swarm-session.json`: pending option 2 session, removed after verified service and driver restoration. Render restoration is also attempted and any failure is reported separately.
- `system-backup.json`: power and communications backup.
- `diagnostics`: reports and observation logs.

Keep backups needed to undo changes. The portable folder needs no separate translation JSON; runtime data JSON files serve a different purpose. Reports can include computer names, device IDs and local events; review before sharing.

## Technical basis and packaging

Windows distinguishes [default-device changes](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immnotificationclient-ondefaultdevicechanged) from [endpoint-state changes](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immnotificationclient-ondevicestatechanged). Event 65 alone does not identify an initiating process. Defaults are queried by [direction and role](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdeviceenumerator-getdefaultaudioendpoint). Render selection uses the nonpublic `IPolicyConfig` interface; failures offer the classic sound panel as a manual fallback. Per-application output overrides are not changed.

Repository translations remain editable in `i18n.json`. `tools/New-PortablePackage.ps1` embeds them into a UTF-8 BOM PS1 for Windows PowerShell 5.1. The ZIP contains **only PS1 and VBS**, without documentation, BAT or standalone JSON. This is a portable package, not an installer. See [AGENTS-EN.md](AGENTS-EN.md) for maintenance guidance.

## Credits

Developed with **Antigravity and Codex**. [MIT license](LICENSE).
