#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: wait-for-text.sh --target target-or-title --pattern pattern [options]

Poll a tmux pane until text appears.

Options:
  -t, --target TARGET    Pane id, tmux target, or pane title. Required.
  -p, --pattern PATTERN  Regex pattern to look for. Required.
  -F, --fixed            Treat pattern as a fixed string.
  -s, --session NAME     Session to search for pane titles. Defaults to current session.
  -T, --timeout SECONDS  Timeout. Default: 30.
  -i, --interval SECS    Poll interval. Default: 0.5.
  -l, --lines N          History lines to inspect. Default: 1000.
  -h, --help             Show this help.
USAGE
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

command -v tmux >/dev/null 2>&1 || die 'tmux was not found in PATH'

target=''
pattern=''
grep_flag='-E'
session=''
timeout='30'
interval='0.5'
lines='1000'

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target) target="${2-}"; shift 2 ;;
    -p|--pattern) pattern="${2-}"; shift 2 ;;
    -F|--fixed) grep_flag='-F'; shift ;;
    -s|--session) session="${2-}"; shift 2 ;;
    -T|--timeout) timeout="${2-}"; shift 2 ;;
    -i|--interval) interval="${2-}"; shift 2 ;;
    -l|--lines) lines="${2-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

[[ -n "$target" ]] || die '--target is required'
[[ -n "$pattern" ]] || die '--pattern is required'
[[ "$timeout" =~ ^[0-9]+$ ]] || die '--timeout must be an integer number of seconds'
[[ "$lines" =~ ^[1-9][0-9]*$ ]] || die '--lines must be a positive integer'

if [[ -z "$session" ]]; then
  session="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"
fi

resolve_target() {
  local query="$1"

  if [[ "$query" == %* ]] && tmux display-message -p -t "$query" '#{pane_id}' >/dev/null 2>&1; then
    printf '%s\n' "$query"
    return
  fi

  if [[ "$query" == *:* ]] && tmux display-message -p -t "$query" '#{pane_id}' >/dev/null 2>&1; then
    tmux display-message -p -t "$query" '#{pane_id}'
    return
  fi

  local list_args=(-a)
  if [[ -n "$session" ]]; then
    list_args=(-s -t "$session")
  fi

  local matches=()
  while IFS='|' read -r pane_id title; do
    if [[ "$title" == "$query" ]]; then
      matches+=("$pane_id")
    fi
  done < <(tmux list-panes "${list_args[@]}" -F '#{pane_id}|#{pane_title}')

  if (( ${#matches[@]} == 1 )); then
    printf '%s\n' "${matches[0]}"
    return
  fi

  if (( ${#matches[@]} > 1 )); then
    die "pane title '$query' is ambiguous; use a pane id"
  fi
}

pane_id="$(resolve_target "$target")"
[[ -n "$pane_id" ]] || die "no pane found for target/title: $target"

start_epoch="$(date +%s)"
deadline=$((start_epoch + timeout))
pane_text=''

while true; do
  pane_text="$(tmux capture-pane -p -J -t "$pane_id" -S "-$lines" 2>/dev/null || true)"

  if printf '%s\n' "$pane_text" | grep "$grep_flag" -- "$pattern" >/dev/null 2>&1; then
    resolved_target="$(tmux display-message -p -t "$pane_id" '#{session_name}:#{window_index}.#{pane_index}')"
    printf 'Found pattern in tmux pane %s (%s)\n' "$pane_id" "$resolved_target"
    exit 0
  fi

  now="$(date +%s)"
  if (( now >= deadline )); then
    printf 'Timed out after %ss waiting for pattern: %s\n' "$timeout" "$pattern" >&2
    printf 'Last %s lines from %s:\n' "$lines" "$pane_id" >&2
    printf '%s\n' "$pane_text" >&2
    exit 1
  fi

  sleep "$interval"
done
