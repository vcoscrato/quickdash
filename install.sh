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

require_cmd() {
    local cmd="$1"
    local hint="$2"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: required command not found: $cmd"
        echo "       $hint"
        exit 1
    fi
}

warn_missing_cmd() {
    local cmd="$1"
    local feature="$2"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        warn "$cmd not found; $feature"
    fi
}

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

require_cmd quickshell "Install QuickShell first, then rerun this installer."

warn_missing_cmd nmcli "network controls will be unavailable until NetworkManager is installed."
warn_missing_cmd bluetoothctl "Bluetooth controls will be unavailable until BlueZ tools are installed."
warn_missing_cmd pactl "audio device controls may be limited until PulseAudio/PipeWire Pulse tools are installed."
warn_missing_cmd curl "weather refresh will be unavailable until curl is installed."

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

warn_missing_cmd brightnessctl "brightness controls will stay hidden until brightnessctl is installed."
warn_missing_cmd hyprsunset "night light controls will stay hidden until hyprsunset is installed."
warn_missing_cmd cliphist "clipboard history in Capture Pad will be unavailable until cliphist is installed."
warn_missing_cmd gtk-launch "desktop launcher entries will be unavailable until gtk-launch is installed."

# Warn if the bin dir is not in PATH
if [[ ":${PATH}:" != *":${BIN_DIR}:"* ]]; then
    warn "$BIN_DIR is not in your PATH."
    warn "Add this to your shell profile (.bashrc / .zshrc / .profile):"
    warn ""
    warn "  export PATH=\"\$PATH:$BIN_DIR\""
    echo ""
fi
