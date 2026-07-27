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

# 4b. browser_batch: 読み取り専用は未初期化でも素通し / 変更系同梱は deny / money_alert 中は deny
rm -f "$DELVEWORK_WF_DIR/active"
out=$(printf '{"tool_name":"mcp__claude-in-chrome__browser_batch","tool_input":{"invocations":[{"name":"read_page"},{"name":"get_page_text"}]}}' | bash "$SC/workflow-gate.sh")
check "batch: 読み取り専用は素通し" EMPTY "$out"
out=$(printf '{"tool_name":"mcp__claude-in-chrome__browser_batch","tool_input":{"invocations":[{"name":"read_page"},{"name":"mcp__claude-in-chrome__computer","input":{"action":"left_click"}}]}}' | bash "$SC/workflow-gate.sh")
check "batch: 変更系同梱は deny" '"permissionDecision":"deny"' "$out"
printf 'x' > "$DELVEWORK_WF_DIR/money_alert"
out=$(printf '{"tool_name":"mcp__claude-in-chrome__browser_batch","tool_input":{"invocations":[{"name":"read_page"}]}}' | bash "$SC/workflow-gate.sh")
check "batch: money_alert 中は読み取り専用でも deny（Money Watch が先）" 'Money Watch' "$out"
rm -f "$DELVEWORK_WF_DIR/money_alert"
echo t > "$DELVEWORK_WF_DIR/active"

# 5b. deny 文言に解除コマンドが含まれない（レビュー指摘a: 突破誘導の除去）
printf 'x' > "$DELVEWORK_WF_DIR/money_alert"
out=$(printf '{"tool_name":"mcp__playwright__browser_click"}' | bash "$SC/workflow-gate.sh")
if printf '%s' "$out" | grep -q 'rm memory'; then
  echo "FAIL: money deny 文言に rm コマンドが残存"; FAIL=1
else
  echo "PASS: money deny 文言に解除コマンドなし"
fi
rm -f "$DELVEWORK_WF_DIR/money_alert"

# 5. Money Watch【強】: \uXXXX エスケープ済み日本語で検知 → フラグ生成 → ゲート deny
# ペイロードは『購入を確定』（動詞つきの確定表現＝強パターン）
rm -f "$DELVEWORK_WF_DIR/money_alert"
out=$(printf '{"tool_response":"\\u8cfc\\u5165\\u3092\\u78ba\\u5b9a"}' | bash "$SC/money-watch.sh")
check "money-watch【強】: エスケープ済み『購入を確定』検知" 'Money Watch' "$out"
[ -f "$DELVEWORK_WF_DIR/money_alert" ] && echo "PASS: money_alert 生成" || { echo "FAIL: money_alert 未生成"; FAIL=1; }
out=$(printf '{"tool_name":"mcp__playwright__browser_click"}' | bash "$SC/workflow-gate.sh")
check "gate: money_alert 中は deny" 'Money Watch' "$out"

# 5b. Money Watch【弱】: ナビ語は注意喚起のみで停止しない（2026-07-27 過剰ゲート監査の回帰）
# ペイロードは『決済画面』。以前はこれで money_alert が立ち、媒体の管理画面を開いた時点で
# 定常タスクが毎回停止していた（解除に strategy-advisor + ユーザー承認が必要）。
rm -f "$DELVEWORK_WF_DIR/money_alert"
out=$(printf '{"tool_response":"\\u6c7a\\u6e08\\u753b\\u9762"}' | bash "$SC/money-watch.sh")
check "money-watch【弱】: 『決済』は注意喚起のみ" 'Money Watch・注意' "$out"
[ ! -f "$DELVEWORK_WF_DIR/money_alert" ] || { echo "FAIL: 弱パターンで money_alert が立った（過剰ゲート再発）"; FAIL=1; }
out=$(printf '{"tool_name":"mcp__playwright__browser_click"}' | bash "$SC/workflow-gate.sh")
check "gate: 弱検知の後も変更操作は通る" EMPTY "$out"

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

# 9b. 検証モード（verify_allowlist）: リスト外は deny・リスト内は通過・フラグ削除後は平常
printf 'example\\.com\nthe-internet\\.herokuapp\\.com\n' > "$DELVEWORK_WF_DIR/verify_allowlist"
out=$(printf '{"url":"https://en.wikipedia.org/wiki/Password"}' | bash "$SC/url-guard.sh")
check "verify-allowlist: リスト外は deny" '検証モード・許可サイト限定' "$out"
out=$(printf '{"url":"https://the-internet.herokuapp.com/login"}' | bash "$SC/url-guard.sh")
check "verify-allowlist: リスト内は通過" EMPTY "$out"
rm -f "$DELVEWORK_WF_DIR/verify_allowlist"
out=$(printf '{"url":"https://en.wikipedia.org/wiki/Password"}' | bash "$SC/url-guard.sh")
check "verify-allowlist: フラグ削除後は平常動作" EMPTY "$out"

# 10. session-start: JSON 妥当性
if printf '{}' | bash "$SC/session-start.sh" | json_valid; then
  echo "PASS: session-start JSON"
else
  echo "FAIL: session-start JSON 不正"; FAIL=1
fi

# --- psv_done ゲート（一括送出の監査強制） ---
echo t > "$DELVEWORK_WF_DIR/active"; touch "$DELVEWORK_WF_DIR/b4_done" "$DELVEWORK_WF_DIR/e_done"
rm -f "$DELVEWORK_WF_DIR/money_alert"
touch "$DELVEWORK_WF_DIR/bulk_send"
out=$(printf '{"tool_name":"mcp__playwright__browser_click","tool_input":{"element":"send button"}}' | bash "$SC/workflow-gate.sh")
check "psv: bulk_send中はpsv_doneまでdeny" 'pre-send-verifier' "$out"
touch "$DELVEWORK_WF_DIR/psv_done"
out=$(printf '{"tool_name":"mcp__playwright__browser_click","tool_input":{"element":"send button"}}' | bash "$SC/workflow-gate.sh")
check "psv: psv_done後は通過" EMPTY "$out"
rm -f "$DELVEWORK_WF_DIR/bulk_send" "$DELVEWORK_WF_DIR/psv_done"

# --- OV Gate（不可逆送出の outcome-verifier 強制） ---
export DELVEWORK_GATE_MODE=deny
rm -f "$DELVEWORK_WF_DIR/bulk_send" "$DELVEWORK_WF_DIR/ov_done"
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"touch memory/.workflow/k_done"}}' | bash "$SC/ov-gate.sh")
check "ov: bulk_sendなしは素通し" EMPTY "$out"
touch "$DELVEWORK_WF_DIR/bulk_send"
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"touch memory/.workflow/k_done"}}' | bash "$SC/ov-gate.sh")
check "ov: bulk_sendあり・ov_doneなしは deny" 'OV Gate' "$out"
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"rm -f memory/.workflow/{b4_done,e_done,k_done,bulk_send,psv_done} && touch memory/.workflow/active"}}' | bash "$SC/ov-gate.sh")
check "ov: 初期化rmは誤爆しない" EMPTY "$out"
echo "VERIFIED 3/3" > "$DELVEWORK_WF_DIR/ov_done"
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"touch memory/.workflow/k_done"}}' | bash "$SC/ov-gate.sh")
check "ov: ov_doneありは通過" EMPTY "$out"
export DELVEWORK_GATE_MODE=warn
rm -f "$DELVEWORK_WF_DIR/ov_done"
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"touch memory/.workflow/k_done"}}' | bash "$SC/ov-gate.sh")
check "ov: 既定warnモードは注入のみ（denyしない）" 'additionalContext.*OV Gate' "$out"
rm -f "$DELVEWORK_WF_DIR/bulk_send"

# --- RM Guard（一括・再帰削除の機械ガード） ---
export DELVEWORK_GATE_MODE=deny
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"rm -rf outputs/"}}' | bash "$SC/rm-guard.sh")
check "rm-guard: rm -rf は deny" 'RM Guard' "$out"
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"rm outputs/*.png"}}' | bash "$SC/rm-guard.sh")
check "rm-guard: グロブ一括は deny" 'RM Guard' "$out"
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"find outputs -name \\"*.tmp\\" -delete"}}' | bash "$SC/rm-guard.sh")
check "rm-guard: find -delete は deny" 'RM Guard' "$out"
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"git clean -fd"}}' | bash "$SC/rm-guard.sh")
check "rm-guard: git clean は deny" 'RM Guard' "$out"
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"rm outputs/v10-test.html"}}' | bash "$SC/rm-guard.sh")
check "rm-guard: 個別ファイルrmは通過" EMPTY "$out"
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"rm -f memory/.workflow/{b4_done,e_done,k_done} && touch memory/.workflow/active"}}' | bash "$SC/rm-guard.sh")
check "rm-guard: .workflowフラグ掃除は通過" EMPTY "$out"
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"rm memory/.workflow/verify_*"}}' | bash "$SC/rm-guard.sh")
check "rm-guard: .workflow内グロブは通過" EMPTY "$out"
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"ls outputs/"}}' | bash "$SC/rm-guard.sh")
check "rm-guard: rmなしコマンドは通過" EMPTY "$out"
export DELVEWORK_GATE_MODE=warn
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"rm -rf outputs/"}}' | bash "$SC/rm-guard.sh")
check "rm-guard: warnモードは注入のみ" 'additionalContext.*RM Guard' "$out"
unset DELVEWORK_GATE_MODE

# --- Critic Gate（artisan生成物の critic PASS 強制） ---
export DELVEWORK_GATE_MODE=deny
rm -f "$DELVEWORK_WF_DIR/critic_pending" "$DELVEWORK_WF_DIR/critic_pass"
out=$(printf '{"tool_name":"SendUserFile","tool_input":{"files":["banner.png"]}}' | bash "$SC/critic-gate.sh")
check "critic: pendingなしは素通し" EMPTY "$out"
touch "$DELVEWORK_WF_DIR/critic_pending"
out=$(printf '{"tool_name":"SendUserFile","tool_input":{"files":["banner.png"]}}' | bash "$SC/critic-gate.sh")
check "critic: pending中のPNG送付は deny" 'Critic Gate' "$out"
out=$(printf '{"tool_name":"SendUserFile","tool_input":{"files":["report.md"]}}' | bash "$SC/critic-gate.sh")
check "critic: pending中でもmdは素通し" EMPTY "$out"
mkdir -p "$CLAUDE_PROJECT_DIR/knowledge/config"
printf 'qa-.*\\.png\n' > "$CLAUDE_PROJECT_DIR/knowledge/config/critic-suppress.txt"
out=$(printf '{"tool_name":"SendUserFile","tool_input":{"files":["qa-1.png"]}}' | bash "$SC/critic-gate.sh")
check "critic: 抑制リスト該当は通過" EMPTY "$out"
rm -f "$CLAUDE_PROJECT_DIR/knowledge/config/critic-suppress.txt"
echo "PASS: layout OK" > "$DELVEWORK_WF_DIR/critic_pass"
out=$(printf '{"tool_name":"SendUserFile","tool_input":{"files":["banner.png"]}}' | bash "$SC/critic-gate.sh")
check "critic: critic_pass後は通過" EMPTY "$out"
rm -f "$DELVEWORK_WF_DIR/critic_pending" "$DELVEWORK_WF_DIR/critic_pass"

# Critic Gate 対象スコープ（2026-07-27 過剰ゲート監査の回帰）:
# critic_pending に対象パターンが書かれていれば、それ以外のビジュアル送付は巻き込まない
printf 'banner-v2' > "$DELVEWORK_WF_DIR/critic_pending"
out=$(printf '{"tool_name":"SendUserFile","tool_input":{"files":["banner-v2.png"]}}' | bash "$SC/critic-gate.sh")
check "critic: スコープ内（対象ファイル）は deny" 'Critic Gate' "$out"
out=$(printf '{"tool_name":"SendUserFile","tool_input":{"files":["debug-screenshot.png"]}}' | bash "$SC/critic-gate.sh")
check "critic: スコープ外の無関係画像は巻き込まない" EMPTY "$out"
rm -f "$DELVEWORK_WF_DIR/critic_pending"
unset DELVEWORK_GATE_MODE

# --- deny 文言に実行可能な出口があるか（2026-07-27 過剰ゲート監査） ---
# 承認を求めるだけで実行経路の無い deny は、AI が「承認 → やはり不可」を往復して進まなくなる
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"rm -rf outputs/"}}' | bash "$SC/rm-guard.sh")
check "rm-guard: deny 文言に出口（ユーザー自身の実行／残置報告）がある" 'ユーザー自身の手で実行|残置' "$out"
touch "$DELVEWORK_WF_DIR/bulk_send"; rm -f "$DELVEWORK_WF_DIR/ov_done"
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"touch memory/.workflow/k_done"}}' | bash "$SC/ov-gate.sh")
check "ov: deny 文言に送出ゼロの出口（NO_SEND）がある" 'NO_SEND' "$out"
rm -f "$DELVEWORK_WF_DIR/bulk_send"

# --- session-start: 残留フラグの通知（2026-07-27 過剰ゲート監査） ---
printf 'x' > "$DELVEWORK_WF_DIR/money_alert"
printf 'example\\.com' > "$DELVEWORK_WF_DIR/verify_allowlist"
out=$(bash "$SC/session-start.sh")
check "session-start: 残留フラグを通知" '残留フラグ' "$out"
check "session-start: 残留通知に verify_allowlist を含む" 'verify_allowlist' "$out"
printf '%s' "$out" | json_valid && echo "PASS: session-start 残留通知 JSON" || { echo "FAIL: session-start 残留通知 JSON が壊れる"; FAIL=1; }
rm -f "$DELVEWORK_WF_DIR/money_alert" "$DELVEWORK_WF_DIR/verify_allowlist"
out=$(bash "$SC/session-start.sh")
printf '%s' "$out" | grep -q '残留フラグ' && { echo "FAIL: 残留なしでも通知が出る（誤爆）"; FAIL=1; } || echo "PASS: 残留なしでは通知しない"

rm -rf "$CLAUDE_PROJECT_DIR"
[ "$FAIL" = 0 ] && echo "test-hooks: ALL PASS" || echo "test-hooks: FAILURES"
exit "$FAIL"

