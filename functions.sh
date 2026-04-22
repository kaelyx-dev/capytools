# capytools functions
# shellcheck shell=bash

CAPYTOOLS_VERSION="0.1.3"   # must match the git tag for this release


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
CAPY_CURRENT_VERSION=$target
CAPY_PREVIOUS_VERSION=$CURRENT_VERSION
EOF
      echo "capytools: rolled back to $target -- open a new shell to load it"
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
        echo "warning: version drift -- open a new shell or re-source entry.sh" >&2
      fi
      ;;
    lock)
      local ver="${2:-}"
      if [ -z "$ver" ]; then
        echo "capytools: usage: capytools lock <version>" >&2
        return 1
      fi
      if [[ ! "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "capytools: invalid version format '$ver' (expected X.Y.Z)" >&2
        return 1
      fi
      local user_conf="${CAPYTOOLS_HOME:-$HOME/.capytools}/user-capytools.conf.env"
      [ -f "$user_conf" ] || touch "$user_conf"
      sed -i '/^CAPY_LOCK_VERSION=/d' "$user_conf"
      echo "CAPY_LOCK_VERSION=$ver" >> "$user_conf"
      echo "capytools: locked to $ver -- run 'capytools update' to install it"
      ;;
    unlock)
      local user_conf="${CAPYTOOLS_HOME:-$HOME/.capytools}/user-capytools.conf.env"
      if [ ! -f "$user_conf" ] || ! grep -q '^CAPY_LOCK_VERSION=' "$user_conf"; then
        echo "capytools: no version lock is set"
        return 0
      fi
      sed -i '/^CAPY_LOCK_VERSION=/d' "$user_conf"
      echo "capytools: unlocked -- 'capytools update' will now fetch the latest release"
      ;;
    list)
      ls -1 "${CAPYTOOLS_HOME:-$HOME/.capytools}/versions/"
      ;;
    full-reset)
      echo "capytools: performing full reset -- this will remove all installed versions and config"
      read -p "Are you sure? (y/N) " -n 1 -r
      echo
      if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        rm -rf "${CAPYTOOLS_HOME:-$HOME/.capytools}" && curl -fsSL https://raw.githubusercontent.com/kaelyx-dev/capytools/main/install.sh | bash
        echo "capytools: reset complete"
      else
        echo "capytools: reset aborted"
      fi
      ;;
    *)
      cat <<EOF
usage: capytools {update|rollback|version|list|lock|unlock|full-reset}
  update    fetch and install the latest release
  rollback  switch CURRENT_VERSION back to PREVIOUS_VERSION
  version   show installed and currently-loaded versions
  list      list all versions installed on disk
  lock      pin updates to a specific version: capytools lock 1.2.0
  unlock    remove version pin and resume tracking latest
  full-reset  remove all installed versions and config
EOF
      ;;
  esac
}

is_config_key_set () {
  if [ -z "${!1:-}" ]; then
    echo "capytools: config key '$1' is not set" >&2
    return 1
  fi
}

get_config_value() {
  local key="$1"
  if ! is_config_key_set "$key"; then
    return 1
  fi
  echo "${!key}"
}

does_command_exist() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "capytools: command '$1' not found" >&2
    return 1
  fi
}

install_if_not_exists () {
  if ! does_command_exist "$1"; then
    echo "capytools: '$1' not found, attempting to install..."
    if does_command_exist "apt-get"; then
      sudo apt install -y "$1"
    else
      echo "capytools: no supported package manager found (apt)" >&2
      return 1
    fi
  fi
}

open () {
  if ! is_config_key_set "CAPY_VSC_PATH"; then
    echo "capytools: CAPY_VSC_PATH is not set in config" >&2
    return 1
  fi

  does_command_exist "$CAPY_VSC_PATH" || return 1

  local workspace_file
  workspace_file=$(find . -maxdepth 1 -type f -name "*.code-workspace" | head -n 1)

  if [ -n "$workspace_file" ]; then
    echo "capytools: opening workspace file '$workspace_file'"
    # shellcheck disable=SC2086
    "$CAPY_VSC_PATH" $CAPY_VSC_ARGS "$workspace_file"
    return 0
  else
    echo "capytools: no workspace file found, opening current directory"
    # shellcheck disable=SC2086
    "$CAPY_VSC_PATH" $CAPY_VSC_ARGS .
    return 0
  fi
}