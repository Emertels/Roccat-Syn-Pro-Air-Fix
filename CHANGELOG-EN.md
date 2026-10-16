# Changelog — ROCCAT Syn Pro Air

Version history for the manager and portable package.

## [1.2.0] — 2026-10-16

### Fixed

- The sentinel is now **passive**: it records audio events and PnP states without changing the default output, selecting the headset, or modifying the driver.
- Monitoring keeps polling when there are no new events; ESC and Ctrl+C stop the monitor and return to the menu.
- Driver restoration in the temporary Swarm flow now uses the captured prior state and verifies the result.
- Option 1 requires the data needed for restoration before it stops/disables the Waves driver.
- The power option verifies settings Windows exposes and reports when Root Hub changes could not be confirmed.
- The VBS launcher starts elevated PowerShell without first opening a CMD window and selects the native path on 64-bit Windows when needed.

### Improved

- Diagnostic report includes PnP endpoints, problem code, endpoint parent, Waves service, and recent audio/USB events.
- Status text describes observed state and no longer treats PnP presence as proof of working audio.
- Language preference and diagnostics use the user's local profile, with a fallback to the portable folder.
- Ten languages are embedded in the distributed PS1. The ZIP contains only the PowerShell script and VBS launcher.
- README and technical guides now separate evidence from hypotheses and explain side effects and restore behavior.

### Known limitations

- This release has not been validated on the user's headset/dongle while the issue is occurring. The cause of endpoint disappearance/re-enumeration remains unconfirmed.
- This release improves diagnostics and action safety; it does not promise a definitive fix. Disabling `WavesTBVirtual` may remove Swarm audio features.

## [1.0.0] — 2026-09-26

- First public PowerShell manager with driver, monitoring, power-setting, Sound panel, and multilingual options.
- The original product copy made stability claims that were not established by telemetry; the 1.2.0 documentation corrects that wording.
