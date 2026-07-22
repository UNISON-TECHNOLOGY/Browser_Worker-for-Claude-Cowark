#!/bin/bash
# Delvework Hook — shared functions (Cowork / Linux VM compatible)
# ワークスペースのパスは CLAUDE_PROJECT_DIR から解決する（絶対パス直書き禁止）

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
WF_DIR="${DELVEWORK_WF_DIR:-$PROJECT_DIR/memory/.workflow}"

# Consume stdin to prevent blocking
cat > /dev/null &

deny() {
  local msg="$1"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$msg"
  exit 0
}

warn_pretool() {
  local msg="$1"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}' "$msg"
  exit 0
}

warn_session() {
  local msg="$1"
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$msg"
  exit 0
}
