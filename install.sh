#!/usr/bin/env bash
#
# QuickDash installer
#
# Installs QuickDash following XDG Base Directory conventions:
#
#   Config  $XDG_CONFIG_HOME/quickdash/  config.jsonc seeded from the example
#   Data    $XDG_DATA_HOME/quickdash/    todos, scratchpad
#   Bin     $HOME/.local/bin/quickdash   launcher script
#
# Run from the quickdash source directory:
#   ./install.sh
#
# To uninstall, run:
#   ./install.sh --uninstall

set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickdash"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/quickdash"
BIN_DIR="$HOME/.local/bin"
LAUNCHER="$BIN_DIR/quickdash"

# ── Helpers ───────────────────────────────────────────────────────────────────

info()    { echo "  $*"; }
success() { echo "✓ $*"; }
warn()    { echo "! $*"; }

# ── Uninstall ─────────────────────────────────────────────────────────────────

if [[ "${1:-}" == "--uninstall" ]]; then
    echo "Uninstalling QuickDash..."
    [[ -f "$LAUNCHER" ]]     && rm "$LAUNCHER"       && success "Removed launcher:    $LAUNCHER"
    warn "Config and data directories are NOT removed."
    warn "Delete manually if you want a clean slate:"
    warn "  rm -rf $CONFIG_DIR"
    warn "  rm -rf $DATA_DIR"
    exit 0
fi

# ── Runtime data dir ──────────────────────────────────────────────────────────

echo "Installing QuickDash..."
echo ""

if [[ -L "$DATA_DIR" ]]; then
    warn "Removing legacy app symlink: $DATA_DIR"
    rm "$DATA_DIR"
elif [[ -e "$DATA_DIR" && ! -d "$DATA_DIR" ]]; then
    echo "ERROR: $DATA_DIR exists and is not a directory."
    echo "       Move or remove it before running this installer."
    exit 1
fi

mkdir -p "$DATA_DIR"
success "Data dir:    $DATA_DIR"

for runtime_file in scratchpad.txt todos.json; do
    if [[ -f "$SOURCE_DIR/$runtime_file" && ! -e "$DATA_DIR/$runtime_file" ]]; then
        mv "$SOURCE_DIR/$runtime_file" "$DATA_DIR/$runtime_file"
        success "Migrated:    $DATA_DIR/$runtime_file"
    fi
done

# ── Config ────────────────────────────────────────────────────────────────────

mkdir -p "$CONFIG_DIR"

if [[ -f "$CONFIG_DIR/config.jsonc" ]]; then
    warn    "Config exists:   $CONFIG_DIR/config.jsonc  (not overwritten)"
else
    cp "$SOURCE_DIR/config.example.jsonc" "$CONFIG_DIR/config.jsonc"
    success "Config created:  $CONFIG_DIR/config.jsonc"
fi

# ── Launcher script ───────────────────────────────────────────────────────────

mkdir -p "$BIN_DIR"

printf '#!/usr/bin/env bash\nexec quickshell -p %q "$@"\n' "$SOURCE_DIR" > "$LAUNCHER"

chmod +x "$LAUNCHER"
success "Launcher:    $LAUNCHER"
info    "         →  $SOURCE_DIR"

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "Done."
echo ""
echo "  Start:  quickdash"
echo "  Config: $CONFIG_DIR/config.jsonc"
echo "  Data:   $DATA_DIR"
echo ""

# Warn if the bin dir is not in PATH
if [[ ":${PATH}:" != *":${BIN_DIR}:"* ]]; then
    warn "$BIN_DIR is not in your PATH."
    warn "Add this to your shell profile (.bashrc / .zshrc / .profile):"
    warn ""
    warn "  export PATH=\"\$PATH:$BIN_DIR\""
    echo ""
fi
