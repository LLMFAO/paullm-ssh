# Privacy Policy — paullm-ssh

**Last updated: 2026-08-22**

> The canonical version of this policy is published at
> https://paullm.com/privacy/paullm-ssh

paullm-ssh is an SSH, SFTP, and terminal client. It connects your device directly
to servers that *you* control. The developer operates no backend, no account
system, and no analytics service, and receives no data from the app.

## What the developer collects

**Nothing.** There is no telemetry, no crash reporting SDK, no advertising
identifier, and no third-party analytics in the app. The app's privacy manifest
declares no collected data types and no tracking.

## Where your data lives

**SSH credentials (passwords, private keys, passphrases)** are stored in the
system Keychain on your device. If you have iCloud Keychain enabled, Apple may
sync them across your devices under your Apple Account. They are never
transmitted to the developer.

**Server and workspace metadata** (host names, usernames, ports, connection
settings, terminal themes, saved session types) syncs through **CloudKit** into
*your own private iCloud database*. This is Apple infrastructure tied to your
Apple Account. The developer cannot read it.

**App preferences** are stored locally in UserDefaults.

## Network connections the app makes

- **To your servers.** SSH and SFTP traffic goes directly from your device to the
  hosts you configure. There is no relay or intermediary operated by the
  developer. If you enable Cloudflare Access or Tailscale modes, traffic is
  routed per your own configuration with those providers.
- **To Apple**, for iCloud/CloudKit sync and speech recognition (below).
- **To Hugging Face** (`huggingface.co`), *only if* you choose to download an
  optional on-device Whisper transcription model.

## Voice input

Voice input is optional and off until you grant permission.

**Microphone audio is sent to Apple's speech recognition service for
transcription.** The app currently uses Apple's `SFSpeechRecognizer` with
on-device recognition *not* required, which means audio may leave your device and
be processed on Apple's servers under Apple's privacy policy.

Alternatively you may download an MLX Whisper model, which performs transcription
entirely on device. The model file itself is downloaded from Hugging Face.

## Local network

The app requests Local Network permission solely to discover SSH hosts on your
network. Discovery results stay on your device.

## Terminal content

Terminal output, command history, and files you browse over SFTP are handled
locally on your device and on the servers you connect to. They are not collected
or transmitted to the developer.

## Deleting your data

Note that **uninstalling the app does not automatically erase everything**:

- **Keychain credentials** may persist in your Keychain (and in iCloud Keychain
  if enabled). Remove them in iOS Settings, or delete the servers inside the app
  before uninstalling.
- **CloudKit data** persists in your private iCloud database. Delete it via
  iOS Settings → your name → iCloud → Manage Account Storage, or by removing
  servers and workspaces in the app before uninstalling.

## Children

The app is not directed at children and collects no personal information.

## Third-party software

The app bundles open-source components including libssh2, OpenSSL, libghostty,
MLX Swift, and others. See `THIRD_PARTY_NOTICES.md`. These components do not
transmit your data to the developer.

## Licensing

paullm-ssh is distributed under GPL-3.0. It is a modified version of VVTerm,
© Vivy Technologies Co., Limited. Source code is available at
https://github.com/LLMFAO/paullm-ssh

## Contact

Questions about this policy: me@pauljpettit.com
