# Changelog — ROCCAT Syn Pro Air

## [1.2.0] — revision dated 2026-10-18

### Main mitigation

- Option 1 targets **Waves Audio Services (`WavesTBSvc`)**, isolated through service stop/start observations on the affected PC. It no longer relies on stopping the kernel driver that failed in the previous workflow.
- Four stages: original backup, disable/stop service, explicit render selection and 30-second observation. Windows retains the service setting without keeping the panel open.
- Applied configuration and confirmed stability are separate results. Interrupted observation, unavailable events or further changes prevent stability confirmation. Reports retain actual observations.
- **R** restores the original service; **P** retains the optional session output guard. No mode automatically chooses the headset or changes capture defaults.

### Other improvements

- Temporary Swarm snapshots service, driver and render defaults; restores in finally and recovers interrupted sessions on next launch. Session-owned helper processes are matched by PID, path and start time. Failed restoration retains the snapshot.
- Option 2 explains that enabling Waves can bring cycling back; minimizing Swarm to its tray may not exit it.
- Passive monitoring includes service transitions and distinguishes endpoint states from default-output changes. Shared PnP enumeration avoids duplicate work.
- Power/communications restoration is independent of Waves state; unreadable kernel-driver state does not block power settings.
- Diagnostics include service configuration, relevant processes and capture defaults alongside PnP, render defaults and events.
- Language saving now prioritizes the profile used for loading; ten translations remain embedded in the portable PS1.
- Direct VBS-to-PowerShell launch, separate backups for separate purposes and messages that avoid unverified restoration claims.
- Portuguese/English README and maintenance guides updated. ZIP includes only PS1 and VBS, with no separate translation JSON, documentation or BAT.

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
