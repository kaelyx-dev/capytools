# capytools functions
# shellcheck shell=bash

CAPYTOOLS_VERSION="0.1.0"   # must match the git tag for this release

capytools() {
  local conf="${CAPYTOOLS_HOME:-$HOME/.capytools}/capytools.conf.env"
  case "${1:-}" in
    update)
      bash "${CAPYTOOLS_HOME:-$HOME/.capytools}/install.sh"
      ;;
    rollback)
      [ -f "$conf" ] || { echo "capytools: no conf file found" >&2; return 1; }
      # shellcheck disable=SC1090
      source "$conf"
      if [ -z "${PREVIOUS_VERSION:-}" ]; then
        echo "capytools: no previous version to roll back to" >&2
        return 1
      fi
      local target="$PREVIOUS_VERSION"
      if [ ! -d "${CAPYTOOLS_HOME:-$HOME/.capytools}/versions/$target" ]; then
        echo "capytools: previous version $target not installed on disk" >&2
        return 1
      fi
      cat > "$conf" <<EOF
CURRENT_VERSION=$target
PREVIOUS_VERSION=$CURRENT_VERSION
EOF
      echo "capytools: rolled back to $target — open a new shell to load it"
      ;;
    version)
      [ -f "$conf" ] || { echo "capytools: no conf file found" >&2; return 1; }
      # shellcheck disable=SC1090
      source "$conf"
      local user_conf="${CAPYTOOLS_HOME:-$HOME/.capytools}/user-capytools.conf.env"
      CAPY_LOCK_VERSION=""
      # shellcheck disable=SC1090
      [ -f "$user_conf" ] && source "$user_conf"
      echo "installed: $CURRENT_VERSION"
      echo "loaded:    $CAPYTOOLS_VERSION"
      if [ -n "${CAPY_LOCK_VERSION:-}" ]; then
        echo "locked:    $CAPY_LOCK_VERSION"
      fi
      if [ "$CURRENT_VERSION" != "$CAPYTOOLS_VERSION" ]; then
        echo "warning: version drift — open a new shell or re-source entry.sh" >&2
      fi
      ;;
    lock)
      local ver="${2:-}"
      if [ -z "$ver" ]; then
        echo "capytools: usage: capytools lock <version>" >&2
        return 1
      fi
      local user_conf="${CAPYTOOLS_HOME:-$HOME/.capytools}/user-capytools.conf.env"
      [ -f "$user_conf" ] || touch "$user_conf"
      sed -i '/^CAPY_LOCK_VERSION=/d' "$user_conf"
      echo "CAPY_LOCK_VERSION=$ver" >> "$user_conf"
      echo "capytools: locked to $ver — run 'capytools update' to install it"
      ;;
    unlock)
      local user_conf="${CAPYTOOLS_HOME:-$HOME/.capytools}/user-capytools.conf.env"
      if [ ! -f "$user_conf" ] || ! grep -q '^CAPY_LOCK_VERSION=' "$user_conf"; then
        echo "capytools: no version lock is set"
        return 0
      fi
      sed -i '/^CAPY_LOCK_VERSION=/d' "$user_conf"
      echo "capytools: unlocked — 'capytools update' will now fetch the latest release"
      ;;
    list)
      ls -1 "${CAPYTOOLS_HOME:-$HOME/.capytools}/versions/"
      ;;
    *)
      cat <<EOF
usage: capytools {update|rollback|version|list|lock|unlock}
  update    fetch and install the latest release
  rollback  switch CURRENT_VERSION back to PREVIOUS_VERSION
  version   show installed and currently-loaded versions
  list      list all versions installed on disk
  lock      pin updates to a specific version: capytools lock 1.2.0
  unlock    remove version pin and resume tracking latest
EOF
      ;;
  esac
}
