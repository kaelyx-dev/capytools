alias capyhi='echo "hello from capytools"'
alias capyhome='cd "$CAPYTOOLS_HOME"'

# Command Line Management
alias c='clear'

# Directory Traversal

for i in {1..6}; do
  dots=$(printf '%*s' "$i" | tr ' ' '.')
  path=$(printf '../%.0s' $(seq 1 "$i"))
  alias "$dots"="cd $path"
done

alias back='cd -'
alias home='cd ~'
alias root='cd /'

# Networking 
alias ports="sudo lsof -i -P -n | grep LISTEN"