# SSH helper to auto-resolve Tailscale hostnames.
# Usage: tssh [ssh-options] user@tailscale-host [command]
# Example: tssh derock@goliath
tssh() {
  local args=()
  for arg in "$@"; do
    if [[ "$arg" == *@* && "$arg" != -* ]]; then
      local user="${arg%@*}"
      local host="${arg#*@}"
      local ip
      ip=$(tailscale ip -4 "$host" 2>/dev/null)
      if [[ -n "$ip" ]]; then
        args+=("${user}@${ip}")
      else
        args+=("$arg")
      fi
    else
      args+=("$arg")
    fi
  done
  ssh "${args[@]}"
}

# Autocompletion logic for the tssh function
_tssh_complete() {
    # COMP_WORDS is an array of the words on the current command line.
    # COMP_CWORD is the index of the word the cursor is on.
    # 'cur' is the current word being completed.
    local cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=() # This array holds the completion suggestions.

    # Command to get the list of unique, non-empty Tailscale hostnames.
    local hosts
    mapfile -t hosts < <(tailscale status --json | jq -r '.Peer[].HostName | select(.!="")' | sort | uniq)

    # Separate any "user@" prefix from the hostname part being completed.
    local user_prefix=""
    local host_part="$cur"
    if [[ "$cur" == *@* ]]; then
        user_prefix="${cur%@*}@" # e.g., "derock@"
        host_part="${cur#*@}"    # e.g., "lap" if typing "derock@lap"
    fi

    # Build a list of suggestions that match what the user is typing.
    local suggestions=()
    for host in "${hosts[@]}"; do
        # If the part being typed matches the beginning of a known host...
        if [[ "$host" == "$host_part"* ]]; then
            # ...add the full suggestion back, including the user prefix.
            suggestions+=("${user_prefix}${host}")
        fi
    done

    # Set the final suggestions.
    COMPREPLY=("${suggestions[@]}")
    return 0
}

# Register the completion function (_tssh_complete) for the command (tssh).
complete -F _tssh_complete tssh
