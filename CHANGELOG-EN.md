# Changelog — ROCCAT Syn Pro Air

## [1.2.0] — revision dated 2026-10-18

### Main mitigation

- Option 1 targets **Waves Audio Services (`WavesTBSvc`)**, isolated through service stop/start observations on the affected PC. It no longer relies on stopping the kernel driver that failed in the previous workflow.
- Four stages: original backup, disable/stop service, device availability check without output selection and 30-second observation. Windows retains the service setting without keeping the panel open.
- Applied configuration and confirmed stability are separate results. Interrupted observation, unavailable events or further changes prevent stability confirmation. Reports retain actual observations.
- **R → W** restores the original service. Option 1 requests no output selection and changes no render/capture defaults. Checks headset, microphone and previously active devices; loss of availability attempts service rollback and records the failure.

### Simplified interface and menu

- Option 1 starts directly with **1 + Enter**, with no extra confirmation or device selection and no default-output changes. Choose output manually in Windows.
- Current menu: **1 mitigation; 2 monitoring; 3 diagnostics; 4 language; R restoration; 0 exit**.
- Temporary Swarm and new USB/power adjustments removed from the menu. Legacy session recovery and power-backup restoration retained for compatibility.
- R offers **W** to restore the Waves service and **E** to restore legacy power/communications settings.
- Portuguese accents and cedillas restored in menus, steps, tips and diagnostics, preserving UTF-8 BOM.
- PowerShell progress overlay replaced with an inline percentage/time bar below the step. Interrupted observation never displays artificial 100% completion.
- Core Audio availability checks require headset, microphone and previously active devices to remain available. Unavailability attempts service rollback and records failure.
- Header queries the audio API rather than treating PnP Unknown as disabled. Power-plan queries removed from startup.
- After manually re-enabling the headset, the user reported cycling had stopped. A later API read showed headset, microphone and CREATIVE active; this does not prove audible playback.
- Obsolete workflow code and UI strings removed; ten embedded languages, with preference saved in the user profile.
- Passive monitoring and diagnostics retained. Portuguese/English README and maintenance guides aligned with the current menu.
- ZIP contains only PS1 and VBS, without standalone JSON, documentation or BAT.

### Evidence and limitations

- With the service disabled/stopped, a 60-second observation recorded zero default changes, zero off-target samples and zero SYN Pro Air state events, with unchanged capture defaults. Starting the service reproduced cycling in a controlled observation. After restoration for panel testing, the user also reported recurrence.
- This does not identify the internal vendor defect, guarantee every case or verify reboot persistence. Dependent Waves EQ/effects can be unavailable. Audible audio, LEDs and individual Swarm controls need physical confirmation. Vendor updates/repairs can re-enable the service.

### Credits

- Developed with **Antigravity and Codex**.

## [1.2.0] — initial publication on 2026-10-16

- Passive monitoring, explicit output guard, temporary driver restoration, power checks, VBS launch without CMD and embedded translations.
- The October 18 revision replaces the same-version ZIP at the maintainer's request and incorporates Waves service investigation.

## [1.0.0] — 2026-09-26

- First public version with driver management, monitoring, power settings, sound panel and languages.
