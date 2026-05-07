# Agent Notes

## Voice

- Be concise, direct, and noticeably saucy; cayenne, not soup. Sharp quips and dry wit are welcome when they do not hide the answer.
- Use light sarcasm when deserved, but never let the bit outrank correctness, safety, or clarity.
- Keep technical claims boringly accurate. If you are guessing, say so; do not cosplay certainty.

## Repo Shape

- This is a personal dotfiles repo, not an app repo. Most directories are tool configs to copy or symlink into `$HOME`.
- The root `README.md` still has template/boilerplate npm setup text; there is no root `package.json`, so do not run `npm install` at repo root just because the README says so.
- macOS-specific configs are real here (`aerospace/`, `ghostty/`, `jj/`), despite the root README saying Linux.

## High-Value Commands

- OpenCode deps live in `opencode/`: run `npm install` there if changing `opencode/package.json` or plugin dependencies.
- Sandbox OpenCode config sync lives at `sbx/opencode-config/sync.sh`; run it before `sbx run` when config changes need to be copied into the sandbox.
- Neovim setup entrypoint is `nvim/setup`, which delegates to `nvim/AstroNvim/v4/setup`.

## OpenCode Config

- `opencode/opencode.json` is the user config source in this repo; sandbox copies are generated under `sbx/opencode-config/files/home/.config/opencode`.
- `sbx/opencode-config/spec.yaml` runs `npm install` in `/home/agent/.config/opencode` and installs `gh` in the sandbox.
- `sbx/opencode-config/sync.sh` rewrites sandbox `opencode.json` permissions to allow-all while preserving auth-file denies. Spicy, but intentional.
- Treat `sbx/opencode-config/files/home/.local/share/opencode/auth.json` and `mcp-auth.json` as secrets. Do not read, quote, commit, or “just peek” at them. Absolutely not, Sherlock.

## Neovim

- AstroNvim has historical `v2/`, `v3/`, and current `v4/` directories; `nvim/setup` uses `v4`.
- Many `nvim/AstroNvim/v4/plugins/*.lua` files are disabled templates when they start with `if true then return {} end`; do not assume those settings are active.
- `nvim/AstroNvim/v4/setup` moves existing `~/.config/nvim` to a random backup name, clones AstroNvim template, then symlinks this repo's `plugins` directory. Ask before running it; it mutates the user's home config.

## Dotfile Safety

- Prefer editing repo files over mutating `$HOME`; install/setup snippets in README files often create symlinks or change shell config.
- Do not normalize all config files to one style. This repo intentionally mixes TOML, YAML, Lua, shell, and terminal/window-manager config formats.
- Existing contribution guidance says PRs target `dev` and commit messages use prefixes like `feat:`, `fix:`, `refactor:`, `docs:`, and `lint:`.
