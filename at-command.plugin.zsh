# at-command oh-my-zsh plugin
#
# Transforms natural language requests into executable shell commands
# using Claude Code. The generated command is placed in the zsh buffer
# for review before execution.
#
# Usage: @ <your natural language request>
# Example: @ list all jpg files larger than 5mb
#
# Requirements:
#   - Claude Code CLI (`claude`) must be installed and authenticated
#
# Configuration:
#   AT_COMMAND_MODEL   Claude model to use (default: haiku)
#   AT_COMMAND_PROMPT  Path to system prompt file (default: ~/.at_prompt)

# Default configuration
: ${AT_COMMAND_MODEL:=haiku}
: ${AT_COMMAND_PROMPT:="${HOME}/.at_prompt"}

# Default system prompt written on first use if none exists
_at_command_default_prompt() {
  cat <<'EOF'
Convert the user's natural language request into a single executable shell command.
Rules:
- The command must be a single line
- Do not execute the command
- Use syntax and flags native to the specified platform and shell — prefer platform-native tools (e.g. on macOS use BSD variants, on Linux use GNU variants)
EOF
}

# Ensure the system prompt file exists — run once at plugin load time, then clean up
if [[ ! -f "${AT_COMMAND_PROMPT}" ]]; then
  _at_command_default_prompt > "${AT_COMMAND_PROMPT}"
  echo "[at-command] Created default system prompt at ${AT_COMMAND_PROMPT}" >&2
fi
unfunction _at_command_default_prompt

# In interactive shells, intercept Enter when the line starts with "@ " so that
# the raw buffer text is passed to _at_command before zsh parses it — this means
# apostrophes, $vars, !, and other special characters work without escaping.
# Falls through to normal accept-line for all other input.
if [[ -o interactive ]]; then
  _at_command_accept_line() {
    if [[ "$BUFFER" == "@ "* ]]; then
      local request="${BUFFER#@ }"
      print -s "$BUFFER"  # add the @ ... line to history
      BUFFER=""
      echo
      _at_command "$request"
    else
      zle .accept-line
    fi
  }
  zle -N accept-line _at_command_accept_line
fi

# Fallback alias for non-interactive use (noglob prevents glob expansion)
alias @='noglob _at_command'

_at_command() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: @ <natural language request>"
    echo "Example: @ list all jpg files larger than 5mb"
    return 1
  fi

  if ! command -v claude &>/dev/null; then
    echo "[at-command] Error: 'claude' CLI not found. Install Claude Code first." >&2
    return 1
  fi

  if ! command -v jq &>/dev/null; then
    echo "[at-command] Error: 'jq' not found. Install it (e.g. brew install jq)." >&2
    return 1
  fi

  # Strip prompt-delimiter tags from user input to prevent injection
  local request="${${${*}//<end>/}//<request>/}"
  local system_prompt
  system_prompt=$(cat "${AT_COMMAND_PROMPT}")

  # Detect platform and shell dynamically
  local platform
  case "$(uname -s)" in
    Darwin) platform="macOS" ;;
    Linux)  platform="Linux" ;;
    *)      platform="$(uname -s)" ;;
  esac
  local shell_name="${SHELL##*/}"

  local context="Platform: ${platform}\nShell: ${shell_name}\n\n"

  local schema='{"type":"object","properties":{"command":{"type":"string"}},"required":["command"]}'

  local cmd json claude_status stderr_content stderr_file
  stderr_file=$(mktemp) || { echo "[at-command] Failed to create temp file." >&2; return 1; }

  # The always{} block runs on normal exit, errors, and signals (Ctrl+C),
  # guaranteeing the terminal is restored and the temp file is removed.
  {
    printf "⏳ thinking... "
    json=$(claude -p --model "${AT_COMMAND_MODEL}" \
      --output-format json \
      --json-schema "$schema" \
      "${context}${system_prompt} <request>${request}<end>" 2>"${stderr_file}")
    claude_status=$?
    cmd=$(printf '%s' "$json" | jq -r '.structured_output.command // empty')
  } always {
    printf "\r\033[K"
    stderr_content=$(cat "${stderr_file}" 2>/dev/null)
    rm -f "${stderr_file}"
  }

  if [[ -z "$cmd" ]] || (( claude_status != 0 )); then
    echo "[at-command] No command generated." >&2
    if [[ -n "$stderr_content" ]]; then
      echo "$stderr_content" >&2
    elif (( claude_status != 0 )); then
      echo "[at-command] claude exited with status ${claude_status}. Check your authentication." >&2
    else
      echo "[at-command] Check your Claude Code authentication." >&2
    fi
    return 1
  fi

  # Push command into zsh line editor buffer for review before execution.
  # Inside a ZLE widget, set BUFFER directly; otherwise use print -z (input stack).
  if [[ -n "$WIDGET" ]]; then
    BUFFER="$cmd"
    zle redisplay
  else
    print -z "$cmd"
  fi
}
