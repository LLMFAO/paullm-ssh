# Building paullm-ssh

## Prerequisites

- Apple Silicon Mac (arm64)
- Xcode 16.0+
- Homebrew

Install build dependencies:

```bash
brew install zig cmake
```

## Vendor Dependencies

paullm-ssh uses vendored native libraries:

- **GhosttyKit** - Terminal rendering (from libghostty)
- **libssh2** - SSH transport
- **OpenSSL** - Cryptography

Build them with:

```bash
./scripts/build.sh all
```

Or individually:

```bash
./scripts/build.sh ghostty   # Build GhosttyKit only
./scripts/build.sh ssh       # Build libssh2 + OpenSSL only
./scripts/build.sh clean     # Clean vendor builds
./scripts/build.sh help      # Show all options
```

## Opening the Project

```bash
open paullm-ssh.xcodeproj
```

Then select your target (iOS Simulator or device) and build.

## Build Notes

- The iOS target requires a physical device for real SSH testing (simulator has networking limitations)
- Live Activity extension requires iOS 16.1+
- Voice input features require microphone permission

## Troubleshooting

### Missing vendor libraries

Run `./scripts/build.sh all` before building.

### Build errors related to StoreKit

The app runs in "Pro" mode by default (no paywall). If you see StoreKit errors, they can be safely ignored or the StoreManager can be compiled out for local builds.

### Swift Package resolution

Xcode should resolve packages automatically. If not, go to **File > Packages > Reset Package Caches**.