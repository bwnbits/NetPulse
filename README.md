# ⚡ NetPulse

A lightweight, native macOS menu-bar app that shows your real-time network speed — no fake numbers, no bloat, no data drain.

**by [bwnbits](https://github.com/bwnbits)**

---

## Features

- 📊 **Live speed** in the menu bar — download & upload, updated every second
- 📈 **Session totals** — cumulative data used, persisted across restarts
- 🌐 **Interface detection** — automatically shows Wi-Fi / Ethernet / VPN
- 🚀 **Built-in speed test** — real download/upload/ping test using parallel streams
- 🕶️ **Menu-bar only mode** — hide the Dock icon entirely, live purely in your menu bar
- 🔓 **Launch at Login** — starts automatically, no manual relaunching
- 🪶 **Minimal footprint** — reads system network stats directly (`getifaddrs`), no polling hacks, no fake randomized data

## Screenshots

<!-- Add 1–2 screenshots of the menu bar popover + main window here -->

## Installation

### Option 1: Download the DMG (recommended)
1. Grab the latest `.dmg` from the [Releases page](../../releases)
2. Open it, drag **NetPulse** into your **Applications** folder
3. Launch NetPulse from Applications (first launch: right-click → Open if you see a Gatekeeper prompt, until notarization is fully live)

### Option 2: Build from source
```bash
git clone https://github.com/bwnbits/netpulse.git
cd netpulse
open NetPulse.xcodeproj
```
Build and run in Xcode (⌘R). Requires macOS 13+ and Xcode 15+.

## Usage

- Click the menu bar icon to see live speed, session totals, and run a speed test
- Toggle **Monitor** to pause/resume tracking
- Toggle **Show in Dock** if you'd rather have a normal Dock-based app
- **Reset Totals** clears your cumulative session data

## Privacy

NetPulse reads network interface byte counters directly from macOS (`getifaddrs`) — it does not inspect your traffic, browsing history, or send any data anywhere except during an explicit, user-initiated speed test (which uses public speed-test endpoints to measure throughput).

## Requirements

- macOS 13.0 or later
- Apple Silicon or Intel

## Contributing

Issues and pull requests are welcome. Please open an issue first for larger changes so we can discuss the approach.

## License

<!-- Pick one: MIT is the simplest for a small open-source utility -->
MIT License — see [LICENSE](LICENSE) for details.

## Credits

Made with ❤️ in India by [bwnbits](https://github.com/bwnbits)
