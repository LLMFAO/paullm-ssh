# Technical Site Content

These drafts are intended for website documentation pages. They are written for technical users evaluating how paullm-ssh works, what is stored where, and how it fits into remote development and AI coding workflows.

## Technical Overview

paullm-ssh is a native Apple-platform SSH terminal and SFTP client. The app targets iOS 16.1+ and macOS 13.3+ on arm64 hardware. It combines Ghostty terminal rendering, libssh2/OpenSSL SSH transport, CloudKit metadata sync, Keychain credential storage, StoreKit 2 entitlements, and feature-specific SwiftUI surfaces for terminal sessions, servers, remote files, settings, security, themes, stats, and voice input.

The app is organized with a feature-first architecture:

- `App` owns application entry points, composition roots, localization preferences, and iOS navigation shell.
- `Core` owns shared infrastructure such as logging, SSH transport, sync, security, terminal helpers, network state, and reusable UI primitives.
- `Features` owns product areas such as Servers, TerminalSessions, RemoteFiles, LocalDiscovery, TerminalThemes, TerminalAccessories, TerminalPresets, Stats, VoiceInput, Store, Security, Settings, Support, and Welcome.
- `GhosttyTerminal` bridges libghostty terminal emulation into Apple platform views.

Feature code is split into `Domain`, `Application`, `Infrastructure`, and `UI` layers where applicable.

## Terminal Architecture

paullm-ssh uses Ghostty terminal technology through `GhosttyKit` for terminal emulation and rendering. Terminal sessions are driven by SSH-backed shell startup and connected to platform-native SwiftUI/AppKit/UIKit presentation.

Terminal capabilities include:

- GPU-accelerated terminal rendering.
- Keyboard, mouse, scroll, and IME input forwarding.
- Multiple terminal sessions with tabs and split panes.
- Persisted session state and reconnect handling.
- tmux-aware startup, attach, install, and recovery flows.
- Rich paste and clipboard helpers.
- iOS keyboard accessory actions for terminal-specific keys and shortcuts.
- iOS Live Activity updates for active connections.

The terminal surface should remain visually stable and readable. Glass, blur, or decorative effects should be applied to navigation and toolbar surfaces only, not to terminal content.

## Connection Methods

paullm-ssh supports multiple connection paths so users can reach machines in different network environments:

- Standard SSH for direct host access.
- Mosh for more resilient sessions across intermittent networks.
- Tailscale SSH for tailnet-protected machines.
- Cloudflare Access for protected hosts behind Cloudflare.

Authentication support includes:

- Password authentication.
- SSH private key authentication.
- SSH key plus passphrase.
- Tailscale SSH policy where no local password or key is required.
- Cloudflare service tokens for supported Cloudflare workflows.

Low-level SSH behavior belongs in `Core/SSH`. Feature policy, screen state, and product-specific workflows should live in the relevant feature module.

## AI Coding and Remote Agent Workflows

paullm-ssh is designed to support AI-assisted coding without requiring a proprietary compute backend. Users can run their coding tools on a Mac mini, workstation, homelab machine, or cloud VM, then connect from any Apple device.

The app supports typed coding sessions for:

- Claude CLI.
- Codex CLI.
- OpenCode CLI.
- Antigravity CLI.
- Generic tmux sessions.

Typed sessions let users identify multiple live sessions on the same host. Startup commands are sourced from editable custom actions, then snapshotted onto a session so existing sessions remain stable if a command changes later.

Recommended website page structure:

1. Prepare a Mac or server for SSH access.
2. Add the host to paullm-ssh.
3. Enable tmux for persistent sessions.
4. Choose a typed coding session when starting a terminal.
5. Reconnect later from iPhone, iPad, or Mac.

The repository also includes `scripts/setup-ssh-host.sh`, which can configure a Mac as an SSH host for AI coding tools. The script can enable Remote Login, harden SSH configuration, configure the firewall, generate an Ed25519 key pair, and create SSH config snippets.

## Remote Files and SFTP

paullm-ssh includes an SFTP-backed remote file browser. The feature belongs to `Features/RemoteFiles` and should keep non-view logic out of `UI`.

Remote file capabilities include:

- Directory browsing with breadcrumbs.
- Sorting and hidden-file toggles.
- Persisted browser state.
- Text, image, and video previews.
- Upload, download, export, and share flows.
- New folder, rename, move, and delete operations.
- POSIX permission editing on supported servers.
- Conflict handling for file operations.

The site should position remote files as a companion to terminal work: quick inspection, transfer, and editing without switching to a separate SFTP app.

## Sync and Security

paullm-ssh separates metadata sync from credential storage.

Synced through CloudKit:

- Workspaces.
- Server metadata.
- Terminal theme preferences.
- Terminal accessory profile data.

Stored in Keychain:

- Passwords.
- SSH private keys.
- SSH key passphrases.
- Cloudflare service tokens.

Important user-facing rule:

Credentials are not synced as raw CloudKit records. Users should understand that server metadata syncs across devices while secrets remain under Keychain protection.

Security features include:

- Full-app lock.
- Per-server biometric unlock.
- Privacy mode.
- Keychain-backed credential storage.
- Known-host and SSH bootstrap helpers.

## Server Organization

Servers are organized into workspaces and environments. The app supports favorites, tags, notes, ordering, workspace colors, last-connected timestamps, and local discovery.

Core concepts for docs:

- A workspace groups related infrastructure.
- An environment labels server purpose, such as production, staging, development, or custom environments.
- Server metadata syncs through iCloud so the list stays available across Apple devices.
- Per-server settings can control authentication, connection mode, tmux behavior, and biometric requirements.

## Customization

paullm-ssh includes customization surfaces for terminal-heavy workflows:

- Built-in terminal themes.
- Custom terminal themes with validation and storage-path management.
- Sync-aware theme preferences.
- Customizable keyboard accessory bar.
- User-defined terminal shortcuts and actions.
- Terminal presets for saved commands or snippets.
- Settings for general behavior, terminal behavior, sync, keychain, transcription, and about/support flows.

## Voice-to-Command

Voice input lets users dictate terminal commands. The app uses on-device MLX model management where available and Apple Speech fallback when needed.

Website copy should avoid promising perfect command generation. Position the feature as a productivity aid for command entry and hands-limited situations.

## Pro Entitlements

Free tier:

- 1 workspace.
- 3 servers.
- 1 connection tab.

Pro tier:

- Unlimited workspaces.
- Unlimited servers.
- Unlimited connection tabs.
- Custom environments.
- Priority support.
- Future features.

Entitlement enforcement lives in:

- `ServerManager.canAddWorkspace`.
- `ServerManager.canAddServer`.
- `ConnectionSessionManager.canOpenNewTab`.

Products:

- Monthly Pro: $6.49.
- Yearly Pro: $24.99.
- Lifetime Pro: $49.99.

## Developer Build Notes

End users do not need to build native vendor libraries. Developers building from source need:

- Apple Silicon Mac.
- Xcode 16.0+.
- macOS 13.3+.
- iOS 16.1+ target support.
- Zig and CMake when rebuilding native vendor libraries.

Vendored native dependencies:

- `Vendor/libghostty/GhosttyKit.xcframework`.
- `Vendor/libssh2/{macos,ios,ios-simulator}/`.

Build commands:

```bash
./scripts/build.sh all
./scripts/build.sh ghostty
./scripts/build.sh ssh
```

Open the Xcode project with:

```bash
open paullm-ssh.xcodeproj
```
