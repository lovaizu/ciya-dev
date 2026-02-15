#!/usr/bin/env bash
# Tests for notify.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

passed=0
failed=0

assert_eq() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $test_name"
    ((++passed))
  else
    echo "  FAIL: $test_name"
    echo "    expected: $expected"
    echo "    actual:   $actual"
    ((++failed))
  fi
}

assert_contains() {
  local test_name="$1"
  local needle="$2"
  local haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "  PASS: $test_name"
    ((++passed))
  else
    echo "  FAIL: $test_name"
    echo "    expected to contain: $needle"
    echo "    actual:              $haystack"
    ((++failed))
  fi
}

# Source notify.sh — the guard prevents notify_main from running
source "$SCRIPT_DIR/notify.sh"

# ── escape_for_xml ───────────────────────────────────────────────
echo "escape_for_xml:"

assert_eq "ampersand" '&amp;' "$(escape_for_xml '&')"
assert_eq "less than" '&lt;' "$(escape_for_xml '<')"
assert_eq "greater than" '&gt;' "$(escape_for_xml '>')"
assert_eq "double quote" '&quot;' "$(escape_for_xml '"')"
assert_eq "single quote" '&apos;' "$(escape_for_xml "'")"
assert_eq "plain text unchanged" 'hello world' "$(escape_for_xml 'hello world')"
assert_eq "mixed special chars" '&lt;b&gt;a &amp; b&lt;/b&gt;' "$(escape_for_xml '<b>a & b</b>')"

# ── parse_json_value ─────────────────────────────────────────────
echo "parse_json_value:"

json='{"hook_event_name": "Stop", "cwd": "/home/user/project", "message": "hello world"}'
assert_eq "extract hook_event_name" "Stop" "$(parse_json_value "$json" "hook_event_name")"
assert_eq "extract cwd" "/home/user/project" "$(parse_json_value "$json" "cwd")"
assert_eq "extract message" "hello world" "$(parse_json_value "$json" "message")"
assert_eq "missing key returns empty" "" "$(parse_json_value "$json" "nonexistent")"

json_notification='{"hook_event_name": "Notification", "notification_type": "permission_prompt", "message": "Claude needs your permission to use Bash"}'
assert_eq "extract notification_type" "permission_prompt" "$(parse_json_value "$json_notification" "notification_type")"
assert_eq "extract notification message" "Claude needs your permission to use Bash" "$(parse_json_value "$json_notification" "message")"

# ── get_repo_info ────────────────────────────────────────────────
echo "get_repo_info:"

repo_info=$(get_repo_info ".")
assert_contains "contains colon separator" ":" "$repo_info"
expected_repo=$(basename -s .git "$(git remote get-url origin 2>/dev/null)" 2>/dev/null || basename "$(pwd)")
assert_contains "contains repo name" "$expected_repo" "$repo_info"

# ── send_notification (non-WSL) ──────────────────────────────────
echo "send_notification:"

if ! command -v powershell.exe &>/dev/null; then
  send_notification "Test Title" "Test Message"
  assert_eq "exits silently without powershell.exe" "0" "$?"
  echo "  (skipping actual toast — powershell.exe not available)"
fi

# Override send_notification to capture arguments for integration tests
notification_title=""
notification_message=""
send_notification() {
  notification_title="$1"
  notification_message="$2"
}

# ── Integration: Stop event ──────────────────────────────────────
echo "integration (Stop):"

# Given: clean notification state
notification_title=""
notification_message=""
# When: Stop event is received
notify_main <<< '{"hook_event_name": "Stop", "cwd": "."}'
# Then: title and message reflect completion
assert_eq "title" "Claude Code - Complete" "$notification_title"
assert_contains "message contains repo info" "$expected_repo:" "$notification_message"
assert_contains "message contains Agent finished" "Agent finished" "$notification_message"

# ── Integration: Notification (permission_prompt) ────────────────
echo "integration (Notification - permission_prompt):"

# Given: clean notification state
notification_title=""
notification_message=""
# When: permission_prompt notification is received
notify_main <<< '{"hook_event_name": "Notification", "notification_type": "permission_prompt", "message": "Claude needs your permission to use Bash", "cwd": "."}'
# Then: title shows action required, message contains the detail
assert_eq "title" "Claude Code - Action Required" "$notification_title"
assert_contains "message contains repo info" "$expected_repo:" "$notification_message"
assert_contains "message contains detail" "Claude needs your permission to use Bash" "$notification_message"

# ── Integration: Notification (empty message fallback) ───────────
echo "integration (Notification - empty message):"

# Given: clean notification state
notification_title=""
notification_message=""
# When: notification with empty message is received
notify_main <<< '{"hook_event_name": "Notification", "notification_type": "permission_prompt", "message": "", "cwd": "."}'
# Then: message falls back to default text
assert_eq "title" "Claude Code - Action Required" "$notification_title"
assert_contains "message fallback" "Waiting for your input" "$notification_message"

# ── Integration: Unknown event ───────────────────────────────────
echo "integration (unknown event):"

# Given: clean notification state
notification_title=""
notification_message=""
# When: unknown event type is received
notify_main <<< '{"hook_event_name": "CustomEvent", "cwd": "."}'
# Then: generic title with event name in message
assert_eq "title" "Claude Code" "$notification_title"
assert_contains "message contains event name" "CustomEvent" "$notification_message"

# ── Message truncation ───────────────────────────────────────────
echo "message truncation:"

# Given: a message exceeding 200 characters
long_message=$(printf 'x%.0s' $(seq 1 250))
notification_title=""
notification_message=""
# When: notification with long message is received
notify_main <<< "{\"hook_event_name\": \"Notification\", \"message\": \"$long_message\", \"cwd\": \".\"}"
# Then: message is truncated to 220 characters or less
if [[ ${#notification_message} -le 220 ]]; then
  echo "  PASS: message truncated (length=${#notification_message})"
  ((++passed))
else
  echo "  FAIL: message not truncated (length=${#notification_message})"
  ((++failed))
fi

# ── Summary ──────────────────────────────────────────────────────
echo ""
echo "Results: $passed passed, $failed failed"

if [[ $failed -gt 0 ]]; then
  exit 1
fi
