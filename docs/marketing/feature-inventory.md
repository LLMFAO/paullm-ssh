# Feature Inventory for Marketing

## Primary Product Pillars

### Terminal and Sessions

- Ghostty-powered terminal rendering.
- Standard SSH shells.
- Mosh sessions.
- Tailscale SSH.
- Cloudflare Access SSH.
- Multi-session tabs.
- Split panes.
- Persisted session state.
- Reconnect handling.
- tmux startup, attach, install, and recovery.
- Typed coding sessions for Claude, Codex, OpenCode, Antigravity, and generic tmux.
- Rich paste and clipboard helpers.
- iOS keyboard accessory with terminal keys and custom actions.
- iOS Live Activity connection status.

### AI and Vibe Coding

- SSH host setup script for preparing a Mac as an AI coding host.
- Recognizable agent session types.
- Startup commands sourced from editable custom actions.
- Multiple agent sessions on one host.
- Permission-bypass command variants where supported by the underlying tool.
- Works with existing CLI agents instead of replacing them.
- Useful for Mac mini, workstation, homelab, cloud VM, and GPU box workflows.

### Remote Files

- SFTP browser.
- Directory breadcrumbs.
- Sorting.
- Hidden-file toggle.
- Persisted browser state.
- Text preview.
- Image preview.
- Video preview.
- Upload.
- Download.
- Export/share.
- New folder.
- Rename.
- Move.
- Delete.
- Permission editing.
- Conflict resolution.

### Security

- Keychain password storage.
- Keychain SSH private key storage.
- SSH key passphrase storage.
- Cloudflare service token storage.
- Full-app lock.
- Per-server biometric unlock.
- Privacy mode.
- Known-host handling.
- Credentials remain separate from CloudKit metadata sync.

### Sync

- CloudKit sync for server metadata.
- CloudKit sync for workspaces.
- CloudKit sync for terminal theme preferences.
- CloudKit sync for terminal accessory profile data.
- Local fallback when iCloud is unavailable.
- Deduplication by stable record ID.

### Organization

- Workspaces.
- Workspace ordering.
- Workspace colors.
- Server environments.
- Custom environments for Pro users.
- Favorites.
- Tags.
- Notes.
- Last-connected timestamps.
- Local-network SSH discovery through Bonjour and subnet probing.

### Customization

- Built-in themes.
- Custom themes.
- Theme validation.
- Theme storage-path management.
- Sync-aware theme preferences.
- Customizable keyboard accessory bar.
- Reorderable actions.
- User-defined shortcuts.
- Terminal presets.
- Settings for general, terminal, sync, keychain, and about flows.

### Stats and Voice

- Remote CPU history.
- Remote memory history.
- Server stats presentation.
- On-device voice-to-command.
- MLX model management.
- Apple Speech fallback.

## Short Feature Claims

- Native SSH for iPhone, iPad, and Mac.
- SFTP files built into the terminal workflow.
- Agent sessions that stay recognizable after reconnects.
- Keychain-secured credentials.
- iCloud-synced server metadata.
- Ghostty-powered rendering.
- Mosh, Tailscale SSH, and Cloudflare Access support.
- tmux-aware session persistence.
- Designed for Apple-first remote developers.

## Claims to Avoid

- Do not imply paullm-ssh hosts or runs AI models itself.
- Do not imply credentials are synced as plain CloudKit records.
- Do not promise that voice input writes perfect production commands.
- Do not imply Mosh removes all connectivity failure modes.
- Do not imply all remote files are editable; use preview/edit language only where supported.
