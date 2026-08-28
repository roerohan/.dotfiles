# Agent-First macOS Setup

This is the preferred runbook for configuring a new Mac with this repository. It is written for an agent to execute end to end; the scripts remain useful fallbacks, not the primary source of truth.

## Owner Preferences

- Prefer Homebrew formulae and casks for software installation. Use another installer only when Homebrew has no suitable package, and say why.
- Install the latest stable release unless a version is explicitly pinned.
- Inspect existing files before replacing them. Preserve unrelated work and back up conflicting home-directory configs.
- Keep source-controlled configs in this repository and symlink them into `$HOME` where practical.
- Verify every installed command, linked path, and config with a non-interactive check.
- Use SSH keys, not GPG keys, for Git commit signing.
- Persistent convenience aliases to preserve in future setup summaries are `vim=nvim`, `mux=tmuxinator`, and `oc=opencode`.
- Never copy OpenCode or Cloudflare authentication files into this repository.

## Choose Apps First

Before installing anything, ask which applications belong on this laptop. Present the known app list as a multi-select question with every app selected by default, then let the owner deselect anything unwanted. Do not assume a new laptop is a work laptop merely because a previous one was.

The current known app list is:

- Core tools: Google Chrome, Ghostty, AeroSpace, Neovim, tmux, tmuxinator, OpenCode, ChatGPT, and T3 Code.
- Productivity: Raycast.
- Optional coding assistants: Claude Code, Codex CLI, and Cursor with Cursor Agent CLI. Cursor Agent is required by T3 Code when using Cursor as its agent.
- Optional Cloudflare tooling: Wrangler. Install it only after Node is active through `nvm`.
- Communication: WhatsApp and Slack. Explicitly describe Slack as a work app.
- Personal media: Spotify.

Install the selected applications only. Prefer Homebrew and skip healthy existing installations.

## Known Starting Point

The 2026 laptop bootstrap began with Homebrew, Google Chrome, Ghostty, OpenCode, and ChatGPT already installed. OpenCode was authenticated through Cloudflare AI Gateway. Authentication material is intentionally not documented or copied.

## Install Software

Confirm Apple Command Line Tools are available, then install the current packages:

```sh
xcode-select -p
brew tap nikitabobko/tap
brew trust --cask nikitabobko/tap/aerospace
brew install --cask nikitabobko/tap/aerospace
brew install neovim tmux tmuxinator nvm fzf direnv zsh-syntax-highlighting zsh-autosuggestions fd lazygit tree-sitter-cli bun codex
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask whatsapp slack spotify raycast claude-code cursor
```

Treat the commands above as the full-selection example, not permission to ignore the app-selection answer. Ghostty, Chrome, OpenCode, and ChatGPT can also be installed with Homebrew when absent. Do not reinstall applications that are already healthy merely to make the command list prettier.

When Cursor is selected, install its Agent CLI too. Homebrew does not package it, so use Cursor's official installer; it provides both `agent` and `cursor-agent` under `~/.local/bin`:

```sh
curl https://cursor.com/install -fsS | bash
cursor-agent --version
```

## Link Configs

Use absolute symlink targets based on the actual clone location:

```sh
DOTFILES="$HOME/Documents/Repos/dotfiles"
mkdir -p ~/.config/aerospace ~/.config/ghostty ~/.nvm
ln -s "$DOTFILES/aerospace/aerospace.toml" ~/.config/aerospace/aerospace.toml
ln -s "$DOTFILES/ghostty/config" ~/.config/ghostty/config
ln -s "$DOTFILES/tmux/tmux.conf" ~/.tmux.conf
ln -s "$DOTFILES/tmux/tmux.conf.local" ~/.tmux.conf.local
ln -s "$DOTFILES/gitconfig" ~/.gitconfig
ln -s "$DOTFILES/zsh/zshrc" ~/.zshrc
ln -s "$DOTFILES/zsh/zshenv" ~/.zshenv
```

If a destination exists, inspect it first. Back it up before replacement unless it is already the correct symlink.

## Shell And Node

The tracked `zsh/zshenv` adds `~/.local/bin`, sets Neovim as `EDITOR`, and defines the standard aliases. The tracked `zsh/zshrc` loads Homebrew's `nvm` and shell helpers.

```sh
mkdir -p ~/.nvm ~/.local/bin
export NVM_DIR="$HOME/.nvm"
. /opt/homebrew/opt/nvm/nvm.sh
nvm install --lts
nvm alias default 'lts/*'
corepack enable
```

When Wrangler is selected, install it under the `nvm`-managed default Node version:

```sh
nvm use default
npm install --global wrangler
wrangler --version
```

Oh My Zsh has no official Homebrew formula. Install it from its upstream Git repository only when `~/.oh-my-zsh` is absent.

## AstroNvim

Always check the [current AstroNvim release](https://github.com/AstroNvim/AstroNvim/releases) and [installation documentation](https://docs.astronvim.com/) before installing. As of 2026-08-28, AstroNvim v6 is current; v5 exists but is obsolete. The official template pins the current stable major.

```sh
git clone --depth 1 https://github.com/AstroNvim/template.git ~/.config/nvim
rm -rf ~/.config/nvim/lua/plugins
ln -s "$DOTFILES/nvim/AstroNvim/v6/plugins" ~/.config/nvim/lua/plugins
nvim --headless "+Lazy! sync" +qa
nvim --headless +qa
```

Back up an existing Neovim config and its state before a major migration. Do not infer the installed AstroNvim major from this repository's historical `v2`, `v3`, or `v4` directories; inspect `~/.config/nvim/lua/lazy_setup.lua`.

## Git Signing

Set Git's signing format to SSH, point `user.signingkey` at the public key, and generate `~/.ssh/allowed_signers` for local verification. Never read or copy the private key.

Register the same public key with GitHub as a signing key in addition to its authentication-key registration. Test with a disposable signed commit and require a `Good "git" signature` result.

## Reload And Verify

Reload Ghostty with `Cmd+Shift+,`; some visual settings require opening a new terminal surface, and background opacity requires a full restart on macOS. Do not terminate an agent's active terminal session just to demonstrate enthusiasm.

Verify at minimum:

```sh
zsh -n ~/.zshrc ~/.zshenv
zsh -lic 'node --version; npm --version; alias vim; alias mux; alias oc; print -r -- $EDITOR'
tmux -L dotfiles-check -f ~/.tmux.conf new-session -d
nvim --headless +qa
aerospace config --config-path
/Applications/Ghostty.app/Contents/MacOS/ghostty +show-config --default=false
git config --global --list --show-origin
```
