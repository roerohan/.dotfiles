#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$script_dir/lib.sh"

usage() {
  cat <<'USAGE'
Usage: stop-pane.sh target-or-title [options]

Gracefully stop a tmux pane by pane id, tmux target, exact title, or title substring.

Options:
  -s, --session NAME        Session to search. Defaults to current session.
  -g, --grace SECONDS       Seconds to wait after C-c. Default: 2.
  -k, --kill                Kill the pane after grace period if it still exists. Default: true.
  --no-kill                 Send C-c only; leave the pane if it remains.
  -h, --help                Show this help.
USAGE
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

command -v tmux >/dev/null 2>&1 || die 'tmux was not found in PATH'

target_query=''
session=''
grace='2'
kill_after=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--session) session="${2-}"; shift 2 ;;
    -g|--grace) grace="${2-}"; shift 2 ;;
    -k|--kill) kill_after=true; shift ;;
    --no-kill) kill_after=false; shift ;;
    -h|--help) usage; exit 0 ;;
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

[[ -n "$target_query" ]] || die 'target or pane title is required'
[[ "$grace" =~ ^[0-9]+$ ]] || die '--grace must be an integer number of seconds'

if [[ -z "$session" ]]; then
  session="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"
fi

resolve_target() {
  local query="$1"
  local query_lower
  query_lower="$(printf '%s' "$query" | tr '[:upper:]' '[:lower:]')"

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
[[ "$pane_id" != 'AMBIGUOUS' ]] || die "pane target '$target_query' is ambiguous. Matching panes were printed above."
[[ -n "$pane_id" ]] || die "no pane found for target/title: $target_query"

if ! resolved_target="$(tmux display-message -p -t "$pane_id" '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null)"; then
  tmux_skill_registry_remove_pane "$pane_id"
  cat <<EOF
Stopped tmux pane
TMUX_PANE=$pane_id
TMUX_TARGET=unknown
TMUX_WINDOW=unknown
TMUX_PANE_TITLE=$target_query
TMUX_PANE_COMMAND=unknown
ACTION=pane was already gone before metadata could be read
EOF
  exit 0
fi

window_name="$(tmux display-message -p -t "$pane_id" '#{window_name}')"
title="$(tmux display-message -p -t "$pane_id" '#{pane_title}')"
command="$(tmux display-message -p -t "$pane_id" '#{pane_current_command}')"

if ! tmux send-keys -t "$pane_id" C-c 2>/dev/null; then
  tmux_skill_registry_remove_pane "$pane_id"
  cat <<EOF
Stopped tmux pane
TMUX_PANE=$pane_id
TMUX_TARGET=$resolved_target
TMUX_WINDOW=$window_name
TMUX_PANE_TITLE=$title
TMUX_PANE_COMMAND=$command
ACTION=pane was already gone before C-c could be sent
EOF
  exit 0
fi

if (( grace > 0 )); then
  sleep "$grace"
fi

pane_exists=false
if tmux display-message -p -t "$pane_id" '#{pane_id}' >/dev/null 2>&1; then
  pane_exists=true
fi

action='sent C-c'
if [[ "$pane_exists" == true && "$kill_after" == true ]]; then
  if tmux kill-pane -t "$pane_id" 2>/dev/null; then
    action='sent C-c, then killed remaining pane'
  else
    action='sent C-c; pane exited before kill-pane'
  fi
elif [[ "$pane_exists" == false ]]; then
  action='sent C-c; pane exited'
fi

tmux_skill_registry_remove_pane "$pane_id"

cat <<EOF
Stopped tmux pane
TMUX_PANE=$pane_id
TMUX_TARGET=$resolved_target
TMUX_WINDOW=$window_name
TMUX_PANE_TITLE=$title
TMUX_PANE_COMMAND=$command
ACTION=$action
EOF
