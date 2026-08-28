# Agent-First macOS Setup

This is the preferred runbook for configuring a new Mac with this repository. It is written for an agent to execute end to end; the scripts remain useful fallbacks, not the primary source of truth.

## Clone The Repository

Use this exact location so config links are consistent across Macs:

```sh
mkdir -p "$HOME/Documents/Repos"
git clone git@github.com:roerohan/.dotfiles.git "$HOME/Documents/Repos/dotfiles"
cd "$HOME/Documents/Repos/dotfiles"
```

If SSH authentication is not ready, clone over HTTPS and keep the same destination path. Do not create a second clone elsewhere once SSH is configured.

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

## Install Software

Assume Homebrew is the only installed setup tool. Confirm Apple Command Line Tools are available, then install every selected command and application rather than assuming anything else exists:

```sh
xcode-select -p
brew tap nikitabobko/tap
brew trust --cask nikitabobko/tap/aerospace
brew install --cask nikitabobko/tap/aerospace
brew install neovim tmux tmuxinator nvm fzf direnv zsh-syntax-highlighting zsh-autosuggestions fd lazygit tree-sitter-cli bun gh jj anomalyco/tap/opencode
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask ghostty google-chrome chatgpt t3-code whatsapp slack spotify raycast claude-code codex cursor
```

Treat the commands above as the full-selection example, not permission to ignore the app-selection answer. Do not reinstall applications that are already healthy merely to make the command list prettier.

When Cursor is selected, install its Agent CLI too. Homebrew does not package it, so use Cursor's official installer; it provides both `agent` and `cursor-agent` under `~/.local/bin`:

```sh
curl https://cursor.com/install -fsS | bash
cursor-agent --version
```

## Link Configs

Repository-managed configs must be symlinked, not copied. Use absolute targets from the canonical clone location:

```sh
DOTFILES="$HOME/Documents/Repos/dotfiles"
mkdir -p ~/.config ~/.nvm
ln -s "$DOTFILES/aerospace" ~/.config/aerospace
ln -s "$DOTFILES/ghostty" ~/.config/ghostty
ln -s "$DOTFILES/jj" ~/.config/jj
ln -s "$DOTFILES/opencode" ~/.config/opencode
ln -s "$DOTFILES/tmux/tmux.conf" ~/.tmux.conf
ln -s "$DOTFILES/tmux/tmux.conf.local" ~/.tmux.conf.local
ln -s "$DOTFILES/gitconfig" ~/.gitconfig
ln -s "$DOTFILES/zsh/zshrc" ~/.zshrc
```

If `~/.zshenv` does not exist, copy the tracked safe baseline once and keep the live file local because it may later contain secrets:

```sh
if [ ! -e "$HOME/.zshenv" ]; then
  cp "$DOTFILES/zsh/zshenv" "$HOME/.zshenv"
  chmod 600 "$HOME/.zshenv"
fi
```

If another destination exists, inspect it first. When it is a copied version of the tracked config, back it up or remove it only after confirming the repository version is correct, then replace it with `ln -s`. Leave `~/.zshenv`, authentication, caches, generated files, and `node_modules` local. Never copy secrets from the live `~/.zshenv` back into the repository baseline.

## Authenticate OpenCode

Authenticate the new OpenCode installation through Cloudflare AI Gateway using the interactive provider flow. Keep generated credentials local and untracked:

```sh
opencode auth login
opencode auth list
```

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

Authenticate GitHub CLI separately and retain SSH as its Git transport:

```sh
gh auth login --hostname github.com --git-protocol ssh --web --skip-ssh-key
gh auth status
```

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
gh auth status
jj --version
opencode debug config
```
