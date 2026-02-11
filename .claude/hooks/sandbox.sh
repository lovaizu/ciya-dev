#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# sandbox.sh - PreToolUse hook for Claude Code
#
# Enforces:
#   1. File access restricted to allowed locations
#   2. Network access restricted to allowed domains
#   3. System-destructive commands blocked
#   4. Hook self-protection
#
# Environment:
#   ALLOWED_DOMAINS_FILE - Path to allowed domains list (one per line).
#                          If unset, all network access is denied.
# ============================================================

INPUT=$(cat)
eval "$(echo "$INPUT" | jq -r '
  @sh "TOOL_NAME=\(.tool_name // "")",
  @sh "CWD=\(.cwd // "")",
  @sh "FILE_PATH=\(.tool_input.file_path // "")",
  @sh "NOTEBOOK_PATH=\(.tool_input.notebook_path // "")",
  @sh "INPUT_PATH=\(.tool_input.path // "")",
  @sh "URL_FIELD=\(.tool_input.url // "")",
  @sh "COMMAND_STR=\(.tool_input.command // "")"
')"

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
#   Allow:  resolved path is under ~/.claude/projects/ (memory directory)
#   Allow:  resolved path is under TMPDIR (defaults to /tmp)
#   Deny:   resolved path is outside all allowed locations
#
# Self-protection spec:
#   Protected paths:
#     - $REPO_ROOT/.claude/hooks/sandbox.sh  (hook script)
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

  # Allow Claude Code memory directory (~/.claude/projects)
  local claude_projects_dir="${HOME}/.claude/projects"
  if [[ "$resolved" == "$claude_projects_dir"/* || "$resolved" == "$claude_projects_dir" ]]; then
    return 0
  fi

  # Allow TMPDIR (defaults to /tmp)
  local tmp_dir
  tmp_dir=$(realpath -m "${TMPDIR:-/tmp}" 2>/dev/null) || tmp_dir="${TMPDIR:-/tmp}"
  if [[ "$resolved" == "$tmp_dir"/* || "$resolved" == "$tmp_dir" ]]; then
    return 0
  fi

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

  if [[ "$resolved" == "$REPO_ROOT/.claude/hooks/sandbox.sh" ]] ||
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
#   Deny if command string contains: .claude/hooks/sandbox.sh or .claude/settings.(json|local.json)
#   Note: best-effort pattern match; can be bypassed via encoding/indirection
#
# Destructive command spec:
#   Deny if command matches any of these patterns:
#     - Disk:     \b(mkfs|fdisk|wipefs|parted)\b
#     - Shutdown: \b(shutdown|reboot|poweroff|halt)\b
#     - Init:     \binit\s+[06]\b
#     - Firewall: \b(iptables|ip6tables|ufw)\b
#     - Root rm:  \brm\s+(-rf|-fr)\s+/($|\s|\*)  (only / and /*)
#     - Device:   \bdd\b.*\b(if|of)=/dev/
#     - Chmod:    \bchmod\s+(-R\s+)?777\s+/
#     - Chown:    \bchown\s+.*root.*\s+/
#     - Fork:     :\(\)\s*\{.*:\|:
#     - Disk IO:  >\s*/dev/(sd|hd|nvme|vd)
#   Note: word boundary match means "echo shutdown" is also denied
#         (accepted false positive for safety)
#
# Path extraction spec:
#   Steps:  1. Strip URLs (https?://...) to avoid false positives
#           2. Extract absolute paths preceded by whitespace or start of string
#              regex: (?:^|(?<=\s))/[a-zA-Z0-9_./-]+
#           3. Allow /dev/null, /dev/stdin, /dev/stdout, /dev/stderr,
#              /dev/zero, /dev/urandom, /dev/random
#           4. Check remaining paths with check_path (allowed locations)
#   Note: paths preceded by = (e.g., dd if=/dev/zero) are not extracted
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

  if echo "$cmd" | grep -qE '\.claude/hooks/sandbox\.sh|\.claude/settings\.(json|local\.json)'; then
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

  # dd with device input or output
  if echo "$cmd" | grep -qE '\bdd\b.*\b(if|of)=/dev/'; then
    deny "Destructive command denied: dd with device input/output"
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

check_bash_paths() {
  local cmd="$1"

  # Strip URLs to avoid false positives on URL path components
  local stripped
  stripped=$(echo "$cmd" | sed -E "s|https?://[^[:space:]\"']+||g")

  # Extract absolute paths preceded by whitespace or at start of string
  local paths
  paths=$(echo "$stripped" | grep -oP '(?:^|(?<=\s))/[a-zA-Z0-9_./-]+' || true)

  [[ -z "$paths" ]] && return 0

  while IFS= read -r path; do
    [[ -z "$path" ]] && continue

    # Allow common /dev/ paths used in shell commands
    case "$path" in
      /dev/null|/dev/stdin|/dev/stdout|/dev/stderr|/dev/zero|/dev/urandom|/dev/random)
        continue ;;
    esac

    check_path "$path"
  done <<< "$paths"
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
# Main dispatch — field-based extraction
#
# Spec:
#   All fields are extracted in a single jq call at script start
#   using eval + @sh for safe shell-variable assignment.
#
#   Pre-extracted variables:
#     TOOL_NAME, CWD, FILE_PATH, NOTEBOOK_PATH, INPUT_PATH,
#     URL_FIELD, COMMAND_STR
#
#   Flow:
#     1. Self-protection: for write tools, check path fields
#     2. Path check: check FILE_PATH, NOTEBOOK_PATH, INPUT_PATH
#     3. Domain check: extract domain from URL_FIELD
#        (WebSearch exempt — uses Anthropic infrastructure)
#     4. Command handling: self-protection, destructive, network
#     5. Allow
# ============================================================

# --- 1. Self-protection for write tools ---
case "$TOOL_NAME" in
  Write|Edit)
#    check_self_protection "$FILE_PATH"
    ;;
  NotebookEdit)
#    check_self_protection "$NOTEBOOK_PATH"
    ;;
esac

# --- 2. Path checks from known fields ---
[[ -n "$FILE_PATH" ]] && check_path "$FILE_PATH"
[[ -n "$NOTEBOOK_PATH" ]] && check_path "$NOTEBOOK_PATH"
[[ -n "$INPUT_PATH" ]] && check_path "$INPUT_PATH"

# --- 3. Domain checks from URL fields ---
if [[ "$TOOL_NAME" != "WebSearch" && -n "$URL_FIELD" ]]; then
  domain=$(extract_domain_from_url "$URL_FIELD")
  check_domain "$domain"
fi

# --- 4. Command field handling ---
if [[ -n "$COMMAND_STR" ]]; then
#  check_bash_self_protection "$COMMAND_STR"
  check_destructive_commands "$COMMAND_STR"
  check_bash_paths "$COMMAND_STR"
  check_bash_network "$COMMAND_STR"
fi

allow
