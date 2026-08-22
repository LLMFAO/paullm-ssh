# Contributing to paullm-ssh

Thanks for your interest in contributing to paullm-ssh.

## Code of Conduct

By participating in this project, you agree to follow `CODE_OF_CONDUCT.md`.

## Before You Start

1. Search existing issues and pull requests to avoid duplicate work.
2. For large changes, open an issue first to align on approach and scope.
3. Keep pull requests focused and small when possible.

## Development Setup

Requirements:

- Xcode 16.0+
- Zig (for building Ghostty): `brew install zig`

Setup:

```bash
git clone https://github.com/LLMFAO/paullm-ssh.git
cd paullm-ssh
./scripts/build.sh all
open paullm-ssh.xcodeproj
```

## Pull Request Guidelines

1. Create a branch from `main`.
2. Make your changes with clear commit messages.
3. Run relevant checks/tests locally before opening a PR.
4. Include screenshots or recordings for UI changes.
5. Include clear validation notes for networking/terminal behavior changes.

## License

This project is licensed under GPL-3.0 (`LICENSE`). By submitting contributions,
you agree that your contributions are licensed under GPL-3.0 as well.

There is no Contributor License Agreement. The upstream project this fork is
based on used a CLA to assign rights to its owner so it could dual-license its
own binaries; that arrangement does not apply here and this fork does not
collect rights assignments.
