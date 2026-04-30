#!/usr/bin/env bash
#
# install.sh - Install an agent skill from a GitHub repository using gh CLI
#
# Usage: install.sh <OWNER/REPO> [SKILL[@VERSION]] [OPTIONS...]
#
# Defaults to --agent opencode --scope user unless overridden.
#
# Options are passed through to gh skill install. Common ones:
#   --agent <name>     Target agent (default: opencode)
#   --scope <scope>    project or user (default: user)
#   --dir <path>       Custom directory (overrides agent and scope)
#   --force            Overwrite existing skills
#   --pin <ref>        Pin to a specific git tag or commit SHA
#   --from-local       Treat first argument as local directory

set -euo pipefail

# Colors (only when connected to terminal)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' NC=''
fi

error() { echo -e "${RED}Error:${NC} $1" >&2; }
info() { echo -e "${GREEN}Info:${NC} $1"; }
warn() { echo -e "${YELLOW}Warning:${NC} $1"; }

# --- Prerequisite checks ---

if ! command -v gh >/dev/null 2>&1; then
    error "gh CLI not found."
    echo "  Install from: https://cli.github.com" >&2
    echo "  Then authenticate with: gh auth login" >&2
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    error "gh CLI is not authenticated."
    echo "  Run: gh auth login" >&2
    exit 1
fi

# --- Argument parsing ---

if [[ $# -lt 1 ]]; then
    echo "Usage: install.sh <OWNER/REPO> [SKILL[@VERSION]] [OPTIONS...]" >&2
    echo "" >&2
    echo "Defaults: --agent opencode --scope user" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  install.sh owner/repo skill-name" >&2
    echo "  install.sh owner/repo skill-name@v1.0.0" >&2
    echo "  install.sh owner/repo skill-name --scope project" >&2
    echo "  install.sh owner/repo skill-name --dir /path/to/skills" >&2
    echo "  install.sh owner/repo skill-name --agent claude-code" >&2
    exit 1
fi

REPO="$1"
shift

# Collect remaining args
EXTRA_ARGS=("$@")

# Determine if user provided --agent, --scope, or --dir overrides
HAS_AGENT=false
HAS_SCOPE=false
HAS_DIR=false

for arg in "${EXTRA_ARGS[@]}"; do
    case "$arg" in
        --agent) HAS_AGENT=true ;;
        --scope) HAS_SCOPE=true ;;
        --dir)   HAS_DIR=true ;;
    esac
done

# Build the command
CMD=(gh skill install "$REPO")

# Add remaining args (skill name, flags, etc.)
CMD+=("${EXTRA_ARGS[@]}")

# Apply defaults only if not overridden and --dir not set
if [[ "$HAS_DIR" == false ]]; then
    if [[ "$HAS_AGENT" == false ]]; then
        CMD+=(--agent opencode)
    fi
    if [[ "$HAS_SCOPE" == false ]]; then
        CMD+=(--scope user)
    fi
fi

# --- Execute ---

info "Running: ${CMD[*]}"
echo ""

if "${CMD[@]}"; then
    echo ""
    info "Skill installed successfully."
else
    EXIT_CODE=$?
    echo ""
    error "gh skill install failed (exit code $EXIT_CODE)."
    echo "  Check the error above for details." >&2
    echo "  Common fixes:" >&2
    echo "    - Verify the repo exists: gh repo view $REPO" >&2
    echo "    - List skills in the repo: gh skill install $REPO (interactive)" >&2
    echo "    - Force overwrite: add --force" >&2
    exit "$EXIT_CODE"
fi
