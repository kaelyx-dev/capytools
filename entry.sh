# ~/.capytools/entry.sh
# Stable shim sourced from ~/.bashrc.
# This file is written once on first install and never overwritten by updates.
# shellcheck shell=bash

CAPYTOOLS_HOME="${CAPYTOOLS_HOME:-$HOME/.capytools}"
CONF="$CAPYTOOLS_HOME/capytools.conf.env"

[ -f "$CONF" ] || return 0

# shellcheck disable=SC1090
source "$CONF"

VDIR="$CAPYTOOLS_HOME/versions/$CURRENT_VERSION"
if [ -d "$VDIR" ]; then

  # System defaults first (CAPY_ prefixed, safe from pollution)
  [ -f "$VDIR/capytools.conf.env" ] && source "$VDIR/capytools.conf.env"

  # User overrides — loaded after system conf so they take precedence
  [ -f "$CAPYTOOLS_HOME/user-capytools.conf.env" ] && source "$CAPYTOOLS_HOME/user-capytools.conf.env"

  # Functions before aliases (aliases may reference functions)
  [ -f "$VDIR/functions.sh" ] && source "$VDIR/functions.sh"
  [ -f "$VDIR/aliases.sh" ]   && source "$VDIR/aliases.sh"
else
  echo "capytools: version '$CURRENT_VERSION' not installed" >&2
fi
