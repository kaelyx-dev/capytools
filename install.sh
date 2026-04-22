#!/usr/bin/env bash
# capytools installer / updater
# Run: curl -fsSL https://raw.githubusercontent.com/kaelyx-dev/capytools/main/install.sh | bash
set -euo pipefail

# TODO: set this to your GitHub username/repo before publishing
REPO="kaelyx-dev/capytools"

CAPYTOOLS_HOME="${CAPYTOOLS_HOME:-$HOME/.capytools}"
VERSIONS_DIR="$CAPYTOOLS_HOME/versions"
CONF="$CAPYTOOLS_HOME/capytools.conf.env"
USER_CONF="$CAPYTOOLS_HOME/user-capytools.conf.env"

# ---------------------------------------------------------------------------
# 1. Create install directory if needed
# ---------------------------------------------------------------------------
echo "capytools: [1/9] preparing install directory ..."
mkdir -p "$VERSIONS_DIR"

# ---------------------------------------------------------------------------
# 2. Fetch latest release tag from GitHub API (no jq required)
# ---------------------------------------------------------------------------
echo "capytools: [2/9] fetching latest release tag ..."
API_URL="https://api.github.com/repos/$REPO/releases/latest"
TAG_RAW="$(curl -fsSL "$API_URL" | grep -m1 '"tag_name"' | cut -d'"' -f4)"

if [ -z "$TAG_RAW" ]; then
  echo "capytools: failed to fetch latest release tag from $API_URL" >&2
  exit 1
fi

# Strip leading 'v' so versions are stored as 1.1.0, not v1.1.0
LATEST="${TAG_RAW#v}"

# ---------------------------------------------------------------------------
# 3. Read currently installed version (if any)
# ---------------------------------------------------------------------------
echo "capytools: [3/9] reading installed version ..."
CURRENT_VERSION=""
if [ -f "$CONF" ]; then
  # shellcheck disable=SC1090
  source "$CONF"
fi

# Read user conf to pick up CAPY_LOCK_VERSION (and any other user overrides)
CAPY_LOCK_VERSION=""
if [ -f "$USER_CONF" ]; then
  # shellcheck disable=SC1090
  source "$USER_CONF"
fi

# Apply version lock if set — overrides the API-fetched latest
if [ -n "${CAPY_LOCK_VERSION:-}" ]; then
  echo "capytools: version lock active — pinned to $CAPY_LOCK_VERSION"
  LATEST="$CAPY_LOCK_VERSION"
fi

# ---------------------------------------------------------------------------
# 4. Idempotency check
# ---------------------------------------------------------------------------
echo "capytools: [4/9] checking version (installed: ${CURRENT_VERSION:-none}, latest: $LATEST) ..."
if [ "${CURRENT_VERSION:-}" = "$LATEST" ]; then
  echo "capytools: already on $LATEST"
  exit 0
fi

PREV_VERSION="${CURRENT_VERSION:-}"

# ---------------------------------------------------------------------------
# 5. Download and extract release tarball if version directory missing
# ---------------------------------------------------------------------------
echo "capytools: [5/9] checking for version $LATEST on disk ..."
TARGET_DIR="$VERSIONS_DIR/$LATEST"
if [ ! -d "$TARGET_DIR" ]; then
  TARBALL_URL="https://github.com/$REPO/archive/refs/tags/v${LATEST}.tar.gz"
  TMPDIR="$(mktemp -d)"
  # Ensure temp dir is cleaned up on exit
  trap 'rm -rf "$TMPDIR"' EXIT

  echo "capytools: downloading $TARBALL_URL ..."
  curl -fsSL "$TARBALL_URL" | tar -xz -C "$TMPDIR"

  # The archive extracts to capytools-<version>/ — glob for it
  EXTRACTED=""
  for d in "$TMPDIR"/capytools-*/; do
    EXTRACTED="$d"
    break
  done

  if [ -z "$EXTRACTED" ] || [ ! -d "$EXTRACTED" ]; then
    echo "capytools: could not find extracted directory in tarball" >&2
    exit 1
  fi

  mkdir -p "$TARGET_DIR"
  cp "$EXTRACTED/aliases.sh"        "$TARGET_DIR/aliases.sh"
  cp "$EXTRACTED/functions.sh"      "$TARGET_DIR/functions.sh"
  cp "$EXTRACTED/capytools.conf.env" "$TARGET_DIR/capytools.conf.env"
fi

# ---------------------------------------------------------------------------
# 6. On first install only: copy entry.sh, seed user conf, and cache install.sh
# ---------------------------------------------------------------------------
echo "capytools: [6/9] setting up entry shim and user conf ..."
if [ ! -f "$CAPYTOOLS_HOME/user-capytools.conf.env" ]; then
  touch "$CAPYTOOLS_HOME/user-capytools.conf.env"
  echo "capytools: created user-capytools.conf.env"
fi

if [ ! -f "$CAPYTOOLS_HOME/entry.sh" ]; then
  ENTRY_URL="https://raw.githubusercontent.com/$REPO/refs/tags/v${LATEST}/entry.sh"
  echo "capytools: fetching entry.sh ..."
  curl -fsSL "$ENTRY_URL" -o "$CAPYTOOLS_HOME/entry.sh"
fi

# Cache install.sh so `capytools update` can re-invoke it locally.
# Use $0 if it is a real file path; otherwise re-download.
SELF_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || true)"
if [ -f "${SELF_PATH:-}" ]; then
  cp "$SELF_PATH" "$CAPYTOOLS_HOME/install.sh"
else
  INSTALL_URL="https://raw.githubusercontent.com/$REPO/refs/tags/v${LATEST}/install.sh"
  curl -fsSL "$INSTALL_URL" -o "$CAPYTOOLS_HOME/install.sh"
fi
chmod +x "$CAPYTOOLS_HOME/install.sh"

# ---------------------------------------------------------------------------
# 7. Write conf file atomically
# ---------------------------------------------------------------------------
echo "capytools: [7/9] writing conf file ..."
CONF_TMP="$(mktemp "$CAPYTOOLS_HOME/.capytools.conf.env.XXXXXX")"
cat > "$CONF_TMP" <<EOF
CURRENT_VERSION=$LATEST
PREVIOUS_VERSION=$PREV_VERSION
EOF
mv "$CONF_TMP" "$CONF"

# ---------------------------------------------------------------------------
# 8. Append source line to ~/.bashrc on first install only
# ---------------------------------------------------------------------------
echo "capytools: [8/9] checking ~/.bashrc ..."
BASHRC_LINE='[ -f "$HOME/.capytools/entry.sh" ] && source "$HOME/.capytools/entry.sh"'
if ! grep -qF 'capytools/entry.sh' "$HOME/.bashrc" 2>/dev/null; then
  echo "" >> "$HOME/.bashrc"
  echo "# capytools" >> "$HOME/.bashrc"
  echo "$BASHRC_LINE" >> "$HOME/.bashrc"
  echo "capytools: added source line to ~/.bashrc"
fi

# ---------------------------------------------------------------------------
# 9. Final status
# ---------------------------------------------------------------------------
echo "capytools: [9/9] done."
if [ -z "$PREV_VERSION" ]; then
  echo "capytools: installed $LATEST — open a new shell or run: source ~/.bashrc"
else
  echo "capytools: updated $PREV_VERSION -> $LATEST — open a new shell or run: source ~/.bashrc"
fi
