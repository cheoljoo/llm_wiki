#!/usr/bin/env bash
# Install vim-herdr-navigation and wire up the pane/workspace/tab keybindings
# used on this machine, so the same setup can be reproduced on another one.
#
# What it sets up:
#   - vim-herdr-navigation plugin (Vim split <-> herdr pane navigation)
#   - prefix+h/j/k/l           -> vim-aware pane navigation (plain ctrl+h/j/k/l
#                                 is avoided because some terminals, e.g.
#                                 Termius, reserve it)
#   - ctrl+shift+up/down       -> previous/next workspace ("space")
#   - ctrl+shift+left/right    -> previous/next tab
#   - ~/.vimrc                -> sources the plugin's editor/vim.vim
#
# Safe to re-run: config.toml is only auto-edited if it doesn't exist yet;
# otherwise the managed block is written next to it for manual merge, and
# ~/.vimrc / plugin install are idempotent.

set -euo pipefail

HERDR_CONFIG_DIR="${HERDR_CONFIG_DIR:-$HOME/.config/herdr}"
CONFIG_TOML="$HERDR_CONFIG_DIR/config.toml"
VIMRC="${VIMRC:-$HOME/.vimrc}"
PLUGIN_ID="vim-herdr-navigation"
PLUGIN_SOURCE="paulbkim-dev/vim-herdr-navigation"
MARKER_BEGIN="# >>> ${PLUGIN_ID} (managed by setup-herdr-vim-nav.sh) >>>"
MARKER_END="# <<< ${PLUGIN_ID} (managed by setup-herdr-vim-nav.sh) <<<"
VIM_MARKER_BEGIN="\" >>> ${PLUGIN_ID} (managed by setup-herdr-vim-nav.sh) >>>"
VIM_MARKER_END="\" <<< ${PLUGIN_ID} (managed by setup-herdr-vim-nav.sh) <<<"

log() { printf '==> %s\n' "$1"; }
warn() { printf 'WARNING: %s\n' "$1" >&2; }

command -v herdr >/dev/null 2>&1 || { warn "herdr not found in PATH. Install it (https://herdr.dev), then re-run this script."; exit 1; }
command -v jq >/dev/null 2>&1 || warn "jq not found — required by the plugin's navigate.sh to detect Vim. Install it (e.g. apt/brew install jq), then re-run this script."
command -v vim >/dev/null 2>&1 || warn "vim not found — the ~/.vimrc integration will be written but won't do anything until vim is installed."

herdr_version="$(herdr --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
if [ -n "$herdr_version" ]; then
  IFS=. read -r maj min _ <<<"$herdr_version"
  if [ "$maj" -eq 0 ] && [ "$min" -lt 7 ]; then
    warn "herdr $herdr_version detected; vim-herdr-navigation needs >= 0.7.0."
  fi
fi

log "Installing plugin ($PLUGIN_SOURCE)..."
herdr plugin install "$PLUGIN_SOURCE" --yes

plugin_root="$(herdr plugin list --json | jq -r --arg id "$PLUGIN_ID" '.result.plugins[] | select(.plugin_id == $id) | .plugin_root')"
if [ -z "$plugin_root" ]; then
  echo "Could not resolve plugin_root for $PLUGIN_ID from 'herdr plugin list --json'." >&2
  exit 1
fi
log "Plugin root: $plugin_root"

config_block() {
  cat <<EOF
$MARKER_BEGIN
[keys]
# Free up prefix+h/j/k/l so the plugin bindings below can claim them
# (built-in defaults would otherwise conflict with the same chord).
focus_pane_left = ""
focus_pane_down = ""
focus_pane_up = ""
focus_pane_right = ""

# ctrl+shift+up/down cycles workspaces ("spaces"); ctrl+shift+left/right cycles tabs.
previous_workspace = "ctrl+shift+up"
next_workspace = "ctrl+shift+down"
previous_tab = "ctrl+shift+left"
next_tab = "ctrl+shift+right"

[[keys.command]]
key = "prefix+h"
type = "plugin_action"
command = "${PLUGIN_ID}.left"
description = "navigate left (vim/herdr)"

[[keys.command]]
key = "prefix+j"
type = "plugin_action"
command = "${PLUGIN_ID}.down"
description = "navigate down (vim/herdr)"

[[keys.command]]
key = "prefix+k"
type = "plugin_action"
command = "${PLUGIN_ID}.up"
description = "navigate up (vim/herdr)"

[[keys.command]]
key = "prefix+l"
type = "plugin_action"
command = "${PLUGIN_ID}.right"
description = "navigate right (vim/herdr)"
$MARKER_END
EOF
}

mkdir -p "$HERDR_CONFIG_DIR"
if [ ! -f "$CONFIG_TOML" ]; then
  log "Creating $CONFIG_TOML"
  { echo "# herdr configuration"; echo; config_block; } > "$CONFIG_TOML"
elif grep -qF "$MARKER_BEGIN" "$CONFIG_TOML" 2>/dev/null; then
  log "$CONFIG_TOML already has the managed block, skipping."
else
  snippet="$HERDR_CONFIG_DIR/config.toml.${PLUGIN_ID}.snippet"
  config_block > "$snippet"
  warn "$CONFIG_TOML already exists — not auto-editing it (a bare [keys] table can only appear once in TOML)."
  warn "Merge $snippet into it by hand, then run: herdr config check && herdr server reload-config"
fi

vim_source_line="source ${plugin_root}/editor/vim.vim"
if [ -f "$VIMRC" ] && grep -qF "$VIM_MARKER_BEGIN" "$VIMRC" 2>/dev/null; then
  log "$VIMRC already has the managed block, skipping."
else
  log "Appending source line to $VIMRC"
  {
    echo
    echo "$VIM_MARKER_BEGIN"
    echo "\" vim-herdr-navigation: herdr side is bound to prefix+h/j/k/l, but it"
    echo "\" always forwards plain ctrl+h/j/k/l into the vim pane, so this side"
    echo "\" keeps the plugin's default C-h/j/k/l mapping."
    echo "$vim_source_line"
    echo "$VIM_MARKER_END"
  } >> "$VIMRC"
fi

if herdr config check >/dev/null 2>&1; then
  herdr server reload-config >/dev/null 2>&1 || warn "herdr server not running (or reload failed) — config will apply on next start."
  log "Done. Test: prefix+h/j/k/l for pane nav, ctrl+shift+up/down for workspaces, ctrl+shift+left/right for tabs."
else
  warn "herdr config check failed — review $CONFIG_TOML before relying on it."
  herdr config check || true
fi
