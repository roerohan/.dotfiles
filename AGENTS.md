# Agent Notes

## Voice

- Be concise, direct, and noticeably saucy; cayenne, not soup. Sharp quips and dry wit are welcome when they do not hide the answer.
- Use light sarcasm when deserved, but never let the bit outrank correctness, safety, or clarity.
- Keep technical claims boringly accurate. If you are guessing, say so; do not cosplay certainty.

## Repo Shape

- This is a personal dotfiles repo, not an app repo. Most root directories are active macOS or shared tool configs to symlink into `$HOME`.
- Linux-only desktop and system configuration lives under `linux/`; do not use it during a macOS setup.
- There is no root `package.json`; OpenCode dependencies belong under `opencode/`.

## High-Value Commands

- OpenCode deps live in `opencode/`: run `npm install` there if changing `opencode/package.json` or plugin dependencies.
- Sandbox OpenCode config sync lives at `sbx/opencode-config/sync.sh`; run it before `sbx run` when config changes need to be copied into the sandbox.
- The agent-first macOS runbook is `MACOS_SETUP.md`. Follow it instead of guessing from historical scripts or the stale root README.
- Neovim setup entrypoint is `nvim/setup`, which delegates to `nvim/AstroNvim/v6/setup`.

## OpenCode Config

- `opencode/opencode.json` is the user config source in this repo; sandbox copies are generated under `sbx/opencode-config/files/home/.config/opencode`.
- `sbx/opencode-config/spec.yaml` runs `npm install` in `/home/agent/.config/opencode` and installs `gh` in the sandbox.
- `sbx/opencode-config/sync.sh` rewrites sandbox `opencode.json` permissions to allow-all while preserving auth-file denies. Spicy, but intentional.
- Treat `sbx/opencode-config/files/home/.local/share/opencode/auth.json` and `mcp-auth.json` as secrets. Do not read, quote, commit, or “just peek” at them. Absolutely not, Sherlock.

## Neovim

- AstroNvim has historical `v2/`, `v3/`, and `v4/` directories; current config lives under `v6/`.
- Check AstroNvim upstream before future installs and use the latest stable major rather than trusting a directory name.
- `nvim/AstroNvim/v6/setup` backs up existing `~/.config/nvim`, clones the current template, and symlinks this repo's plugins. Ask before running it because it mutates the user's home config.

## Laptop Setup Preferences

- Ask which applications the laptop should have before installing anything. Offer all known apps selected by default, but call out work-specific apps such as Slack and allow deselection.
- Prefer Homebrew for installations and install latest stable releases unless explicitly pinned.
- Favor agent-executable written instructions over opaque setup scripts; scripts remain supported fallbacks.
- Preserve the aliases `vim=nvim`, `mux=tmuxinator`, and `oc=opencode` in future summaries and setups.
- Use SSH commit signing rather than GPG signing.

## Dotfile Safety

- Prefer editing repo files over mutating `$HOME`; install/setup snippets in README files often create symlinks or change shell config.
- Never symlink or overwrite `~/.zshenv`. `zsh/zshenv` is a secrets-free starter copy; the live file stays local and may contain secrets.
- Do not normalize all config files to one style. This repo intentionally mixes TOML, YAML, Lua, shell, and terminal/window-manager config formats.
- Existing contribution guidance says PRs target `dev` and commit messages use prefixes like `feat:`, `fix:`, `refactor:`, `docs:`, and `lint:`.
