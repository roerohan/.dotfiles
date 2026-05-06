#!/bin/sh
# Syncs OpenCode config and data into this kit.
# Run this before `sbx run` to pick up config changes.
set -e

KIT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Sync ~/.config/opencode (excluding bulky/generated/binary/platform-specific files)
CONFIG_DEST="$KIT_DIR/files/home/.config/opencode"
CONFIG_SRC="$HOME/.config/opencode"
rm -rf "$CONFIG_DEST"
rsync -a \
  --exclude='node_modules' \
  --exclude='state' \
  --exclude='.gitignore' \
  --exclude='package-lock.json' \
  --exclude='bun.lock' \
  --exclude='sounds' \
  --exclude='plugins/notification.js' \
  "$CONFIG_SRC/" "$CONFIG_DEST/"
echo "Synced $CONFIG_SRC -> $CONFIG_DEST"

# Patch opencode.json for yolo mode: replace permission block with allow-all
# Uses sed to strip comments and trailing commas before JSON.parse
if command -v node >/dev/null 2>&1; then
  node -e "
    const fs = require('fs');
    const p = '$CONFIG_DEST/opencode.json';
    let raw = fs.readFileSync(p, 'utf-8');
    // Strip single-line comments
    raw = raw.replace(/^\s*\/\/.*$/gm, '');
    // Strip trailing commas before } or ]
    raw = raw.replace(/,\s*([\]}])/g, '\$1');
    const config = JSON.parse(raw);
    config.permission = { '*': 'allow', bash: { '*': 'allow' }, read: { '*': 'allow' }, edit: 'allow', external_directory: { '*': 'allow' } };
    fs.writeFileSync(p, JSON.stringify(config, null, 2) + '\n');
  "
  echo "Patched opencode.json for yolo mode"
fi

# Generate .gitconfig with SSH commit signing
SSH_PUB_KEY=$(cat "$HOME/.ssh/id_ed25519.pub" 2>/dev/null || true)
if [ -n "$SSH_PUB_KEY" ]; then
  GIT_USER_NAME=$(git config --global user.name 2>/dev/null || true)
  GIT_USER_EMAIL=$(git config --global user.email 2>/dev/null || true)
  cat > "$KIT_DIR/files/home/.gitconfig" <<GITEOF
[user]
	name = ${GIT_USER_NAME}
	email = ${GIT_USER_EMAIL}
	signingkey = key::${SSH_PUB_KEY}
[gpg]
	format = ssh
[commit]
	gpgsign = true
GITEOF
  echo "Generated .gitconfig with SSH signing"
fi

# Sync MCP auth tokens from ~/.local/share/opencode
DATA_SRC="$HOME/.local/share/opencode"
DATA_DEST="$KIT_DIR/files/home/.local/share/opencode"
if [ -f "$DATA_SRC/mcp-auth.json" ]; then
  mkdir -p "$DATA_DEST"
  cp "$DATA_SRC/mcp-auth.json" "$DATA_DEST/mcp-auth.json"
  echo "Synced mcp-auth.json"
fi
if [ -f "$DATA_SRC/auth.json" ]; then
  mkdir -p "$DATA_DEST"
  cp "$DATA_SRC/auth.json" "$DATA_DEST/auth.json"
  echo "Synced auth.json"
fi
