# Building paullm-ssh

## SSH Host Setup

If you want to use this Mac as a remote development host for AI coding tools (Claude, OpenCode, Codex, etc.), run:

```bash
./scripts/setup-ssh-host.sh
```

This interactive script will:

1. Enable Remote Login (SSH)
2. Harden SSH configuration (key-based auth, no root login, keepalive)
3. Configure the macOS firewall
4. Generate an Ed25519 SSH key pair for AI tool access
5. Set up SSH config snippets

For non-interactive setup with defaults:

```bash
./scripts/setup-ssh-host.sh --auto
```

Other options:

```bash
# Create a dedicated 'developer' user for AI tools
./scripts/setup-ssh-host.sh --with-ai-user

# Use a custom port
./scripts/setup-ssh-host.sh --auto --port 2222

# Preview changes without applying
./scripts/setup-ssh-host.sh --dry-run
```

See `./scripts/setup-ssh-host.sh --help` for all options. For a setup and troubleshooting guide covering Tailscale MagicDNS, tmux, and typed AI CLI sessions, see [`AI_CODING_HOST_SETUP.md`](AI_CODING_HOST_SETUP.md).

For website-facing copy and technical documentation about AI coding workflows, see `docs/marketing/technical-content.md`.

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
