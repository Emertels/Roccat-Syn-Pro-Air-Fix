# Technical maintenance and agent guide

Applies to this repository's manager, translations, launcher and packaging. Keep user-facing instructions consistent with the implementation.

## Evidence and limits

- October 18, 2026 controlled observations isolated `WavesTBSvc` (Waves Audio Services) as an implicated component on the reported PC: stopping it halted cycling, starting it reproduced cycling. Stopping GUI helpers alone did not help.
- A source-core observation after disabling/stopping the service recorded 60 seconds with zero default changes, zero off-target samples, zero SYN Pro Air state events and unchanged capture defaults. This is a limited observation, not a permanent guarantee or an audible/LED test. Reboot persistence has not been verified.
- Event 65 alone does not identify the initiating process. Dongle presence does not establish headset power state or working audio. Do not claim every cycling case has the same cause or that vendor binaries were repaired.

## Implementation contract

1. Option 1 snapshots the exact `WavesTBSvc` service, saves the baseline once, disables/stops it, applies an explicitly selected active render endpoint to all three roles and observes for 30 seconds without reapplying the default. Success requires service readback, complete observation, event availability, zero changes/off-target samples/state events, unchanged capture defaults and matching final render roles. Applied configuration and confirmed stability are separate results. Before application completes, failures attempt to restore prior service/render state. R restores the service baseline; P opens the optional session guard. Do not disable `WavesTBVirtual` as part of option 1.
2. Option 2 records temporary driver/service/render state before mutation, enables Waves and opens Swarm. Watch `ROCCAT_Swarm.exe`, not its resident monitor. A finally block restores prior state on monitored exit or ESC/Ctrl+C. Only terminate helpers launched by this session after matching PID, path and start time. Interrupted sessions recover on next launch; retain snapshots on service/driver restoration failure. Playback restoration failures must also be reported. Waves cycling can return while the service is temporarily active.
3. Passive monitoring records event 65, PnP transitions, render defaults and service changes without altering them. Keep polling if there are no events. ESC/Ctrl+C returns to the menu.
4. Power/communications settings have their own backup and verification. Restoring them must not modify Waves driver/service state. Do not require a readable kernel-driver state to adjust power settings.
5. Diagnostics include service configuration, driver, relevant processes, capture/render defaults, PnP/parents/problem codes and recent events. Reports are evidence, not automatic attribution.
6. Language saving prefers the same user-profile configuration that loading prefers. Update all ten languages for every new UI key.

## Files and packaging

- `Roccat-SynPro-Manager.ps1`: Windows PowerShell 5.1 source, UTF-8 BOM; exactly one `@@ROCCAT_I18N_JSON_EMBED@@` marker.
- `i18n.json`: editable translations retained in the repository.
- `Roccat-SynPro-Manager.vbs`: elevation and native PowerShell launch without CMD; BAT is legacy and excluded from ZIP.
- `tools/New-PortablePackage.ps1`: embeds translations and inspects a ZIP containing exactly PS1 and VBS. Never publish the uncompiled source as the standalone portable PS1.
- `README.md` and `README-PT-BR.md` must match; keep English guides and both changelogs aligned. Credits: Antigravity and Codex.

Runtime data is under `%LOCALAPPDATA%\RoccatSynProManager`, falling back to the script folder: `config.json`, `waves-service-backup.json`, `swarm-session.json`, `system-backup.json`, and diagnostics. Removing standalone translation JSON from the portable folder does not authorize deleting restoration backups.

## Safety and compatibility

- Always preserve explicit playback choice and capture defaults. The render setter uses nonpublic IPolicyConfig; handle failure and provide mmsys.cpl fallback. Do not select headset by name or overwrite per-app preferences.
- Service disablement persists as Windows configuration; no scheduled task or background guard is installed. Vendor repair/updates can re-enable it. Disabling Waves may affect EQ/effects even if Swarm opens. Explain these limits without guaranteeing LEDs or microphone quality.
- Use exact service names and validated snapshots. Check readback, preserve baseline backups and report partial failures. Do not remove driver files or change unrelated audio services/devices.
- Do not apply live service/driver changes merely to check packaging. Obtain task authorization for live configuration changes; follow later user instructions to leave the machine unchanged.
