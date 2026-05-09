#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: read-pane.sh [target-or-title] [options]

Capture recent output from a tmux pane. If no target is provided, reads current pane.

Options:
  -s, --session NAME    Session to search. Defaults to current session.
  -l, --lines N         History lines to capture. Default: 120.
  -r, --raw             Print only captured pane text.
  -h, --help            Show this help.

Targets can be pane ids (%12), tmux targets (session:1.2), exact pane titles,
or case-insensitive pane-title substrings.
USAGE
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

command -v tmux >/dev/null 2>&1 || die 'tmux was not found in PATH'

target_query=''
session=''
lines='120'
raw=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--session) session="${2-}"; shift 2 ;;
    -l|--lines|--lines) lines="${2-}"; shift 2 ;;
    -r|--raw) raw=true; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "unknown option: $1" ;;
    *)
      if [[ -z "$target_query" ]]; then
        target_query="$1"
        shift
      else
        die "unexpected argument: $1"
      fi
      ;;
  esac
done

[[ "$lines" =~ ^[1-9][0-9]*$ ]] || die '--lines must be a positive integer'

if [[ -z "$session" ]]; then
  session="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"
fi

resolve_target() {
  local query="$1"
  local query_lower
  query_lower="$(printf '%s' "$query" | tr '[:upper:]' '[:lower:]')"

  if [[ -z "$query" ]]; then
    tmux display-message -p '#{pane_id}' 2>/dev/null || true
    return
  fi

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

  local exact_matches=()
  local partial_matches=()
  local title_lower
  while IFS='|' read -r pane_id target title window_name command; do
    title_lower="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]')"
    if [[ "$title" == "$query" ]]; then
      exact_matches+=("$pane_id|$target|$title|$window_name|$command")
    elif [[ "$title_lower" == *"$query_lower"* ]]; then
      partial_matches+=("$pane_id|$target|$title|$window_name|$command")
    fi
  done < <(tmux list-panes "${list_args[@]}" -F '#{pane_id}|#{session_name}:#{window_index}.#{pane_index}|#{pane_title}|#{window_name}|#{pane_current_command}')

  if (( ${#exact_matches[@]} == 1 )); then
    printf '%s\n' "${exact_matches[0]%%|*}"
    return
  fi

  if (( ${#exact_matches[@]} > 1 )); then
    printf 'AMBIGUOUS\n'
    printf '%s\n' "${exact_matches[@]}" >&2
    return
  fi

  if (( ${#partial_matches[@]} == 1 )); then
    printf '%s\n' "${partial_matches[0]%%|*}"
    return
  fi

  if (( ${#partial_matches[@]} > 1 )); then
    printf 'AMBIGUOUS\n'
    printf '%s\n' "${partial_matches[@]}" >&2
    return
  fi
}

pane_id="$(resolve_target "$target_query")"
[[ "$pane_id" != 'AMBIGUOUS' ]] || die "pane target '$target_query' is ambiguous. Matching panes were printed above. Ask the user which one, because guessing here is how terminals become confetti."
[[ -n "$pane_id" ]] || die "no pane found for target/title: ${target_query:-current pane}"

resolved_target="$(tmux display-message -p -t "$pane_id" '#{session_name}:#{window_index}.#{pane_index}')"
window_name="$(tmux display-message -p -t "$pane_id" '#{window_name}')"
title="$(tmux display-message -p -t "$pane_id" '#{pane_title}')"
command="$(tmux display-message -p -t "$pane_id" '#{pane_current_command}')"

if [[ "$raw" == false ]]; then
  cat <<EOF
TMUX_PANE=$pane_id
TMUX_TARGET=$resolved_target
TMUX_WINDOW=$window_name
TMUX_PANE_TITLE=$title
TMUX_PANE_COMMAND=$command
CAPTURE_COMMAND=tmux capture-pane -p -J -t '$pane_id' -S -$lines
--- output ---
EOF
fi

tmux capture-pane -p -J -t "$pane_id" -S "-$lines"
