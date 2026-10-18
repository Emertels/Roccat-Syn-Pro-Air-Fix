# Technical maintenance and agent guide

Applies to this repository's manager, translations, launcher and packaging. Keep user-facing instructions consistent with the implementation.

## Evidence and limits

- October 18, 2026 controlled observations isolated `WavesTBSvc` (Waves Audio Services) as an implicated component on the reported PC: stopping it halted cycling, starting it reproduced cycling. Stopping GUI helpers alone did not help.
- A source-core observation after disabling/stopping the service recorded 60 seconds with zero default changes, zero off-target samples, zero SYN Pro Air state events and unchanged capture defaults. This is a limited observation, not a permanent guarantee or an audible/LED test. Reboot persistence has not been verified.
- Event 65 alone does not identify the initiating process. Dongle presence does not establish headset power state or working audio. Do not claim every cycling case has the same cause or that vendor binaries were repaired.

## Implementation contract

1. Option 1 starts directly after 1 and Enter. Saves the original backup once and disables/stops only `WavesTBSvc`. Never asks for a device, writes render/capture defaults, disables endpoints or disables `WavesTBVirtual`. Uses Core Audio to check SYN Pro Air render/capture and all previously active endpoints. Observes for 30 seconds with an inline percentage bar below the step; never use Write-Progress. Lost availability attempts service rollback and records failure. Applied configuration and confirmed stability are separate; confirmation requires complete observation, available events, unchanged defaults and available devices.
2. Passive monitoring records event 65, PnP, defaults and service without altering them. Keep polling when no new events exist. ESC/Ctrl+C returns to the menu.
3. Diagnostics save service/driver/process details, render/capture defaults, PnP and events, and open mmsys.cpl for manual output choice. PnP Unknown alone does not establish disabled state: query Core Audio.
4. Language saving prioritizes the same profile as loading. Maintain all keys in ten languages; accented Portuguese, UTF-8 BOM.
5. R opens restoration: W restores the service backup; E restores legacy power/communications settings independently of Waves. No additional confirmation in option 1. New power adjustments and temporary Swarm were removed from the menu.
6. Retain pending Swarm session recovery for compatibility: validate snapshots, check PID/path/start time before stopping owned helpers, restore service/driver and report failures. Do not reintroduce temporary activation as the main mitigation.

## Files and packaging

- `Roccat-SynPro-Manager.ps1`: Windows PowerShell 5.1 source, UTF-8 BOM; exactly one `@@ROCCAT_I18N_JSON_EMBED@@` marker.
- `i18n.json`: editable translations retained in the repository.
- `Roccat-SynPro-Manager.vbs`: elevation and native PowerShell launch without CMD; BAT is legacy and excluded from ZIP.
- `tools/New-PortablePackage.ps1`: embeds translations and inspects a ZIP containing exactly PS1 and VBS. Never publish the uncompiled source as the standalone portable PS1.
- `README.md` and `README-PT-BR.md` must match; keep English guides and both changelogs aligned. Credits: Antigravity and Codex.

Runtime data is under `%LOCALAPPDATA%\RoccatSynProManager`, falling back to the script folder: `config.json`, `waves-service-backup.json`, `swarm-session.json`, `system-backup.json`, and diagnostics. Removing standalone translation JSON from the portable folder does not authorize deleting restoration backups.

## Safety and compatibility

- Always preserve current render/capture defaults; do not request device selection in the main mitigation workflow. The render setter uses nonpublic IPolicyConfig; handle failure and provide mmsys.cpl fallback. Do not select headset by name or overwrite per-app preferences.
- Service disablement persists as Windows configuration; no scheduled task or background guard is installed. Vendor repair/updates can re-enable it. Disabling Waves may affect EQ/effects even if Swarm opens. Explain these limits without guaranteeing LEDs or microphone quality.
- Use exact service names and validated snapshots. Check readback, preserve baseline backups and report partial failures. Do not remove driver files or change unrelated audio services/devices.
- Do not apply live service/driver changes merely to check packaging. Obtain task authorization for live configuration changes; follow later user instructions to leave the machine unchanged.
