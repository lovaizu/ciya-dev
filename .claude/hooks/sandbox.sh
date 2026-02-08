#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# sandbox.sh - PreToolUse hook for Claude Code
#
# Enforces:
#   1. File access restricted to repository
#   2. Network access restricted to allowed domains
#   3. System-destructive commands blocked
#   4. Hook self-protection
#
# Environment:
#   ALLOWED_DOMAINS_FILE - Path to allowed domains list (one per line).
#                          If unset, all network access is denied.
# ============================================================

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
CWD=$(echo "$INPUT" | jq -r '.cwd')

REPO_ROOT=$(cd "$CWD" && git rev-parse --show-toplevel 2>/dev/null) || {
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Cannot determine repository root"}}' >&1
  exit 0
}

# ============================================================
# Decision helpers
# ============================================================

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

ask() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

allow() {
  exit 0
}

# ============================================================
# Path checks
#
# Spec:
#   Input:  file path string (absolute or relative to CWD)
#   Steps:  1. If relative, prepend CWD
#           2. Canonicalize with realpath -m (resolves .. and symlinks
#              for existing components; does not require path to exist)
#   Allow:  resolved path == REPO_ROOT or starts with REPO_ROOT/
#   Deny:   resolved path is outside REPO_ROOT
#
# Self-protection spec:
#   Protected paths:
#     - $REPO_ROOT/.claude/hooks/*   (hook scripts)
#     - $REPO_ROOT/.claude/settings.json
#     - $REPO_ROOT/.claude/settings.local.json
#   Deny:   Write/Edit/NotebookEdit targeting protected paths
#   Allow:  Read targeting protected paths (read-only access is safe)
# ============================================================

check_path() {
  local path="$1"
  [[ -z "$path" ]] && return 0

  # Resolve relative paths against CWD
  [[ "$path" != /* ]] && path="$CWD/$path"

  local resolved
  resolved=$(realpath -m "$path" 2>/dev/null) || resolved="$path"

  if [[ "$resolved" != "$REPO_ROOT"/* && "$resolved" != "$REPO_ROOT" ]]; then
    deny "File access outside repository denied: $resolved"
  fi
}

check_self_protection() {
  local path="$1"
  [[ -z "$path" ]] && return 0

  [[ "$path" != /* ]] && path="$CWD/$path"

  local resolved
  resolved=$(realpath -m "$path" 2>/dev/null) || resolved="$path"

  if [[ "$resolved" == "$REPO_ROOT/.claude/hooks"* ]] ||
     [[ "$resolved" == "$REPO_ROOT/.claude/settings.json" ]] ||
     [[ "$resolved" == "$REPO_ROOT/.claude/settings.local.json" ]]; then
    deny "Self-protection: modification of hook configuration denied: $resolved"
  fi
}

# ============================================================
# Network checks
#
# Domain list spec:
#   Source: $ALLOWED_DOMAINS_FILE environment variable
#   Format: one domain per line, # comments, empty lines ignored
#   If ALLOWED_DOMAINS_FILE is unset or file not found: deny all
#
# Domain matching spec:
#   - Case-insensitive comparison
#   - Exact match: "github.com" matches "github.com"
#   - Subdomain match: "api.github.com" matches entry "github.com"
#   - Non-subdomain prefix does NOT match: "notgithub.com" does NOT
#     match "github.com" (requires "." before the entry)
#
# URL domain extraction spec:
#   Input:  URL string (e.g., https://user:pass@host:port/path)
#   Steps:  1. Strip protocol (scheme://)
#           2. Strip path (everything after first /)
#           3. Strip credentials (everything before last @)
#           4. Strip port (everything after first :)
#   Output: hostname string
# ============================================================

load_allowed_domains() {
  if [[ -z "${ALLOWED_DOMAINS_FILE:-}" ]]; then
    return 1
  fi
  if [[ ! -f "$ALLOWED_DOMAINS_FILE" ]]; then
    return 1
  fi
  return 0
}

is_domain_allowed() {
  local domain="$1"
  [[ -z "$domain" ]] && return 1

  domain=$(echo "$domain" | tr '[:upper:]' '[:lower:]')

  while IFS= read -r entry || [[ -n "$entry" ]]; do
    [[ -z "$entry" || "$entry" =~ ^[[:space:]]*# ]] && continue
    entry=$(echo "$entry" | tr '[:upper:]' '[:lower:]' | xargs)
    [[ -z "$entry" ]] && continue

    if [[ "$domain" == "$entry" ]] || [[ "$domain" == *".$entry" ]]; then
      return 0
    fi
  done < "$ALLOWED_DOMAINS_FILE"

  return 1
}

extract_domain_from_url() {
  local url="$1"
  local rest="${url#*://}"
  rest="${rest%%/*}"
  rest="${rest##*@}"
  rest="${rest%%:*}"
  echo "$rest"
}

check_domain() {
  local domain="$1"

  if ! load_allowed_domains; then
    deny "Network access denied: ALLOWED_DOMAINS_FILE is not set or file not found"
  fi

  if ! is_domain_allowed "$domain"; then
    deny "Network access denied: domain '$domain' is not in the allowed list"
  fi
}

# ============================================================
# Bash-specific checks
#
# Self-protection spec:
#   Deny if command string contains: .claude/(hooks|settings.(json|local.json))
#   Note: best-effort pattern match; can be bypassed via encoding/indirection
#
# Destructive command spec:
#   Deny if command matches any of these patterns:
#     - Disk:     \b(mkfs|fdisk|wipefs|parted)\b
#     - Shutdown: \b(shutdown|reboot|poweroff|halt)\b
#     - Init:     \binit\s+[06]\b
#     - Firewall: \b(iptables|ip6tables|ufw)\b
#     - Root rm:  \brm\s+(-rf|-fr)\s+/($|\s|\*)  (only / and /*)
#     - Device:   \bdd\b.*\bif=/dev/
#     - Chmod:    \bchmod\s+(-R\s+)?777\s+/
#     - Chown:    \bchown\s+.*root.*\s+/
#     - Fork:     :\(\)\s*\{.*:\|:
#     - Disk IO:  >\s*/dev/(sd|hd|nvme|vd)
#   Note: word boundary match means "echo shutdown" is also denied
#         (accepted false positive for safety)
#
# Network command spec:
#   Trigger: command contains \b(curl|wget|ssh|scp|rsync|nc|ncat|
#            netcat|telnet)\b or \bgit\s+clone\b
#   Domain extraction:
#     - URLs:  grep for https?://... and extract domain
#     - Hosts: grep for user@host patterns (ssh/scp/rsync)
#   Decision:
#     - Domain found + in allowed list:     allow
#     - Domain found + NOT in allowed list: deny
#     - No domain extractable:             ask (passthrough to user)
#     - ALLOWED_DOMAINS_FILE unset:        deny
# ============================================================

check_bash_self_protection() {
  local cmd="$1"

  if echo "$cmd" | grep -qE '\.claude/(hooks|settings\.(json|local\.json))'; then
    deny "Self-protection: Bash command targets hook configuration"
  fi
}

check_destructive_commands() {
  local cmd="$1"

  # Disk partitioning / formatting
  if echo "$cmd" | grep -qE '\b(mkfs|fdisk|wipefs|parted)\b'; then
    deny "Destructive command denied: disk partitioning/formatting"
  fi

  # System shutdown / reboot
  if echo "$cmd" | grep -qE '\b(shutdown|reboot|poweroff|halt)\b'; then
    deny "Destructive command denied: system shutdown/reboot"
  fi

  # Init level change
  if echo "$cmd" | grep -qE '\binit\s+[06]\b'; then
    deny "Destructive command denied: system init level change"
  fi

  # Firewall modification
  if echo "$cmd" | grep -qE '\b(iptables|ip6tables|ufw)\b'; then
    deny "Destructive command denied: firewall modification"
  fi

  # rm -rf / or rm -rf /*
  if echo "$cmd" | grep -qE '\brm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)\s+/(\s|$|\*)'; then
    deny "Destructive command denied: recursive force delete at root level"
  fi

  # dd with device input
  if echo "$cmd" | grep -qE '\bdd\b.*\bif=/dev/'; then
    deny "Destructive command denied: dd with device input"
  fi

  # chmod 777 on absolute paths
  if echo "$cmd" | grep -qE '\bchmod\s+(-R\s+)?777\s+/'; then
    deny "Destructive command denied: chmod 777 on absolute path"
  fi

  # chown root on absolute paths
  if echo "$cmd" | grep -qE '\bchown\s+.*root.*\s+/'; then
    deny "Destructive command denied: chown to root on absolute path"
  fi

  # Fork bomb
  if echo "$cmd" | grep -qE ':\(\)\s*\{.*:\|:'; then
    deny "Destructive command denied: fork bomb"
  fi

  # Overwrite disk devices
  if echo "$cmd" | grep -qE '>\s*/dev/(sd|hd|nvme|vd)'; then
    deny "Destructive command denied: overwrite disk device"
  fi
}

check_bash_network() {
  local cmd="$1"

  # Network command keywords
  local net_cmds='curl|wget|ssh|scp|rsync|nc|ncat|netcat|telnet'

  local has_net_cmd=false
  if echo "$cmd" | grep -qE "\b($net_cmds)\b"; then
    has_net_cmd=true
  fi
  # git clone with URL
  if echo "$cmd" | grep -qE '\bgit\s+clone\b'; then
    has_net_cmd=true
  fi

  [[ "$has_net_cmd" == false ]] && return 0

  # Network command detected - need domain list
  if ! load_allowed_domains; then
    deny "Network access denied: ALLOWED_DOMAINS_FILE is not set or file not found"
  fi

  # Extract domains from URLs (http:// or https://)
  local url_domains
  url_domains=$(echo "$cmd" | grep -oP 'https?://[^/\s"'\'']+' | while read -r url; do
    extract_domain_from_url "$url"
  done 2>/dev/null || true)

  # Extract host from user@host patterns (ssh, scp, rsync)
  local ssh_hosts
  ssh_hosts=$(echo "$cmd" | grep -oP '(?<=@)[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?\.[a-zA-Z]{2,}' 2>/dev/null || true)

  # Combine all found domains
  local all_domains
  all_domains=$(printf '%s\n%s' "$url_domains" "$ssh_hosts" | sort -u | sed '/^$/d')

  if [[ -z "$all_domains" ]]; then
    ask "Network command detected but target domain could not be determined. Please verify."
    return 0
  fi

  while IFS= read -r domain; do
    [[ -z "$domain" ]] && continue
    if ! is_domain_allowed "$domain"; then
      deny "Network access denied: domain '$domain' is not in the allowed list"
    fi
  done <<< "$all_domains"
}

# ============================================================
# Main dispatch
#
# Spec:
#   Write/Edit:    self-protection → path check → allow
#   Read:          path check → allow
#   NotebookEdit:  self-protection → path check → allow
#   Glob/Grep:     path check on .path param (if present) → allow
#   WebFetch:      extract domain from .url → domain check → allow
#   WebSearch:     allow (uses Anthropic infrastructure, no direct fetch)
#   Bash:          self-protection → destructive check → network check → allow
#   Other tools:   allow
# ============================================================

case "$TOOL_NAME" in
  Write|Edit)
    file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    check_self_protection "$file_path"
    check_path "$file_path"
    allow
    ;;

  Read)
    file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    check_path "$file_path"
    allow
    ;;

  NotebookEdit)
    file_path=$(echo "$INPUT" | jq -r '.tool_input.notebook_path // empty')
    check_self_protection "$file_path"
    check_path "$file_path"
    allow
    ;;

  Glob)
    path=$(echo "$INPUT" | jq -r '.tool_input.path // empty')
    [[ -n "$path" ]] && check_path "$path"
    allow
    ;;

  Grep)
    path=$(echo "$INPUT" | jq -r '.tool_input.path // empty')
    [[ -n "$path" ]] && check_path "$path"
    allow
    ;;

  WebFetch)
    url=$(echo "$INPUT" | jq -r '.tool_input.url // empty')
    if [[ -n "$url" ]]; then
      domain=$(extract_domain_from_url "$url")
      check_domain "$domain"
    fi
    allow
    ;;

  WebSearch)
    # WebSearch goes through Anthropic's infrastructure
    allow
    ;;

  Bash)
    command_str=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
    check_bash_self_protection "$command_str"
    check_destructive_commands "$command_str"
    check_bash_network "$command_str"
    allow
    ;;

  *)
    allow
    ;;
esac
