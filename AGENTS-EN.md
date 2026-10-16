# Technical maintenance and agent guide

This file describes what the repository implements. Do not treat hypotheses, menu labels, or historical claims as evidence of cause or effectiveness.

## Goal and available evidence

The project helps observe ROCCAT Syn Pro Air audio endpoints and offers reversible settings on Windows 10/11. In the current report, the dongle can remain connected while Windows removes and re-enumerates the audio/microphone endpoint. The dongle's PnP status does not tell whether the headset is powered on or identify what initiated an endpoint change. Audio/Operational event 65, when available, records a state change; it does not prove that Waves, Swarm, USB, or hardware caused it.

Do not claim a definitive fix, guaranteed selection of `usbaudio.sys`, working LEDs, or that event 65 identifies the initiating process. Final validation requires observing the user's PC and headset during the failure.

## Structure and launch

- `Roccat-SynPro-Manager.ps1`: PowerShell panel for Windows PowerShell 5.1.
- `i18n.json`: editable source for ten languages.
- `Roccat-SynPro-Manager.vbs`: requests elevation through UAC and starts PowerShell; uses `Sysnative` when a 32-bit VBS host runs on 64-bit Windows.
- `Roccat-SynPro-Manager.bat`: legacy compatibility wrapper, excluded from the portable package.
- `tools/New-PortablePackage.ps1`: replaces the single `@@ROCCAT_I18N_JSON_EMBED@@` marker, writes a UTF-8 BOM PS1, and builds/inspects the release ZIP.
- `README.md` and `README-EN.md`: user guides; `README-PT-BR.md` is the Portuguese copy for an explicit link.
- `CHANGELOG-PT-BR.md` and `CHANGELOG-EN.md`: version history.

The published ZIP contains only `Roccat-SynPro-Manager.ps1` (embedded translations) and `Roccat-SynPro-Manager.vbs`. It is not an installer and does not contain README, agent documents, a separate language JSON, or the BAT wrapper.

## Option behavior

1. **Pin default output:** enumerates active `eRender` endpoints, lets the user choose one, sets Console/Multimedia/Communications roles, and reapplies the choice if it changes while monitoring. It does not change `eCapture`, the driver, or hardware. ESC/Ctrl+C stops the guard; there is no background service/task. The setter uses Windows' IPolicyConfig COM interface, which is not publicly documented; any failure must open the `mmsys.cpl` fallback and must not be reported as success.
2. **Temporary Swarm:** captures the prior startup/running state, sets Start=3, starts Waves and Swarm. It waits for the `ROCCAT_Swarm.exe` interface process and ignores `ROCCAT_Swarm_Monitor.exe`, which can remain resident without a window. When Swarm fully exits or monitoring is cancelled by ESC/Ctrl+C, it attempts to restore the captured state. Cancelling leaves Swarm open; force-terminating PowerShell can interrupt restoration. This option is for EQ/microphone setup, not output-switch repair.
3. **Passive sentinel:** observes event 65, AudioEndpoint PnP states, and default `eRender` roles; it does not modify driver, PnP state, endpoint, or default output. It logs transitions to `sentinela.log` and keeps polling when no new events are present. ESC/Ctrl+C returns to the menu.
4. **Power/communications:** snapshots USB selective-suspend values per power scheme, the prior UserDuckingPreference, and readable WMI states. Applies and checks changes; reports when Root Hubs cannot be enumerated or verified. Restore requires the needed snapshot data.
5. **Diagnostics:** saves PnP state, endpoint parent, problem code when available, playback defaults by role, driver/service details and queried events; opens `mmsys.cpl`. The report does not prove cause.
6. **Language:** saves the preference in the local profile; strings come from `i18n.json` in the repository or embedded JSON in the published script.

Data files are stored under `%LOCALAPPDATA%\RoccatSynProManager`, with a fallback to the script folder. ESC in the main menu exits the process.

## Maintenance rules

- Preserve the user's explicit choice. Never select the headset by name/default; the guard may alter `eRender` roles only after the user chooses an endpoint and must not alter capture/microphone. Do not add background persistence without an explicit option.
- Before changing registry, driver service, or power settings, confirm the required snapshot is complete; afterward verify the resulting state and report partial failures.
- Do not remove or replace Windows driver files. Changes to `WavesTBVirtual` must be described as driver-service changes with possible impact on Swarm features.
- Update every used UI/monitor string in all ten languages; confirm each array has ten values and the JSON remains valid.
- Keep exactly one embedding marker in the source PS1. Build the distribution with the package script, inspect the ZIP, and do not add documentation to the portable asset.
- Separate observation from hypothesis. Do not add hardware/controller IDs, USB bandwidth diagnoses, or Windows internals without machine-specific evidence and a reliable source.
