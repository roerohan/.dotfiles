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
    config.permission = {
      '*': 'allow',
      bash: { '*': 'allow', 'cat *opencode*auth*': 'deny', 'cat *mcp-auth*': 'deny', 'cat *auth.json': 'deny' },
      read: { '*': 'allow', '**/.local/share/opencode/**': 'deny', '**/mcp-auth.json': 'deny', '**/auth.json': 'deny' },
      edit: 'allow',
      external_directory: { '*': 'allow', '**/.local/share/opencode/**': 'deny' }
    };
    fs.writeFileSync(p, JSON.stringify(config, null, 2) + '\n');
  "
  echo "Patched opencode.json for yolo mode"
fi

# Copy host gitconfig files and patch signing for SSH
SSH_PUB_KEY=$(cat "$HOME/.ssh/id_ed25519.pub" 2>/dev/null || true)

patch_signing() {
  if [ -n "$SSH_PUB_KEY" ] && git config -f "$1" user.signingkey >/dev/null 2>&1; then
    git config -f "$1" user.signingkey "key::${SSH_PUB_KEY}"
    git config -f "$1" gpg.format ssh
  fi
}

for f in "$HOME"/.gitconfig "$HOME"/.gitconfig-*; do
  [ -f "$f" ] || continue
  dest="$KIT_DIR/files/home/$(basename "$f")"
  cp "$f" "$dest"
  patch_signing "$dest"
  echo "Synced $(basename "$f")"
done

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

# Export corporate CA certificates from macOS keychain for sandbox TLS trust
CERT_DEST="$KIT_DIR/files/home/.ssl"
mkdir -p "$CERT_DEST"
CERT_FILE="$CERT_DEST/corp-ca-bundle.pem"
CERT_COUNT=0
: > "$CERT_FILE"
for cert_cn in \
  "Cloudflare Corporate Zero Trust" \
  "CFManage Root" \
  "CFManage Intermediate CA" \
  "Cloudflare for Teams ECC Certificate Authority"; do
  pem=$(security find-certificate -a -c "$cert_cn" -p /Library/Keychains/System.keychain 2>/dev/null || true)
  if [ -n "$pem" ]; then
    # Skip expired certs
    expiry=$(echo "$pem" | openssl x509 -noout -enddate 2>/dev/null | sed 's/notAfter=//')
    if [ -n "$expiry" ]; then
      exp_epoch=$(date -j -f "%b %d %T %Y %Z" "$expiry" "+%s" 2>/dev/null || echo 0)
      now_epoch=$(date "+%s")
      if [ "$exp_epoch" -lt "$now_epoch" ] 2>/dev/null; then
        echo "Skipping expired cert: $cert_cn (expired $expiry)"
        continue
      fi
    fi
    printf "# %s\n%s\n\n" "$cert_cn" "$pem" >> "$CERT_FILE"
    CERT_COUNT=$((CERT_COUNT + 1))
  fi
done
if [ "$CERT_COUNT" -gt 0 ]; then
  echo "Exported $CERT_COUNT corporate CA cert(s) to $CERT_FILE"
else
  rm -f "$CERT_FILE"
  rmdir "$CERT_DEST" 2>/dev/null || true
  echo "No corporate CA certs found — skipping cert bundle"
fi
