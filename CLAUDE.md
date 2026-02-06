# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is Bolt

Bolt is a macOS menu bar app for battery charge management. It controls MacBook charging behavior via SMC (System Management Controller) keys, allowing users to limit max battery charge to extend battery longevity. Requires macOS 14.0+. Built upon [BatFi](https://github.com/rurza/BatFi).

## Build Commands

```bash
# Build the main app
xcodebuild -project Bolt.xcodeproj -scheme Bolt -configuration Debug build

# Build the privileged helper
xcodebuild -project Bolt.xcodeproj -scheme Helper -configuration Debug build
```

Open `Bolt.xcodeproj` in Xcode for full development (code signing, running on device, etc).

## Architecture

### Two-Target Structure

The project has two Xcode targets that work together:

1. **Bolt** (app target) — SwiftUI menu bar app (`BoltApp.swift`). Renders in the menu bar using `MenuBarExtra` with `.window` style. No main window.
2. **Helper** (command-line tool) — Privileged helper daemon that performs SMC read/write operations requiring root access. Registered via `SMAppService.daemon()`.

### IPC: Main App ↔ Helper

- The app communicates with the Helper via **NSXPCConnection** (Mach service: `com.aayush.opensource.Bolt.Helper.mach`)
- The XPC interface is defined in `Shared/HelperProtocol.swift` (`HelperToolProtocol`) — shared between both targets
- Additionally, both targets set up an **XPCSession** on `xpc.aayush.opensource.bolt` (newer XPC API)
- `ServiceManager` (singleton) is the app-side XPC client that wraps all helper calls

### SMC Layer (Helper/SMC/)

- `SMC.swift` — SMCKit library (MIT, from beltex). Low-level IOKit calls to AppleSMC.kext driver. Handles `SMCParamStruct` (must be exactly 80 bytes)
- `SMC+Keys.swift` — Defines charging-related SMC keys: `CH0I`, `CH0C`, `CH0B` (inhibit charging), `MSLD` (lid closed)
- `SMC+Temperature.swift` — Temperature sensor readings via SMC

### Key SMC Keys

| Key    | Purpose                        |
|--------|--------------------------------|
| `BCLM` | Battery Charge Level Max       |
| `CH0B` | Inhibit/enable charging        |
| `BRSC` | Battery remaining state charge |

### App Layer

- **BoltViewModel** (`@Observable`) — Polls battery status every 10s via `IOPSCopyPowerSourcesInfo`, manages XPC session reconnection every 30s, tracks `bclmValue`
- **BatteryInfo** — Model parsed from IOKit power source dictionary
- **MenuView** — Uses `MacControlCenterUI` (local package in `Packages/`) to render a Control Center-style popup with a charge limit slider and battery info

### Shared Code (`Shared/`)

Code shared between both targets:
- `HelperProtocol.swift` — XPC protocol + `helperVersion` constant
- `Logger+Extension.swift` — Convenience `Logger(category:)` initializer

### Local Package

`Packages/MacControlCenterUI` — Vendored fork of [orchetect/MacControlCenterUI](https://github.com/orchetect/MacControlCenterUI). Provides macOS Control Center-style UI components (`MacControlCenterMenu`, `MenuSlider`, `MenuSection`, `MenuCommand`). Depends on `MenuBarExtraAccess`.
