# AI Coding Host Setup

This guide helps prepare a Mac as an SSH host for typed coding sessions from paullm-ssh, including Antigravity CLI, Claude CLI, Codex CLI, OpenCode CLI, and generic tmux sessions.

## Quick Start

Run the host setup helper on the Mac you want to connect to:

```bash
./scripts/setup-ssh-host.sh
```

The script enables Remote Login, hardens SSH defaults, configures the firewall, creates an Ed25519 key for app access, and prints connection details.

For unattended setup:

```bash
./scripts/setup-ssh-host.sh --auto
```

If you use Tailscale, add the Mac in paullm-ssh with its MagicDNS hostname, the macOS username, and the generated SSH private key.

## Recommended Host Checks

On the Mac host, verify SSH and tmux before testing from iPhone:

```bash
ssh localhost 'printf "ssh ok\n"'
command -v tmux || brew install tmux
tmux -V
```

For AI CLI sessions, make sure the CLI is available from an interactive shell:

```bash
command -v agy
command -v claude
command -v codex
command -v opencode
```

If a CLI is installed through Homebrew, npm, a version manager, or a vendor installer, put the PATH setup in the shell file that your normal interactive shell reads, usually `~/.zshrc` for zsh or `~/.bashrc` for bash.

## macOS tmux and Login Shells

macOS terminal apps commonly start login shells. Linux terminal emulators more often start non-login interactive shells. That difference matters when tmux launches panes.

If tmux starts a login shell on macOS, it may read files such as `~/.zprofile`, `~/.zlogin`, or `~/.bash_profile` instead of the interactive setup in `~/.zshrc` or `~/.bashrc`. The result is that commands like `agy` can work in Terminal.app but be missing inside a tmux-backed session launched over SSH.

paullm-ssh works around this by:

- importing a safe whitelist of login-shell environment values before starting tmux
- refreshing tmux global environment values such as `HOME`, `SHELL`, `PATH`, and XDG config directories
- setting tmux `default-shell` to the user's shell
- setting tmux `default-command` to a non-login interactive shell command
- launching typed CLI sessions through an interactive non-login shell so `.zshrc` and `.bashrc` setup is visible

## Symptom: Failed to Request Shell

If you tap a host, choose **New Terminal**, select **Antigravity CLI**, tap **Start**, see **Reconnecting**, and then get:

```text
SSH error: Failed to request shell
```

the SSH key and hostname may still be correct. In this app, that error can happen when the server accepts the SSH login but rejects the shell, PTY, or startup command request used to launch the typed session.

Try these steps:

1. Build or install the latest app version with the tmux shell-startup fix.
2. On the Mac host, run `tmux kill-server` once to clear any old tmux server that still has stale login-shell defaults.
3. Confirm the CLI is visible from an interactive shell: `command -v agy`.
4. Confirm the app server entry uses the expected username, MagicDNS hostname, and SSH private key.
5. Start a plain tmux session from paullm-ssh. If that works, try the typed Antigravity CLI session again.

## When to Install tmux

The app should still detect tmux at runtime and offer to install it when missing. That keeps fresh hosts usable even when they were not prepared with the setup script.

The host setup script can also install tmux as a convenience, especially on Macs intended for AI coding sessions. Treat that as preflight setup, not the source of truth. The app must still own runtime detection, environment refresh, recovery, and attach behavior.

## Manual tmux Recovery

If tmux behavior looks stale after changing shell files or updating the app:

```bash
tmux kill-server
```

Then reconnect from paullm-ssh. Existing long-running tmux sessions will stop when you kill the server, so use this only when you are not trying to preserve active work.

To inspect tmux's current shell settings:

```bash
tmux show-options -g default-shell
tmux show-options -g default-command
```

For paullm-ssh-managed sessions, the app writes its own tmux config under:

```text
~/.paullm/tmux.conf
```

Avoid putting app-specific tmux fixes into your personal `~/.tmux.conf` unless you want them to affect all tmux usage on the Mac.
