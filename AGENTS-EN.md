# 🤖 AGENTS-EN.md — Technical Guide for AI Agents & Open-Source Contributors

This document provides complete system architecture specifications, hardware registers, driver mechanics, and diagnostic heuristics for autonomous AI agents (such as Antigravity, Claude, Copilot, etc.) and human developers working on or auditing the **ROCCAT Syn Pro Air Master Fix** repository.

---

## 📋 1. Project Mission & Historical Background

* **Goal:** Definitively resolve the chronic audio-cycling, disconnect, and speaker-switching bug on the **ROCCAT Syn Pro Air** wireless gaming headset on Windows 10 and Windows 11.
* **Original Author & Investigator:** Emerson Teles.
* **AI Pair Programming Partner:** Antigravity (Google DeepMind).
* **Corporate Market Context:** ROCCAT was acquired and retired by Turtle Beach. The Syn Pro Air is legacy hardware unsupported by the newer Turtle Beach Swarm II software suite, remaining pinned to ROCCAT Swarm 1 with an unmaintained 2021 kernel driver (`WavesTBVirtual.sys`) that suffers silent buffer desynchronization upon cumulative Windows updates.
* **Tested Environment:** Validated and proven across multiple fresh OS installations and hardware revisions by Emerson Teles.

---

## 🔌 2. Hardware Identification & Audio Endpoints

| Attribute | Technical Value |
| :--- | :--- |
| **Vendor ID (VID)** | `1E7D` (ROCCAT / Turtle Beach) |
| **Product ID (PID)** | `3A3B` (Syn Pro Air 2.4GHz Wireless Transmitter Dongle) |
| **Parent USB Device** | `USB\VID_1E7D&PID_3A3B\5018C4BF4C18` |
| **Composite Interfaces** | `MI_00` (HID Controls), `MI_01` (USB Audio Class 1/2), `MI_05` (Lighting & Firmware) |
| **Native Microsoft Driver** | `usbaudio.sys` (`wdma_usb.inf` provided by Microsoft) |
| **Problematic Driver** | `WavesTBVirtual.sys` (`C:\Windows\system32\drivers\WavesTBVirtual.sys`) |
| **Virtual Device Node** | `ROOT\MEDIA\0000` (*Virtual Audio Device*) |

---

## ⚙️ 3. Failure Mode Mechanics & Diagnostic Heuristics

### The Conflict Chain:
1. When the *Turtle Beach Audio Driver* package is installed, the service `WavesTBVirtual.sys` creates a secondary virtual audio endpoint: `Headset Chat (Turtle Beach)`.
2. The Windows Audio Service (`audiosrv.dll`) and `AudioEndpointBuilder` encounter sample buffer desynchronization during polling routines with the legacy Waves driver.
3. Windows marks the primary endpoint `HEADSET (SYN Pro Air)` as `Unknown` (disabled in `MMDevAPI`), switching the default audio output to secondary devices (e.g., Creative 2.1 speakers).
4. The background process `ROCCAT_Waves_Driver.exe` notices the disabled endpoint and attempts to force it back on, generating an **infinite reset loop** logged in the Windows Event Viewer:
   * **Path:** `Applications and Services Logs > Microsoft > Windows > Audio > Operational`
   * **Event ID:** `65` (*MMDevAPI: Audio device state has changed*)

### Isochronous USB Bandwidth Exhaustion (ASMedia vs. Intel/AMD):
* Connecting the transmitter dongle to ports controlled by third-party chips (such as ASMedia `PCI\VEN_1B21&DEV_3241`) frequently causes *periodic isochronous bandwidth exhaustion* ("USB controller resources exceeded").
* **Technical Requirement:** The dongle must be plugged directly into USB ports connected to the motherboard's primary native chipset (Intel `PCI\VEN_8086&DEV_A3AF` or AMD equivalent).

---

## 🛠️ 4. System Registry & Power Policies

| Policy / Key | Required Target Value | Purpose |
| :--- | :--- | :--- |
| `HKLM:\SYSTEM\CurrentControlSet\Services\WavesTBVirtual` -> `Start` | `4` (Disabled) or `3` (Manual) | `4` prevents kernel driver auto-load, locking headset in rock-solid Microsoft native driver mode. |
| `powercfg` Subgroup `2a737441-1930-4402-8d77-b2bebba308a3`, Option `48e6b7a6-50f5-4782-a5d4-53bb8f07e226` | `0x00000000` (AC & DC) | Disables Windows USB Selective Suspend across all system power plans. |
| `HKCU:\SOFTWARE\Microsoft\Multimedia\Audio` -> `UserDuckingPreference` | `3` (DWORD) | Sets communication ducking to "Do Nothing". |
| WMI `root\wmi:MSPower_DeviceEnable` | `Enable = $false` on Root Hubs | Prevents Windows from placing internal USB hubs into low-power sleep states. |

---

## 🤖 5. Guidelines & Safety Constraints for AI Agents

1. **Preserve Native Microsoft Driver (`usbaudio.sys`):**
   * Never attempt to uninstall or replace Microsoft's native `usbaudio.sys`. The Syn Pro Air hardware functions with 100% audio fidelity and zero drops on this native driver.
2. **Maintain Multilingual Support (10 Languages):**
   * All UI strings are stored in `i18n.json`. When modifying menu options or prompt text, update all 10 language nodes: `pt-BR`, `en-US`, `es-ES`, `fr-FR`, `de-DE`, `it-IT`, `ru-RU`, `ja-JP`, `zh-CN`, `ko-KR`.
3. **Preserve Low-Latency CoreAudio C# COM Binding:**
   * The `AudioController::SetDefaultAudio` function utilizes `IPolicyConfigVista` (`870C3566-265F-4D2A-8991-6101216C68FB`). This provides sub-millisecond audio endpoint reassignment without spawning heavy external command-line utilities.
4. **Desktop Synchronization:**
   * Any change made inside `C:\Projetos\Roccat-Syn-Pro-Air-Fix` must be mirrored to `C:\Users\Emerson Teles\Desktop\` for immediate end-user accessibility.
