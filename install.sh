#!/usr/bin/env sh
# Lightweight installer for experiment (MIT)
# Installs the single bash script into /usr/local/bin if writable,
# else falls back to ~/.local/bin. Override via env vars below.

set -eu

REPO="${REPO:-RAMCloudCode/experiment-venv}"  # GitHub "owner/repo"
REF="${REF:-main}"                            # branch or tag; default main
SRC_PATH="${SRC_PATH:-experiment}"            # path to script in repo
BIN_NAME="${BIN_NAME:-experiment}"            # install name
TARGET_DIR="${TARGET_DIR:-/usr/local/bin}"    # exact install dir (preferred)
FALLBACK_DIR="${FALLBACK_DIR:-$HOME/.local/bin}"

# Pick and create a writable install dir
INSTALL_DIR="$TARGET_DIR"
if ! mkdir -p "$TARGET_DIR" 2>/dev/null || [ ! -w "$TARGET_DIR" ]; then
  INSTALL_DIR="$FALLBACK_DIR"
  if ! mkdir -p "$INSTALL_DIR" 2>/dev/null || [ ! -w "$INSTALL_DIR" ]; then
    echo "Error: cannot write to $TARGET_DIR or fallback $FALLBACK_DIR" >&2
    exit 1
  fi
fi

# Fetch helper (curl or wget)
fetch() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$1" -O "$2"
  else
    echo "Error: need curl or wget" >&2
    exit 1
  fi
}

RAW_URL="https://raw.githubusercontent.com/$REPO/$REF/$SRC_PATH"
TMP="$(mktemp -t experiment.XXXXXX)"
trap 'rm -f "$TMP"' EXIT

echo "Downloading $BIN_NAME from $RAW_URL"
fetch "$RAW_URL" "$TMP"

# Sanity check: shebang on first line
if ! head -n 1 "$TMP" | grep -q '^#!/usr/bin/env bash$'; then
  echo "Download sanity check failed (unexpected shebang)" >&2
  exit 1
fi

chmod +x "$TMP"
if ! mv "$TMP" "$INSTALL_DIR/$BIN_NAME" 2>/dev/null; then
  # The permission check above can become stale, or the destination itself may
  # have restrictions. Retry in the fallback directory before giving up.
  if [ "$INSTALL_DIR" = "$FALLBACK_DIR" ]; then
    echo "Error: could not install to $INSTALL_DIR" >&2
    exit 1
  fi

  echo "Cannot install to $INSTALL_DIR; falling back to $FALLBACK_DIR" >&2
  INSTALL_DIR="$FALLBACK_DIR"
  if ! mkdir -p "$INSTALL_DIR" 2>/dev/null || [ ! -w "$INSTALL_DIR" ]; then
    echo "Error: fallback directory is not writable: $INSTALL_DIR" >&2
    exit 1
  fi
  mv "$TMP" "$INSTALL_DIR/$BIN_NAME"
fi

# Ensure PATH has INSTALL_DIR. Optionally auto-append to profile.
# Set AUTO_PATH_UPDATE=0 to disable.
AUTO_PATH_UPDATE="${AUTO_PATH_UPDATE:-1}"

in_path() { case ":$PATH:" in *":$1:"*) return 0;; *) return 1;; esac; }

if ! in_path "$INSTALL_DIR"; then
  # Pick a profile file based on OS and shell
  OS="$(uname 2>/dev/null || echo unknown)"
  SH="$(basename "${SHELL:-sh}")"
  case "$OS:$SH" in
    Darwin:zsh) PROFILE="$HOME/.zprofile" ;;
    Darwin:bash) PROFILE="$HOME/.bash_profile" ;;
    Darwin:*) PROFILE="$HOME/.profile" ;;
    *:zsh) PROFILE="$HOME/.zshrc" ;;
    *:bash) PROFILE="$HOME/.bashrc" ;;
    *:*) PROFILE="$HOME/.profile" ;;
  esac

  # Use $HOME form when possible for portability
  case "$INSTALL_DIR" in
    "$HOME"/*) PATH_DIR="\$HOME${INSTALL_DIR#$HOME}" ;;
    *) PATH_DIR="$INSTALL_DIR" ;;
  esac
  LINE="export PATH=\"$PATH_DIR:\$PATH\""

  if [ "$AUTO_PATH_UPDATE" = "1" ]; then
    mkdir -p "$(dirname "$PROFILE")"
    touch "$PROFILE"
    if ! grep -qsF "$LINE" "$PROFILE"; then
      echo "$LINE" >> "$PROFILE"
      echo "Added PATH to $PROFILE:"
      echo "  $LINE"
    else
      echo "PATH already configured in $PROFILE"
    fi
    echo "Open a new terminal or run: source \"$PROFILE\""
  else
    echo "Add to PATH so $BIN_NAME is available globally:"
    echo "  $LINE"
    echo "Append it to: $PROFILE  (then: source \"$PROFILE\")"
  fi
fi

# Minimal dependency hints (non-fatal)
need() { command -v "$1" >/dev/null 2>&1; }
missing=""
for d in bash python3 find mktemp grep cat dirname basename mv rm; do
  need "$d" || missing="$missing $d"
done
[ -n "$missing" ] && echo "Note: missing deps (script may not run):$missing" >&2

echo "Installed to $INSTALL_DIR/$BIN_NAME"
