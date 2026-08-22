# paullm-ssh

[![macOS](https://img.shields.io/badge/macOS-13.3+-black?style=flat-square&logo=apple)](https://www.apple.com)
[![iOS](https://img.shields.io/badge/iOS-16.1+-black?style=flat-square&logo=apple)](https://www.apple.com)
[![Swift](https://img.shields.io/badge/Swift-5.0+-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![Source License](https://img.shields.io/badge/Source-GPL%203.0-blue?style=flat-square)](LICENSE)

Open-source SSH terminal for iPhone and Mac.

![paullm-ssh](/web/src/preview.png)

## Overview

paullm-ssh is a cross-platform SSH terminal app for Apple platforms. The current codebase targets iOS and macOS, uses Ghostty for terminal rendering, libssh2/OpenSSL for SSH transport, CloudKit for sync, and Keychain for local credential storage.

## Getting Started

### Use This Mac as an SSH Host for AI Coding Tools

If you want to use this Mac as a remote development machine for Claude, OpenCode, Codex, Cursor, or any other AI tool that connects over SSH, run the host setup script. No app build required.

```bash
./scripts/setup-ssh-host.sh
```

This interactive script will:

1. Enable Remote Login (SSH)
2. Harden SSH configuration (key-based auth only, no root login, keepalive)
3. Configure the macOS firewall
4. Generate an Ed25519 SSH key pair for AI tool access
5. Set up SSH config snippets with connection details

For hands-off setup with defaults:

```bash
./scripts/setup-ssh-host.sh --auto
```

Other common options:

```bash
# Create a dedicated user for AI tools
./scripts/setup-ssh-host.sh --with-ai-user

# Use a custom SSH port
./scripts/setup-ssh-host.sh --auto --port 2222

# Preview what would change without applying
./scripts/setup-ssh-host.sh --dry-run
```

See `./scripts/setup-ssh-host.sh --help` for all options. For tmux, Tailscale MagicDNS, and AI CLI troubleshooting, see [`docs/AI_CODING_HOST_SETUP.md`](docs/AI_CODING_HOST_SETUP.md).

---

### Install the App

paullm-ssh is available on the App Store for iPhone and Mac.

If you want to build it yourself, see the **Developer Setup** section below.

## Current State

- Main app target: `paullm-ssh`
- Companion target: `paullm-sshLiveActivity`
- Runtime targets: `macOS 13.3+` and `iOS 16.1+`
- Hardware targets: Apple Silicon / arm64 only
- App-owned code is organized under `paullm-ssh/App`, `paullm-ssh/Core`, and `paullm-ssh/Features`
- The repo also contains tests, native vendor builds, feature specs under `docs/specs`, and the marketing site under `web/`

## Implemented Feature Areas

### Terminal and connections

- GPU-accelerated terminal rendering via `GhosttyKit`
- SSH authentication with password, SSH key, and SSH key + passphrase
- Connection modes for standard SSH, Mosh, and Cloudflare Access
- Multi-session connection management with tabs, split panes, reconnect handling, and persisted session state
- tmux-aware startup, attach, install, and recovery flows
- Rich paste and clipboard helpers for terminal input
- iOS keyboard accessory support, including special keys and custom actions
- iOS Live Activity status for active terminal connections

### Servers and organization

- Workspaces with ordering, colors, and environment grouping
- Server metadata including favorites, tags, notes, last-connected timestamps, and biometric-unlock requirements
- Local-network SSH discovery via Bonjour and subnet probing

### Remote files

- SFTP-backed remote file browser for iOS and macOS
- Directory browsing with breadcrumbs, sorting, hidden-file toggles, and persisted browser state
- File preview, upload, download, export/share, new folder, rename, move, and delete flows
- Permission editing and remote-file conflict resolution

### Security and sync

- Keychain-backed storage for SSH credentials and Cloudflare service tokens
- CloudKit sync for servers, workspaces, terminal theme preferences, and terminal accessory profile data
- Full-app lock and per-server biometric unlock
- Privacy-mode support

### Customization and productivity

- Built-in and custom terminal themes with validation, storage-path management, and sync-aware preference handling
- Customizable terminal accessory bar with reorderable actions and user-defined shortcuts
- Terminal presets for saved commands/snippets
- Settings surfaces for general, terminal, sync, keychain, and about flows
- Welcome/onboarding and in-app support surfaces

### Stats and voice input

- Remote server stats collection with live CPU and memory history
- On-device voice-to-command pipeline with MLX model management and Apple Speech fallback

## Developer Setup

> The following is only needed if you want to build the app from source. End users can skip this.

### Requirements

- Apple Silicon Mac (arm64)
- Xcode `16.0+`
- macOS `13.3+`
- iOS `16.1+`
- `zig` and `cmake`

Install the non-Xcode build tools with Homebrew:

```bash
brew install zig cmake
```

### Building From Source

```bash
git clone https://github.com/paullm/paullm-ssh.git
cd paullm-ssh

# Build native vendor libraries (GhosttyKit + libssh2/OpenSSL)
./scripts/build.sh all

# Open the project in Xcode
open paullm-ssh.xcodeproj
```

`./scripts/build.sh` supports `all`, `ghostty`, `ssh`, `clean`, and `help`.

### Architecture

paullm-ssh uses a feature-first structure for app-owned code.

```text
paullm-ssh/
├── App/                         # App entry, composition roots, shared root containers
├── Core/                        # Shared infrastructure and cross-feature primitives
│   ├── Logging/
│   ├── Network/
│   ├── Security/
│   ├── SSH/
│   ├── Sync/
│   ├── Terminal/
│   └── UI/
├── Features/                    # Product features
│   ├── ConnectionViews/
│   ├── LocalDiscovery/
│   ├── RemoteFiles/
│   ├── Security/
│   ├── Servers/
│   ├── Settings/
│   ├── Stats/
│   ├── Store/
│   ├── Support/
│   ├── TerminalAccessories/
│   ├── TerminalPresets/
│   ├── TerminalSessions/
│   ├── TerminalThemes/
│   ├── VoiceInput/
│   └── Welcome/
├── GhosttyTerminal/             # Ghostty bridge and terminal host views
├── Compatibility/               # Version/platform helpers
├── Generated/                   # Build-time generated sources
└── Resources/                  # Bundled assets, themes, terminfo, localizations
```

Feature modules follow these boundaries:

- `Domain`: pure types and rules
- `Application`: state, orchestration, coordinators, managers
- `Infrastructure`: persistence, transport, adapters, external integrations
- `UI`: SwiftUI/AppKit/UIKit presentation

Other top-level folders in the repo:

```text
paullm-ssh-iOS/                     # iOS Info.plist and entitlements
paullm-ssh-macOS/                   # macOS Info.plist and entitlements
paullm-sshLiveActivity/             # ActivityKit target
paullm-sshShared/                   # Shared Activity attributes and small shared types
paullm-sshTests/                    # Unit and integration tests
paullm-sshUITests/                  # UI tests
Vendor/                             # Vendored native dependencies
docs/                               # Documentation (BUILDING.md, feature specs)
scripts/                            # Build scripts and SSH host setup
  build.sh                          # Native vendor library builds
  setup-ssh-host.sh                 # Configure macOS as SSH dev host for AI tools
web/                                # Marketing site
```

## Dependencies

Native/vendor dependencies:

- [libghostty](https://github.com/ghostty-org/ghostty) for terminal emulation and rendering
- [libssh2](https://github.com/libssh2/libssh2) for SSH transport
- [OpenSSL](https://github.com/openssl/openssl) for cryptography

Swift package dependencies currently resolved by the Xcode project:

- [Cloudflared](https://github.com/wiedymi/swift-cloudflared)
- [swift-mosh](https://github.com/wiedymi/swift-mosh)
- [mlx-swift](https://github.com/ml-explore/mlx-swift)
- [ZIPFoundation](https://github.com/weichsel/ZIPFoundation)
- [swift-numerics](https://github.com/apple/swift-numerics)
- [TweetNacl](https://github.com/bitmark-inc/tweetnacl-swiftwrap.git)

## Documentation

- [CONTRIBUTING.md](CONTRIBUTING.md) for contribution workflow
- [SECURITY.md](SECURITY.md) for vulnerability reporting
- [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for third-party notices
- [CLA.md](CLA.md) for the contributor license agreement
- [docs/marketing/](docs/marketing/) for website copy, technical site content, and feature messaging
- `docs/specs/` for feature specs such as biometric locks, local discovery, terminal themes, terminal accessories, remote rich clipboard, and the SFTP browser

## License

paullm-ssh is licensed under GNU GPL v3.0 (`LICENSE`).

Copyright © 2025 paullm
