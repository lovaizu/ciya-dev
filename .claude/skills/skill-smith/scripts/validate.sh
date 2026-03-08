#!/usr/bin/env bash
#
# Skill structural validation for skill-smith Evaluate mode.
# Pure bash — no Python dependency.
#
# Usage: bash scripts/validate.sh <skill_folder_path>
# Output: JSON report to stdout, summary to stderr.

set -uo pipefail

# ── Helpers ──

RESULTS="[]"
PASS_COUNT=0 FAIL_COUNT=0 WARN_COUNT=0 SKIP_COUNT=0

add_result() {
  local id="$1" cat="$2" check="$3" verdict="$4" evidence="$5" fix="${6:-null}"
  [[ "$fix" != "null" ]] && fix="\"$fix\""
  RESULTS=$(printf '%s' "$RESULTS" | sed 's/]$//')
  [[ "$RESULTS" != "[" ]] && RESULTS="${RESULTS},"
  RESULTS="${RESULTS}{\"id\":\"$id\",\"category\":\"$cat\",\"check\":\"$check\",\"verdict\":\"$verdict\",\"evidence\":\"$evidence\",\"fix\":$fix}]"
  case "$verdict" in
    PASS) PASS_COUNT=$((PASS_COUNT + 1)) ;;
    FAIL) FAIL_COUNT=$((FAIL_COUNT + 1)) ;;
    WARN) WARN_COUNT=$((WARN_COUNT + 1)) ;;
    SKIP) SKIP_COUNT=$((SKIP_COUNT + 1)) ;;
  esac
}

pass() { add_result "$1" "$2" "$3" "PASS" "$4"; }
fail() { add_result "$1" "$2" "$3" "FAIL" "$4" "$5"; }
warn() { add_result "$1" "$2" "$3" "WARN" "$4" "${5:-}"; }
skip() { add_result "$1" "$2" "$3" "SKIP" "$4"; }

to_kebab() {
  echo "$1" | sed -E 's/([A-Z])/-\L\1/g; s/[^a-z0-9-]/-/g; s/-+/-/g; s/^-//; s/-$//'
}

# ── Main ──

if [[ $# -ne 1 ]]; then
  echo "Usage: bash scripts/validate.sh <skill_folder_path>" >&2
  exit 1
fi

SKILL_DIR="$(cd "$1" && pwd)"
FOLDER_NAME="$(basename "$SKILL_DIR")"

# ── S-01: SKILL.md exists ──
if [[ -f "$SKILL_DIR/SKILL.md" ]]; then
  pass "S-01" "structure" "SKILL.md exists" "Found"
else
  variant=$(find "$SKILL_DIR" -maxdepth 1 -iname "skill.md" -print -quit 2>/dev/null)
  if [[ -n "$variant" ]]; then
    fail "S-01" "structure" "SKILL.md exists" "Found '$(basename "$variant")' but must be exactly SKILL.md" "Rename to SKILL.md"
  else
    fail "S-01" "structure" "SKILL.md exists" "Not found" "Create SKILL.md"
  fi
  # Can't continue without SKILL.md
  printf '{"skill_path":"%s","skill_name":"%s","results":{"total":%d,"passed":%d,"failed":%d,"warned":%d,"skipped":%d},"grade":"F","details":%s}\n' \
    "$SKILL_DIR" "$FOLDER_NAME" 1 "$PASS_COUNT" "$FAIL_COUNT" "$WARN_COUNT" "$SKIP_COUNT" "$RESULTS"
  exit 1
fi

# ── S-02: Folder name is kebab-case ──
if echo "$FOLDER_NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
  pass "S-02" "structure" "Folder kebab-case" "$FOLDER_NAME"
else
  fail "S-02" "structure" "Folder kebab-case" "$FOLDER_NAME" "Rename to $(to_kebab "$FOLDER_NAME")"
fi

# ── S-04: No README.md ──
if [[ -f "$SKILL_DIR/README.md" ]]; then
  fail "S-04" "structure" "No README.md" "Found README.md" "Remove — docs go in SKILL.md or references/"
else
  pass "S-04" "structure" "No README.md" "Correct"
fi

# ── S-05: Standard directories only ──
EXPECTED_DIRS="scripts references assets evals"
UNEXPECTED=""
for d in "$SKILL_DIR"/*/; do
  [[ ! -d "$d" ]] && continue
  dname="$(basename "$d")"
  [[ "$dname" == .* ]] && continue
  if ! echo "$EXPECTED_DIRS" | grep -qw "$dname"; then
    UNEXPECTED="${UNEXPECTED}${dname} "
  fi
done
if [[ -z "$UNEXPECTED" ]]; then
  pass "S-05" "structure" "Standard dirs only" "OK"
else
  warn "S-05" "structure" "Standard dirs only" "Unexpected: ${UNEXPECTED% }" "Move to references/ or remove"
fi

# ── S-06: No auxiliary docs ──
AUX_FOUND=""
for f in INSTALLATION_GUIDE.md CHANGELOG.md CONTRIBUTING.md SETUP.md; do
  [[ -f "$SKILL_DIR/$f" ]] && AUX_FOUND="${AUX_FOUND}${f} "
done
if [[ -z "$AUX_FOUND" ]]; then
  pass "S-06" "structure" "No auxiliary docs" "Clean"
else
  warn "S-06" "structure" "No auxiliary docs" "Found: ${AUX_FOUND% }" "Move to references/ or remove"
fi

# ── Parse frontmatter ──
CONTENT="$(cat "$SKILL_DIR/SKILL.md")"
FIRST_LINE="$(head -1 "$SKILL_DIR/SKILL.md")"

# F-01: Delimiters
if [[ "$FIRST_LINE" != "---" ]]; then
  fail "F-01" "frontmatter" "Delimiters" "No opening ---" "Add --- delimiters"
  # Output partial report and exit
  TOTAL=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT + SKIP_COUNT))
  printf '{"skill_path":"%s","skill_name":"%s","results":{"total":%d,"passed":%d,"failed":%d,"warned":%d,"skipped":%d},"grade":"F","details":%s}\n' \
    "$SKILL_DIR" "$FOLDER_NAME" "$TOTAL" "$PASS_COUNT" "$FAIL_COUNT" "$WARN_COUNT" "$SKIP_COUNT" "$RESULTS"
  exit 1
fi

# Extract frontmatter (between first and second ---)
FRONTMATTER="$(sed -n '2,/^---$/{ /^---$/d; p; }' "$SKILL_DIR/SKILL.md")"
if [[ -z "$FRONTMATTER" ]]; then
  fail "F-01" "frontmatter" "Delimiters" "No closing ---" "Add closing ---"
  TOTAL=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT + SKIP_COUNT))
  printf '{"skill_path":"%s","skill_name":"%s","results":{"total":%d,"passed":%d,"failed":%d,"warned":%d,"skipped":%d},"grade":"F","details":%s}\n' \
    "$SKILL_DIR" "$FOLDER_NAME" "$TOTAL" "$PASS_COUNT" "$FAIL_COUNT" "$WARN_COUNT" "$SKIP_COUNT" "$RESULTS"
  exit 1
fi
pass "F-01" "frontmatter" "Delimiters" "Valid"

# F-02: Valid YAML (basic: check key: value structure)
# We check that every non-empty, non-comment line either starts a key or is a continuation
YAML_OK=true
while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  # Allow key: value, key:, or indented continuation (metadata sub-keys)
  if ! echo "$line" | grep -qE '^[a-zA-Z_-]+:' && ! echo "$line" | grep -qE '^[[:space:]]'; then
    YAML_OK=false
    break
  fi
done <<< "$FRONTMATTER"

if $YAML_OK; then
  pass "F-02" "frontmatter" "Valid YAML" "OK"
else
  fail "F-02" "frontmatter" "Valid YAML" "Malformed line: $line" "Fix YAML syntax"
  TOTAL=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT + SKIP_COUNT))
  printf '{"skill_path":"%s","skill_name":"%s","results":{"total":%d,"passed":%d,"failed":%d,"warned":%d,"skipped":%d},"grade":"F","details":%s}\n' \
    "$SKILL_DIR" "$FOLDER_NAME" "$TOTAL" "$PASS_COUNT" "$FAIL_COUNT" "$WARN_COUNT" "$SKIP_COUNT" "$RESULTS"
  exit 1
fi

# ── Extract fields ──
# name: extract first match (handles single-line value)
NAME="$(echo "$FRONTMATTER" | grep -E '^name:' | head -1 | sed 's/^name:[[:space:]]*//' | tr -d '"'"'")"

# description: may be single-line or multi-line
# Strategy: grab from "description:" to the next top-level key or end
DESC="$(echo "$FRONTMATTER" | sed -n '/^description:/,/^[a-zA-Z_-]*:/{ /^description:/{ s/^description:[[:space:]]*//; p; d; }; /^[a-zA-Z_-]*:/d; p; }' | tr '\n' ' ' | sed 's/[[:space:]]*$//' | tr -d '"'"'")"

# F-03: name exists
if [[ -n "$NAME" ]]; then
  pass "F-03" "frontmatter" "name exists" "$NAME"
else
  fail "F-03" "frontmatter" "name exists" "Missing" "Add name field"
fi

# F-04: name is kebab-case
if [[ -n "$NAME" ]]; then
  if echo "$NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$' && [[ ${#NAME} -le 64 ]]; then
    pass "F-04" "frontmatter" "name kebab-case" "$NAME (${#NAME} chars)"
  else
    fail "F-04" "frontmatter" "name kebab-case" "$NAME" "Use $(to_kebab "$NAME" | cut -c1-64)"
  fi
fi

# S-03: Folder matches name
if [[ -n "$NAME" ]]; then
  if [[ "$NAME" == "$FOLDER_NAME" ]]; then
    pass "S-03" "structure" "Folder = name" "Both $FOLDER_NAME"
  else
    fail "S-03" "structure" "Folder = name" "Folder '$FOLDER_NAME' != name '$NAME'" "Align names"
  fi
fi

# F-05: name not reserved
if [[ -n "$NAME" ]]; then
  NAME_LOWER="$(echo "$NAME" | tr '[:upper:]' '[:lower:]')"
  if echo "$NAME_LOWER" | grep -qE 'claude|anthropic'; then
    fail "F-05" "frontmatter" "name not reserved" "$NAME contains reserved word" "Remove claude/anthropic"
  else
    pass "F-05" "frontmatter" "name not reserved" "OK"
  fi
fi

# F-06: description exists
if [[ -n "$DESC" ]]; then
  DESC_LEN=${#DESC}
  pass "F-06" "frontmatter" "description exists" "${DESC_LEN} chars"
else
  fail "F-06" "frontmatter" "description exists" "Missing" "Add description with WHAT + WHEN"
fi

if [[ -n "$DESC" ]]; then
  # F-07: description length
  if [[ $DESC_LEN -le 1024 ]]; then
    pass "F-07" "frontmatter" "description <= 1024" "$DESC_LEN chars"
  else
    fail "F-07" "frontmatter" "description <= 1024" "$DESC_LEN chars" "Shorten to <= 1024"
  fi

  # F-08: No XML
  if echo "$DESC" | grep -q '[<>]'; then
    fail "F-08" "frontmatter" "No XML in desc" "Found < or >" "Remove angle brackets"
  else
    pass "F-08" "frontmatter" "No XML in desc" "Clean"
  fi

  # D-01: WHAT stated
  DESC_LOWER="$(echo "$DESC" | tr '[:upper:]' '[:lower:]')"
  HAS_VAGUE=false
  for v in "helps with" "assists with" "does things" "handles stuff"; do
    echo "$DESC_LOWER" | grep -q "$v" && HAS_VAGUE=true
  done
  HAS_VERB=false
  for v in creates generates manages analyzes builds converts processes extracts formats deploys \
           monitors validates orchestrates automates transforms produces audits evaluates improves \
           create generate manage analyze build convert perform; do
    echo "$DESC_LOWER" | grep -qw "$v" && HAS_VERB=true && break
  done

  if $HAS_VERB && ! $HAS_VAGUE; then
    pass "D-01" "description" "WHAT stated" "Concrete function verbs found"
  elif $HAS_VAGUE; then
    fail "D-01" "description" "WHAT stated" "Vague language" "Use concrete verbs"
  else
    warn "D-01" "description" "WHAT stated" "No clear function verbs detected"
  fi

  # D-02: WHEN stated
  HAS_WHEN=false
  for kw in "use when" "use for" "use this" "trigger" "use if" "also use"; do
    echo "$DESC_LOWER" | grep -q "$kw" && HAS_WHEN=true && break
  done
  if $HAS_WHEN; then
    pass "D-02" "description" "WHEN stated" "Trigger conditions found"
  else
    fail "D-02" "description" "WHEN stated" "No trigger conditions" "Add: Use when user says ..."
  fi

  # D-03: Natural trigger phrases (count quoted strings — handle escaped quotes too)
  PHRASE_COUNT=$(echo "$DESC" | grep -oE '("|\\")[^"\\]{3,}("|\\")' | wc -l)
  if [[ $PHRASE_COUNT -lt 2 ]]; then
    # Also try matching the raw frontmatter line for escaped quotes
    RAW_DESC="$(sed -n '/^description:/,/^[a-zA-Z_-]*:/{ /^description:/{ s/^description:[[:space:]]*//; p; d; }; /^[a-zA-Z_-]*:/d; p; }' "$SKILL_DIR/SKILL.md" | tr '\n' ' ')"
    PHRASE_COUNT=$(echo "$RAW_DESC" | grep -oE '\\"[^\\]{3,}\\"' | wc -l)
    [[ $PHRASE_COUNT -lt 2 ]] && PHRASE_COUNT=$(echo "$RAW_DESC" | grep -oE '"[^"]{3,}"' | wc -l)
  fi
  if [[ $PHRASE_COUNT -ge 2 ]]; then
    pass "D-03" "description" "Natural phrases >= 2" "${PHRASE_COUNT} found"
  elif [[ $PHRASE_COUNT -eq 1 ]]; then
    warn "D-03" "description" "Natural phrases >= 2" "Only 1 found" "Add more quoted phrases"
  else
    warn "D-03" "description" "Natural phrases >= 2" "None found" "Add quoted user phrases"
  fi
fi

# F-09: Allowed properties only
ALLOWED_KEYS="name description license allowed-tools metadata compatibility"
BAD_KEYS=""
while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^[[:space:]] || "$line" =~ ^# ]] && continue
  key="$(echo "$line" | cut -d: -f1 | tr -d ' ')"
  if ! echo "$ALLOWED_KEYS" | grep -qw "$key"; then
    BAD_KEYS="${BAD_KEYS}${key} "
  fi
done <<< "$FRONTMATTER"

if [[ -z "$BAD_KEYS" ]]; then
  pass "F-09" "frontmatter" "Allowed props only" "OK"
else
  fail "F-09" "frontmatter" "Allowed props only" "Unexpected: ${BAD_KEYS% }" "Remove or move to metadata"
fi

# F-10: compatibility length
COMPAT="$(echo "$FRONTMATTER" | grep -E '^compatibility:' | head -1 | sed 's/^compatibility:[[:space:]]*//')"
if [[ -n "$COMPAT" ]]; then
  if [[ ${#COMPAT} -le 500 ]]; then
    pass "F-10" "frontmatter" "compat <= 500" "${#COMPAT} chars"
  else
    fail "F-10" "frontmatter" "compat <= 500" "${#COMPAT} chars" "Shorten"
  fi
else
  skip "F-10" "frontmatter" "compat <= 500" "Not present"
fi

# ── Instruction metrics ──
# Body = everything after second ---
BODY="$(awk 'c>=2; /^---$/{c++}' "$SKILL_DIR/SKILL.md")"
BODY_LINES="$(echo "$BODY" | wc -l)"
BODY_WORDS="$(echo "$BODY" | wc -w)"

# I-05: Size
if [[ $BODY_LINES -le 500 ]]; then
  pass "I-05" "instruction" "Size <= 500 lines" "${BODY_LINES} lines"
elif [[ $BODY_LINES -le 1000 ]]; then
  warn "I-05" "instruction" "Size <= 500 lines" "${BODY_LINES} lines" "Move details to references/"
else
  fail "I-05" "instruction" "Size <= 500 lines" "${BODY_LINES} lines" "Split into references/"
fi

# I-07: MUST density
MUST_COUNT=$(echo "$BODY" | grep -owE '\b(MUST|ALWAYS|NEVER|CRITICAL|IMPORTANT)\b' | wc -l)
if [[ $MUST_COUNT -eq 0 ]]; then
  pass "I-07" "instruction" "MUST density" "No mandatory keywords"
elif [[ $BODY_WORDS -gt 0 ]]; then
  DENSITY=$((BODY_WORDS / MUST_COUNT))
  if [[ $DENSITY -ge 200 ]]; then
    pass "I-07" "instruction" "MUST density" "${MUST_COUNT} in ${BODY_WORDS}w (1/${DENSITY}w)"
  else
    warn "I-07" "instruction" "MUST density" "${MUST_COUNT} in ${BODY_WORDS}w (1/${DENSITY}w)" "Explain WHY instead"
  fi
fi

# ── Security ──
SCRIPTS_DIR="$SKILL_DIR/scripts"
if [[ -d "$SCRIPTS_DIR" ]]; then
  DANGER_FOUND=false
  while IFS= read -r -d '' sf; do
    sfname="$(basename "$sf")"
    [[ "$sfname" == "validate.sh" ]] && continue
    # Only scan actual script files
    case "$sfname" in
      *.py|*.sh|*.js|*.ts|*.rb|*.pl) : ;;
      *) continue ;;
    esac
    for pattern in 'rm[[:space:]]+\-rf[[:space:]]+/' '\bsudo\b' 'curl.*-d[[:space:]]*@' 'wget.*[|].*sh'; do
      if grep -qlE "$pattern" "$sf" 2>/dev/null; then
        REL="$(realpath --relative-to="$SKILL_DIR" "$sf")"
        warn "SEC-02" "security" "No dangerous ops" "Pattern in $REL" "Review"
        DANGER_FOUND=true
      fi
    done
  done < <(find "$SCRIPTS_DIR" -type f -print0)  # LCOV_EXCL_LINE — kcov cannot trace process substitution on done
  $DANGER_FOUND || pass "SEC-02" "security" "No dangerous ops" "Clean"
else
  skip "SEC-02" "security" "No dangerous ops" "No scripts/"
fi

# SEC-03: Hardcoded secrets
SECRET_FOUND=false
while IFS= read -r -d '' f; do
  case "$f" in
    *.py|*.sh|*.js|*.ts|*.json|*.yaml|*.yml|*.env)
      for pat in 'api[_-]\?key.*[:=].*["'"'"'][^"'"'"']\{10,\}' 'sk-[a-zA-Z0-9]\{20,\}' 'xoxb-[a-zA-Z0-9-]\+'; do
        if grep -ql "$pat" "$f" 2>/dev/null; then
          REL="$(realpath --relative-to="$SKILL_DIR" "$f")"
          fail "SEC-03" "security" "No secrets" "Possible secret in $REL" "Use environment variables"
          SECRET_FOUND=true
          break 2
        fi
      done
      ;;
  esac
done < <(find "$SKILL_DIR" -type f -print0)
$SECRET_FOUND || pass "SEC-03" "security" "No secrets" "Clean"

# ── Grade ──
TOTAL=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT + SKIP_COUNT))

# Collect fail IDs
FAIL_IDS=""
for entry in $(echo "$RESULTS" | grep -o '"id":"[^"]*","category":"[^"]*","check":"[^"]*","verdict":"FAIL"' | grep -o '"id":"[^"]*"' | sed 's/"id":"//;s/"//'); do
  FAIL_IDS="$FAIL_IDS $entry"
done

GRADE="A"
if echo "$FAIL_IDS" | grep -qE 'S-01|F-01|F-02|F-03|F-06'; then
  GRADE="F"
elif echo "$FAIL_IDS" | grep -qE 'D-01|D-02|D-03|I-01|I-02'; then
  GRADE="D"
elif [[ $FAIL_COUNT -gt 2 ]]; then
  GRADE="C"
elif [[ $FAIL_COUNT -gt 0 ]]; then
  GRADE="C"
elif [[ $WARN_COUNT -gt 3 ]]; then
  GRADE="B"
fi

# ── Output JSON ──
cat <<EOF
{
  "skill_path": "$SKILL_DIR",
  "skill_name": "$FOLDER_NAME",
  "results": { "total": $TOTAL, "passed": $PASS_COUNT, "failed": $FAIL_COUNT, "warned": $WARN_COUNT, "skipped": $SKIP_COUNT },
  "grade": "$GRADE",
  "details": $RESULTS
}
EOF

# ── Summary to stderr ──
echo "========================================" >&2
echo "Grade: $GRADE  |  PASS: $PASS_COUNT  FAIL: $FAIL_COUNT  WARN: $WARN_COUNT  SKIP: $SKIP_COUNT" >&2

echo "$RESULTS" | grep -o '{[^}]*"verdict":"FAIL"[^}]*}' | while IFS= read -r entry; do
  eid=$(echo "$entry" | grep -o '"id":"[^"]*"' | sed 's/"id":"//;s/"//')
  echk=$(echo "$entry" | grep -o '"check":"[^"]*"' | sed 's/"check":"//;s/"//')
  eev=$(echo "$entry" | grep -o '"evidence":"[^"]*"' | sed 's/"evidence":"//;s/"//')
  echo "  FAIL [$eid] $echk: $eev" >&2
done

echo "$RESULTS" | grep -o '{[^}]*"verdict":"WARN"[^}]*}' | while IFS= read -r entry; do
  eid=$(echo "$entry" | grep -o '"id":"[^"]*"' | sed 's/"id":"//;s/"//')
  echk=$(echo "$entry" | grep -o '"check":"[^"]*"' | sed 's/"check":"//;s/"//')
  eev=$(echo "$entry" | grep -o '"evidence":"[^"]*"' | sed 's/"evidence":"//;s/"//')
  echo "  WARN [$eid] $echk: $eev" >&2
done

[[ "$GRADE" == "A" || "$GRADE" == "B" ]]
