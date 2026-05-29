#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/roerohan/.dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
NVM_VERSION="${NVM_VERSION:-v0.40.3}"

log() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf '\nWARN: %s\n' "$*" >&2
}

read_tty() {
  local prompt="$1"
  local default="${2:-}"
  local answer

  if [ -r /dev/tty ]; then
    printf '%s' "$prompt" > /dev/tty
    IFS= read -r answer < /dev/tty || answer="$default"
  else
    answer="$default"
  fi

  printf '%s' "${answer:-$default}"
}

read_secret_tty() {
  local prompt="$1"
  local answer=""

  if [ -r /dev/tty ]; then
    printf '%s' "$prompt" > /dev/tty
    stty -echo < /dev/tty
    IFS= read -r answer < /dev/tty || answer=""
    stty echo < /dev/tty
    printf '\n' > /dev/tty
  fi

  printf '%s' "$answer"
}

ask_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  local suffix="[Y/n]"
  local answer

  if [ "$default" = "n" ]; then
    suffix="[y/N]"
  fi

  answer="$(read_tty "$prompt $suffix " "$default")"
  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    n|N|no|NO) return 1 ;;
    *) [ "$default" = "y" ] ;;
  esac
}

backup_path() {
  local path="$1"

  if [ -e "$path" ] || [ -L "$path" ]; then
    mv "$path" "$path.backup.$(date +%Y%m%d%H%M%S)"
  fi
}

same_file_content() {
  local left="$1"
  local right="$2"

  [ -f "$left" ] && [ -f "$right" ] && cmp -s "$left" "$right"
}

install_if_changed() {
  local src="$1"
  local dest="$2"
  local mode="${3:-}"

  if same_file_content "$src" "$dest"; then
    log "$dest already up to date"
    return
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if ! ask_yes_no "$dest exists and differs. Replace it?" n; then
      log "Keeping existing $dest"
      return
    fi
    backup_path "$dest"
  fi

  if [ -n "$mode" ]; then
    install -m "$mode" "$src" "$dest"
  else
    cp "$src" "$dest"
  fi
}

link_if_needed() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    log "$dest already linked"
    return
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if ! ask_yes_no "$dest exists and is not the expected link. Replace it?" n; then
      log "Keeping existing $dest"
      return
    fi
    backup_path "$dest"
  fi

  ln -s "$src" "$dest"
}

sudo_cmd() {
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

install_apt_packages() {
  log "Installing Ubuntu packages"
  sudo_cmd apt update
  sudo_cmd apt install -y \
    git curl ca-certificates gnupg build-essential pkg-config \
    zsh tmux neovim \
    ripgrep fd-find fzf direnv \
    zsh-syntax-highlighting zsh-autosuggestions \
    unzip tar gzip xz-utils \
    python3 python3-pip python3-venv \
    ruby ruby-dev pipx \
    lsof perl procps jq coreutils \
    rsync \
    xclip xsel wl-clipboard \
    openssh-client
}

install_github_cli() {
  if command -v gh >/dev/null 2>&1; then
    log "GitHub CLI already installed"
    return
  fi

  if ! ask_yes_no "Install GitHub CLI (gh)?" n; then
    log "Skipping GitHub CLI install"
    return
  fi

  log "Installing GitHub CLI"
  sudo_cmd mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo_cmd tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo_cmd chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  printf 'deb [arch=%s signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n' "$(dpkg --print-architecture)" | sudo_cmd tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo_cmd apt update
  sudo_cmd apt install -y gh
}

configure_sshd_accept_env() {
  local config_path="/etc/ssh/sshd_config.d/90-llm-env.conf"
  local sshd_bin=""

  if ! ask_yes_no "Allow SSH SendEnv for OpenAI/Anthropic API keys on this box?" n; then
    log "Skipping sshd AcceptEnv setup"
    return
  fi

  if [ -x /usr/sbin/sshd ]; then
    sshd_bin="/usr/sbin/sshd"
  elif command -v sshd >/dev/null 2>&1; then
    sshd_bin="$(command -v sshd)"
  else
    log "Installing openssh-server for sshd AcceptEnv support"
    sudo_cmd apt install -y openssh-server
    if [ -x /usr/sbin/sshd ]; then
      sshd_bin="/usr/sbin/sshd"
    elif command -v sshd >/dev/null 2>&1; then
      sshd_bin="$(command -v sshd)"
    fi
  fi

  log "Configuring sshd AcceptEnv for LLM API keys"
  printf 'AcceptEnv OPENAI_API_KEY ANTHROPIC_API_KEY\n' | sudo_cmd tee "$config_path" >/dev/null
  sudo_cmd chmod 644 "$config_path"

  if [ -n "$sshd_bin" ]; then
    sudo_cmd "$sshd_bin" -t
  else
    warn "Could not find sshd to validate config. The config was written, but sshd may not be installed. Excellent ambiguity, very on brand."
  fi

  if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files ssh.service >/dev/null 2>&1; then
    sudo_cmd systemctl reload ssh
  elif command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files sshd.service >/dev/null 2>&1; then
    sudo_cmd systemctl reload sshd
  else
    warn "Could not reload sshd automatically. Run: sudo systemctl reload ssh"
  fi
}

clone_or_update_dotfiles() {
  log "Cloning/updating dotfiles"
  if [ -d "$DOTFILES_DIR/.git" ]; then
    git -C "$DOTFILES_DIR" pull --ff-only || warn "Could not fast-forward $DOTFILES_DIR; leaving existing checkout alone. Tiny git goblin dodged."
  elif [ -e "$DOTFILES_DIR" ]; then
    warn "$DOTFILES_DIR exists but is not a git repo; skipping clone. Set DOTFILES_DIR to another path if needed."
  else
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
}

install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log "Oh My Zsh already installed"
    return
  fi

  log "Installing Oh My Zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_nvm_node() {
  if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
    log "Installing nvm"
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash
  fi

  # shellcheck disable=SC1091
  . "$HOME/.nvm/nvm.sh"

  log "Installing latest Node.js LTS"
  set +u
  nvm install --lts
  nvm alias default 'lts/*'
  nvm use --lts
  set -u
}

install_bun() {
  if command -v bun >/dev/null 2>&1 || [ -x "$HOME/.bun/bin/bun" ]; then
    log "Bun already installed"
  else
    log "Installing Bun"
    curl -fsSL https://bun.sh/install | bash
  fi

  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
}

install_opencode() {
  log "Installing OpenCode"
  if command -v opencode >/dev/null 2>&1; then
    log "OpenCode already installed"
  else
    npm install -g opencode-ai
  fi

  if [ -f "$DOTFILES_DIR/opencode/package.json" ]; then
    log "Installing OpenCode config package dependencies"
    npm install --prefix "$DOTFILES_DIR/opencode"
  fi
}

configure_tmux() {
  if ! ask_yes_no "Configure tmux dotfiles?" y; then
    log "Skipping tmux config"
    return
  fi

  log "Configuring tmux"
  link_if_needed "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
  link_if_needed "$DOTFILES_DIR/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"
}

configure_opencode() {
  local tmp_config

  if ! ask_yes_no "Configure OpenCode dotfiles and remote-friendly permissions?" y; then
    log "Skipping OpenCode config"
    return
  fi

  log "Configuring OpenCode"
  mkdir -p "$HOME/.config/opencode"
  tmp_config="$(mktemp)"
  cat > "$tmp_config" <<'JSON'
{
  "$schema": "https://opencode.ai/config.json",
  "autoupdate": true,
  "plugin": [
    "@plannotator/opencode@latest"
  ],
  "model": "openai/gpt-5.5",
  "permission": {
    "bash": {
      "*": "allow",
      "env": "deny",
      "printenv": "deny",
      "printenv *": "deny",
      "set": "deny",
      "cat *.env": "deny",
      "cat *.env.*": "deny",
      "cat **/.env": "deny",
      "cat **/.env.*": "deny",
      "cat ~/.zshenv": "deny",
      "cat $HOME/.zshenv": "deny",
      "cat ~/.netrc": "deny",
      "cat $HOME/.netrc": "deny",
      "cat ~/.npmrc": "deny",
      "cat $HOME/.npmrc": "deny",
      "cat **/secrets/**": "deny",
      "cat **/.ssh/**": "deny",
      "cat **/.aws/**": "deny",
      "cat **/.gcp/**": "deny",
      "cat **/.gnupg/**": "deny",
      "cat **/.kube/**": "deny",
      "head *.env*": "deny",
      "tail *.env*": "deny",
      "less *.env*": "deny"
    },
    "edit": {
      "*": "allow",
      "*.env": "deny",
      "*.env.*": "deny",
      "*.env.example": "allow",
      "*.envrc": "deny",
      "**/.env": "deny",
      "**/.env.*": "deny",
      "**/.envrc": "deny",
      ".dev.vars": "deny",
      "**/.dev.vars": "deny",
      "secrets/*": "deny",
      "**/secrets/**": "deny",
      "*.pem": "deny",
      "*.key": "deny",
      "*.p12": "deny",
      "*.pfx": "deny",
      "~/.zshenv": "deny",
      "$HOME/.zshenv": "deny",
      "~/.netrc": "deny",
      "$HOME/.netrc": "deny",
      "~/.npmrc": "deny",
      "$HOME/.npmrc": "deny",
      "**/.ssh/**": "deny",
      "**/.aws/**": "deny",
      "**/.gcp/**": "deny",
      "**/.gnupg/**": "deny",
      "**/.kube/**": "deny",
      "$HOME/.local/share/opencode/mcp-auth.json": "deny",
      "~/.local/share/opencode/mcp-auth.json": "deny",
      "$HOME/.local/share/opencode/auth.json": "deny",
      "~/.local/share/opencode/auth.json": "deny"
    },
    "read": {
      "*": "allow",
      "*.env": "deny",
      "*.env.*": "deny",
      "*.env.example": "allow",
      "*.envrc": "deny",
      "**/.env": "deny",
      "**/.env.*": "deny",
      "**/.envrc": "deny",
      ".dev.vars": "deny",
      "**/.dev.vars": "deny",
      "secrets/*": "deny",
      "**/secrets/**": "deny",
      "*.pem": "deny",
      "*.key": "deny",
      "*.p12": "deny",
      "*.pfx": "deny",
      "~/.zshenv": "deny",
      "$HOME/.zshenv": "deny",
      "~/.netrc": "deny",
      "$HOME/.netrc": "deny",
      "~/.npmrc": "deny",
      "$HOME/.npmrc": "deny",
      "**/.ssh/**": "deny",
      "**/.aws/**": "deny",
      "**/.gcp/**": "deny",
      "**/.gnupg/**": "deny",
      "**/.kube/**": "deny",
      "$HOME/.local/share/opencode/mcp-auth.json": "deny",
      "~/.local/share/opencode/mcp-auth.json": "deny",
      "$HOME/.local/share/opencode/auth.json": "deny",
      "~/.local/share/opencode/auth.json": "deny"
    },
    "external_directory": {
      "*": "allow",
      "**/.ssh/**": "deny",
      "**/.aws/**": "deny",
      "**/.gcp/**": "deny",
      "**/.gnupg/**": "deny",
      "**/.kube/**": "deny",
      "~/.zshenv": "deny",
      "~/.netrc": "deny",
      "~/.npmrc": "deny",
      "~/.local/share/opencode/*": "deny"
    },
    "webfetch": "allow",
    "glob": "allow",
    "grep": "allow",
    "list": "allow",
    "lsp": "allow",
    "todowrite": "allow",
    "question": "allow",
    "task": "allow",
    "skill": "allow",
    "websearch": "allow"
  }
}
JSON
  install_if_changed "$tmp_config" "$HOME/.config/opencode/opencode.json"
  rm -f "$tmp_config"
  link_if_needed "$DOTFILES_DIR/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
  link_if_needed "$DOTFILES_DIR/opencode/skills" "$HOME/.config/opencode/skills"
}

configure_fd() {
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    log "Adding fd shim for Ubuntu's fdfind package name"
    mkdir -p "$HOME/.local/bin"
    link_if_needed "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
}

configure_git() {
  local git_name
  local git_email

  if ! ask_yes_no "Configure git globals from dotfiles?" n; then
    log "Skipping git config"
    return
  fi

  log "Configuring git"

  if [ -f "$DOTFILES_DIR/gitconfig" ]; then
    install_if_changed "$DOTFILES_DIR/gitconfig" "$HOME/.gitconfig"
  elif [ -f "$DOTFILES_DIR/.gitconfig" ]; then
    install_if_changed "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
  fi

  if [ -f "$DOTFILES_DIR/.gitconfig-dyte" ]; then
    install_if_changed "$DOTFILES_DIR/.gitconfig-dyte" "$HOME/.gitconfig-dyte"
  elif [ -f "$DOTFILES_DIR/gitconfig-dyte" ]; then
    install_if_changed "$DOTFILES_DIR/gitconfig-dyte" "$HOME/.gitconfig-dyte"
  fi

  git_name="$(git config --global user.name 2>/dev/null || printf 'Rohan Mukherjee')"
  git_email="$(git config --global user.email 2>/dev/null || printf 'roerohan@gmail.com')"
  git_name="$(read_tty "Git user.name [$git_name]: " "$git_name")"
  git_email="$(read_tty "Git user.email [$git_email]: " "$git_email")"

  [ -n "$git_name" ] && git config --global user.name "$git_name"
  [ -n "$git_email" ] && git config --global user.email "$git_email"
  git config --global url.git@github.com:.insteadOf https://github.com/
  git config --global push.autoSetupRemote true
  git config --global init.defaultBranch main

  warn "SSH signing is not configured on the remote. Use SSH agent forwarding for GitHub auth, or configure signing manually if you need signed commits here."
  git config --global commit.gpgsign false
}

configure_github_cli() {
  if ! command -v gh >/dev/null 2>&1; then
    warn "gh is not installed; skipping GitHub CLI auth"
    return
  fi

  if ! ask_yes_no "Configure/authenticate GitHub CLI?" n; then
    log "Skipping GitHub CLI config"
    return
  fi

  if gh auth status >/dev/null 2>&1; then
    log "GitHub CLI already authenticated"
  elif ask_yes_no "Authenticate gh now? This opens GitHub device/browser login." y; then
    gh auth login -h github.com -p ssh -w || warn "gh auth login failed; you can run it later. Computers remain undefeated."
  fi

  if gh auth status >/dev/null 2>&1; then
    log "GitHub CLI auth is ready"
  fi
}

configure_sbx_kit() {
  local kit_src="$DOTFILES_DIR/sbx/opencode-config"
  local kit_dest="$HOME/.config/sbx-kits/opencode-config"

  if [ ! -d "$kit_src" ]; then
    log "No sbx kit found in repo; skipping"
    return
  fi

  if ! ask_yes_no "Install/update sbx opencode-config kit?" y; then
    log "Skipping sbx kit setup"
    return
  fi

  log "Installing sbx opencode-config kit"
  mkdir -p "$HOME/.config/sbx-kits"
  mkdir -p "$kit_dest"
  rsync -a --delete \
    --exclude='files/home/.local/share/opencode/auth.json' \
    --exclude='files/home/.local/share/opencode/mcp-auth.json' \
    "$kit_src/" "$kit_dest/"

  if command -v sbx >/dev/null 2>&1 && ask_yes_no "Run sbx kit sync now? This may copy local OpenCode auth into the kit if present." n; then
    "$kit_dest/sync.sh" || warn "sbx kit sync failed"
  elif ! command -v sbx >/dev/null 2>&1; then
    warn "sbx CLI not found. Kit installed at $kit_dest; install sbx separately before using it. Because one more CLI was apparently necessary."
  fi
}

write_api_key_exports() {
  local zshenv="$HOME/.zshenv"
  local openai_key="${OPENAI_API_KEY:-}"
  local anthropic_key="${ANTHROPIC_API_KEY:-}"
  local tmp=""

  if [ -z "$openai_key" ] && ! grep -q '^export OPENAI_API_KEY=' "$zshenv" 2>/dev/null; then
    openai_key="$(read_secret_tty "OpenAI API key (blank to skip): ")"
  fi

  if [ -z "$anthropic_key" ] && ! grep -q '^export ANTHROPIC_API_KEY=' "$zshenv" 2>/dev/null; then
    anthropic_key="$(read_secret_tty "Anthropic API key (blank to skip): ")"
  fi

  if [ -z "$openai_key" ] && [ -z "$anthropic_key" ]; then
    log "No new API keys provided"
    return
  fi

  log "Writing API key exports to ~/.zshenv"
  tmp="$(mktemp)"
  if [ -f "$zshenv" ]; then
    awk '
      /^# >>> dotfiles remote-box api keys >>>$/ { skip = 1; next }
      /^# <<< dotfiles remote-box api keys <<<$/ { skip = 0; next }
      skip != 1 { print }
    ' "$zshenv" > "$tmp"
  else
    : > "$tmp"
  fi

  {
    printf '\n# >>> dotfiles remote-box api keys >>>\n'
    [ -n "$openai_key" ] && printf 'export OPENAI_API_KEY=%q\n' "$openai_key"
    [ -n "$anthropic_key" ] && printf 'export ANTHROPIC_API_KEY=%q\n' "$anthropic_key"
    printf '# <<< dotfiles remote-box api keys <<<\n'
  } >> "$tmp"

  install -m 600 "$tmp" "$zshenv"
  rm -f "$tmp"

  [ -n "$openai_key" ] && export OPENAI_API_KEY="$openai_key"
  [ -n "$anthropic_key" ] && export ANTHROPIC_API_KEY="$anthropic_key"
}

load_existing_api_key_exports() {
  local loaded_openai=""
  local loaded_anthropic=""

  if [ ! -f "$HOME/.zshenv" ] || ! command -v zsh >/dev/null 2>&1; then
    return
  fi

  if [ -z "${OPENAI_API_KEY:-}" ]; then
    loaded_openai="$(zsh -c 'print -r -- ${OPENAI_API_KEY-}' 2>/dev/null || true)"
    [ -n "$loaded_openai" ] && export OPENAI_API_KEY="$loaded_openai"
  fi

  if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    loaded_anthropic="$(zsh -c 'print -r -- ${ANTHROPIC_API_KEY-}' 2>/dev/null || true)"
    [ -n "$loaded_anthropic" ] && export ANTHROPIC_API_KEY="$loaded_anthropic"
  fi
}

copy_linux_zshrc() {
  local tmp_zshrc

  if ! ask_yes_no "Copy repo zshrc to ~/.zshrc and patch it for Ubuntu?" y; then
    log "Skipping zshrc copy"
    return
  fi

  log "Copying and Linux-patching zshrc"
  tmp_zshrc="$(mktemp)"
  cp "$DOTFILES_DIR/zsh/zshrc" "$tmp_zshrc"

  perl -0pi -e 's/^source ~\/\.bashrc$/# source ~\/\.bashrc # disabled: bash config breaks zsh/m' "$tmp_zshrc"
  perl -0pi -e 's|^\[ -s "/opt/homebrew/opt/nvm/nvm\.sh" \] && \\. "/opt/homebrew/opt/nvm/nvm\.sh".*$|[ -s "$HOME/.nvm/nvm.sh" ] \&\& \\. "$HOME/.nvm/nvm.sh"|m' "$tmp_zshrc"
  perl -0pi -e 's|^\[ -s "/opt/homebrew/opt/nvm/etc/bash_completion\.d/nvm" \] && \\. "/opt/homebrew/opt/nvm/etc/bash_completion\.d/nvm".*$|[ -s "$HOME/.nvm/bash_completion" ] \&\& \\. "$HOME/.nvm/bash_completion"|m' "$tmp_zshrc"
  perl -0pi -e 's|^export GPG_TTY=/dev/ttys001$|export GPG_TTY="$(tty)"|m' "$tmp_zshrc"
  perl -0pi -e 's|^source <\(fzf --zsh\)$|if command -v fzf >/dev/null 2>\&1 \&\& fzf --zsh >/dev/null 2>\&1; then\n  source <(fzf --zsh)\nelif [ -s /usr/share/doc/fzf/examples/key-bindings.zsh ]; then\n  source /usr/share/doc/fzf/examples/key-bindings.zsh\nfi|m' "$tmp_zshrc"
  perl -0pi -e 's|^source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting\.zsh$|[ -s /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] \&\& source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh|m' "$tmp_zshrc"
  perl -0pi -e 's|^source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions\.zsh$|[ -s /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] \&\& source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh|m' "$tmp_zshrc"
  perl -0pi -e 's|^source ~/\.zshenv$|[ -f ~/.zshenv ] \&\& source ~/.zshenv|m' "$tmp_zshrc"
  perl -0pi -e 's|/Users/rmukherjee/\.bun/_bun|$HOME/.bun/_bun|g' "$tmp_zshrc"
  perl -0pi -e 's|^export PNPM_HOME="/Users/rmukherjee/Library/pnpm"$|export PNPM_HOME="$HOME/.local/share/pnpm"|m' "$tmp_zshrc"
  install_if_changed "$tmp_zshrc" "$HOME/.zshrc"
  rm -f "$tmp_zshrc"
}

configure_neovim() {
  if ! ask_yes_no "Install AstroNvim template and link repo plugins?" y; then
    log "Skipping Neovim setup"
    return
  fi

  log "Configuring AstroNvim"
  mkdir -p "$HOME/.config"
  if [ -e "$HOME/.config/nvim" ] || [ -L "$HOME/.config/nvim" ]; then
    if [ -L "$HOME/.config/nvim/lua/plugins" ] && [ "$(readlink "$HOME/.config/nvim/lua/plugins")" = "$DOTFILES_DIR/nvim/AstroNvim/v4/plugins" ]; then
      log "AstroNvim already appears configured"
      return
    fi
    if ! ask_yes_no "$HOME/.config/nvim exists. Replace it with AstroNvim template?" n; then
      log "Keeping existing Neovim config"
      return
    fi
    backup_path "$HOME/.config/nvim"
  fi
  git clone --depth 1 https://github.com/AstroNvim/template.git "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/lua/plugins"
  ln -s "$DOTFILES_DIR/nvim/AstroNvim/v4/plugins" "$HOME/.config/nvim/lua/plugins"
}

set_login_shell() {
  local zsh_bin
  zsh_bin="$(command -v zsh)"

  if [ "${SHELL:-}" = "$zsh_bin" ]; then
    log "Login shell already appears to be zsh"
    return
  fi

  if ask_yes_no "Change login shell to zsh for $USER?" y; then
    chsh -s "$zsh_bin" || warn "chsh failed. Run manually: chsh -s '$zsh_bin'"
  fi
}

run_local_validation() {
  log "Running local validation"
  command -v zsh >/dev/null
  command -v tmux >/dev/null
  command -v nvim >/dev/null
  command -v node >/dev/null
  command -v npm >/dev/null
  command -v opencode >/dev/null
  command -v gh >/dev/null || warn "gh is not installed; skipped or failed"
  git config --global user.name >/dev/null || warn "git user.name is not set"
  git config --global user.email >/dev/null || warn "git user.email is not set"
  [ -f "$HOME/.zshrc" ] && zsh -n "$HOME/.zshrc" || warn "~/.zshrc not found; zsh validation skipped"
  opencode debug config >/dev/null
  if [ -f "$HOME/.tmux.conf" ]; then
    tmux -L dotfiles-setup -f "$HOME/.tmux.conf" start-server \; source-file "$HOME/.tmux.conf" \; kill-server
  else
    warn "~/.tmux.conf not found; tmux config validation skipped"
  fi
  if [ -d "$HOME/.config/nvim" ]; then
    timeout 45 nvim --headless '+qall' || warn "nvim headless validation failed or timed out; plugins may still be installing on first launch. Naturally."
  else
    warn "~/.config/nvim not found; Neovim config validation skipped"
  fi
  if [ -n "${SSH_AUTH_SOCK:-}" ]; then
    ssh-add -l >/dev/null 2>&1 || warn "SSH_AUTH_SOCK is set but no forwarded/listable keys are visible. Git over SSH may fail until you reconnect with agent forwarding."
  else
    warn "SSH_AUTH_SOCK is not set. Reconnect with ssh -A for GitHub SSH auth."
  fi
}

run_opencode_validation() {
  if [ "${RUN_OPENCODE_VALIDATE:-1}" = "0" ]; then
    log "Skipping OpenCode validation because RUN_OPENCODE_VALIDATE=0"
    return
  fi

  if ! command -v opencode >/dev/null 2>&1; then
    warn "opencode is not available; skipping OpenCode validation"
    return
  fi

  if [ -z "${OPENAI_API_KEY:-}" ] && [ -z "${ANTHROPIC_API_KEY:-}" ] && [ "${OPENCODE_FORCE_VALIDATE:-0}" != "1" ]; then
    if ! ask_yes_no "No OpenAI/Anthropic env keys are loaded. Try final OpenCode validation anyway?" n; then
      log "Skipping OpenCode validation"
      return
    fi
  fi

  log "Running OpenCode validation"
  opencode run --agent build --model "${OPENCODE_VALIDATE_MODEL:-openai/gpt-5.5}" "
Validate this remote Ubuntu dotfiles setup. Do not edit files and do not print secrets.

Check:
- zsh parses ~/.zshrc without Bash shopt errors
- ~/.zshrc does not source ~/.bashrc
- ~/.zshrc uses Linux paths for nvm, zsh-syntax-highlighting, zsh-autosuggestions, GPG_TTY, bun, and pnpm
- if configured, tmux config loads from ~/.tmux.conf
- if configured, Neovim config exists at ~/.config/nvim and links repo plugins
- if configured, OpenCode global config, AGENTS.md, and skills are wired under ~/.config/opencode
- OpenCode config permits normal read/edit/bash/tool usage but denies secrets, .env files, SSH/AWS/GCP/GPG/Kube material, and OpenCode auth files
- if configured, git global user.name/user.email are set, gh is installed/authenticated, and ~/.config/sbx-kits/opencode-config exists if the sbx kit was requested
- SSH agent forwarding is available for GitHub SSH auth, or the report explains how to reconnect with ssh -A
- node, npm, bun, opencode, tmux, nvim, rg, fd/fdfind, fzf, and direnv are available; gh is optional if skipped

Return a concise PASS/FAIL report with exact fixes if anything is wrong.
"
}

print_final_instructions() {
  log "SSH agent forwarding follow-up"

  printf 'This setup does not create SSH keys on the remote box. Use SSH agent forwarding from your local machine instead.\n\n'
  printf 'On your local machine, make sure your GitHub key is loaded:\n'
  printf '  ssh-add -l\n'
  printf '  ssh-add ~/.ssh/id_ed25519        # if needed\n\n'
  printf 'Reconnect to this box with agent forwarding:\n'
  printf '  ssh -A %s@<remote-host-or-ip>\n\n' "$USER"
  printf 'Then validate on the remote:\n'
  printf '  ssh-add -l\n'
  printf '  ssh -T git@github.com\n\n'
  printf 'If forwarding is disabled by local SSH config, add something like this locally in ~/.ssh/config:\n'
  printf '  Host <remote-alias>\n'
  printf '    HostName <remote-host-or-ip>\n'
  printf '    User %s\n' "$USER"
  printf '    ForwardAgent yes\n\n'
  printf 'If GitHub CLI auth is not set yet and you want it, run:\n  gh auth login -h github.com -p ssh -w\n\n'
  printf 'To forward OpenAI/Anthropic API keys per SSH session, add this locally in ~/.ssh/config:\n'
  printf '  Host <remote-alias>\n'
  printf '    SendEnv OPENAI_API_KEY ANTHROPIC_API_KEY\n\n'
  printf 'Then connect from a shell where those env vars are exported. The remote sshd must allow AcceptEnv; this script can configure that when you opt in.\n\n'
  printf 'Restart your shell with:\n  exec zsh -l\n'
}

main() {
  install_apt_packages
  install_github_cli
  configure_sshd_accept_env
  clone_or_update_dotfiles
  install_oh_my_zsh
  install_nvm_node
  install_bun
  install_opencode
  configure_git
  configure_github_cli
  configure_tmux
  configure_opencode
  configure_fd
  configure_sbx_kit
  write_api_key_exports
  load_existing_api_key_exports
  copy_linux_zshrc
  configure_neovim
  set_login_shell
  run_local_validation
  run_opencode_validation

  log "Remote box setup complete. Restart your shell with: exec zsh -l"
  print_final_instructions
}

main "$@"
