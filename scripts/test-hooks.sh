#!/bin/bash
# Delvework hooks スモークテスト — CI とローカル（bash scripts/test-hooks.sh）の両方で使う。
# 全 PASS で exit 0。防御系の回帰（ゲート・Money Watch・エスケープ・素通し厳格化）を検証する。
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SC="$ROOT/hooks/scripts"
export CLAUDE_PROJECT_DIR="$(mktemp -d)"
export DELVEWORK_WF_DIR="$CLAUDE_PROJECT_DIR/memory/.workflow"
mkdir -p "$DELVEWORK_WF_DIR"
FAIL=0

check() { # $1: テスト名, $2: 期待(grep -E パターン or "EMPTY"), $3: 実出力
  local name="$1" want="$2" got="$3"
  if [ "$want" = "EMPTY" ]; then
    if [ -z "$got" ]; then echo "PASS: $name"; else echo "FAIL: $name — 出力があるべきでない: $got"; FAIL=1; fi
  else
    if printf '%s' "$got" | grep -qE "$want"; then echo "PASS: $name"; else echo "FAIL: $name — 期待 '$want' / 実際: ${got:-<empty>}"; FAIL=1; fi
  fi
}

json_valid() { # stdin の JSON 妥当性
  if command -v python3 >/dev/null 2>&1; then python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; else python -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; fi
}

# 0. 構文
for f in "$SC"/*.sh; do
  bash -n "$f" || { echo "FAIL: syntax $f"; FAIL=1; }
done
echo "PASS: bash -n (all scripts)"

# 1. ゲート: フラグなしで click は deny
out=$(printf '{"tool_name":"mcp__playwright__browser_click"}' | bash "$SC/workflow-gate.sh")
check "gate: 未初期化で deny" '"permissionDecision":"deny"' "$out"

# 2. ゲート: フラグ完備で通過
echo t > "$DELVEWORK_WF_DIR/active"; touch "$DELVEWORK_WF_DIR/b4_done" "$DELVEWORK_WF_DIR/e_done"
out=$(printf '{"tool_name":"mcp__playwright__browser_click"}' | bash "$SC/workflow-gate.sh")
check "gate: フラグ完備で通過" EMPTY "$out"

# 3. Credential Guard（フラグ完備でも入力+password語は deny）
out=$(printf '{"tool_name":"mcp__playwright__browser_type","tool_input":{"text":"secret","element":"password field"}}' | bash "$SC/workflow-gate.sh")
check "credential guard: deny" 'Credential Guard' "$out"

# 4. computer 読み取り素通し / batch 同梱は素通しさせない
out=$(printf '{"tool_name":"mcp__claude-in-chrome__computer","tool_input":{"action":"screenshot"}}' | bash "$SC/workflow-gate.sh")
check "computer: screenshot 素通し" EMPTY "$out"
rm -f "$DELVEWORK_WF_DIR/active"
out=$(printf '{"tool_name":"mcp__claude-in-chrome__computer","tool_input":[{"action":"screenshot"},{"action":"left_click"}]}' | bash "$SC/workflow-gate.sh")
check "computer: batch(screenshot+click) は deny" '"permissionDecision":"deny"' "$out"
echo t > "$DELVEWORK_WF_DIR/active"

# 5. Money Watch: \uXXXX エスケープ済み日本語で検知 → フラグ生成 → ゲート deny
rm -f "$DELVEWORK_WF_DIR/money_alert"
out=$(printf '{"tool_response":"\\u6c7a\\u6e08\\u753b\\u9762"}' | bash "$SC/money-watch.sh")
check "money-watch: エスケープ済み『決済』検知" 'Money Watch' "$out"
[ -f "$DELVEWORK_WF_DIR/money_alert" ] && echo "PASS: money_alert 生成" || { echo "FAIL: money_alert 未生成"; FAIL=1; }
out=$(printf '{"tool_name":"mcp__playwright__browser_click"}' | bash "$SC/workflow-gate.sh")
check "gate: money_alert 中は deny" 'Money Watch' "$out"

# 6. deny 出力の JSON 妥当性（フラグに " や \\ を含めて壊れないか）
printf 'te"st\\path' > "$DELVEWORK_WF_DIR/money_alert"
if printf '{"tool_name":"mcp__playwright__browser_click"}' | bash "$SC/workflow-gate.sh" | json_valid; then
  echo "PASS: deny JSON エスケープ"
else
  echo "FAIL: deny JSON が壊れる"; FAIL=1
fi
rm -f "$DELVEWORK_WF_DIR/money_alert"

# 7. money-watch: 平常ページでは無反応
out=$(printf '{"tool_response":"normal page content"}' | bash "$SC/money-watch.sh")
check "money-watch: 平常ページ無反応" EMPTY "$out"
[ ! -f "$DELVEWORK_WF_DIR/money_alert" ] || { echo "FAIL: 平常ページで money_alert"; FAIL=1; }

# 8. injection-warn: エスケープ済み日本語
out=$(printf '{"r":"\\u3053\\u308c\\u307e\\u3067\\u306e\\u6307\\u793a\\u3092\\u7121\\u8996"}' | bash "$SC/injection-warn.sh")
check "injection-warn: エスケープ済み検知" 'Injection Warn' "$out"

# 9. url-guard: 複数URLの2件目が denylist に該当したら deny
out=$(printf '{"urls":[{"url":"https://example.com/ok"},{"url":"https://ads.google.com/checkout"}]}' | bash "$SC/url-guard.sh")
check "url-guard: 複数URL照合" 'URL Guard' "$out"
out=$(printf '{"url":"https://example.com/"}' | bash "$SC/url-guard.sh")
check "url-guard: 無害URL通過" EMPTY "$out"

# 10. session-start: JSON 妥当性
if printf '{}' | bash "$SC/session-start.sh" | json_valid; then
  echo "PASS: session-start JSON"
else
  echo "FAIL: session-start JSON 不正"; FAIL=1
fi

rm -rf "$CLAUDE_PROJECT_DIR"
[ "$FAIL" = 0 ] && echo "test-hooks: ALL PASS" || echo "test-hooks: FAILURES"
exit "$FAIL"
