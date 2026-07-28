#!/bin/bash
# Delvework Hook — shared functions (Cowork / Linux VM compatible)
# ワークスペースのパスは CLAUDE_PROJECT_DIR から解決する（絶対パス直書き禁止）

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
WF_DIR="${DELVEWORK_WF_DIR:-$PROJECT_DIR/memory/.workflow}"

# Capture stdin (hook payload JSON) for input inspection
STDIN_JSON="$(cat 2>/dev/null || true)"

# STDIN_TEXT: ツール結果JSONは日本語が \uXXXX エスケープで来ることがあり、そのままでは
# 日本語パターン（決済/クレジットカード等）が一切マッチしない（Money Watch がサイレント無効化）。
# 日本語照合は必ず STDIN_TEXT に対して行うこと。perl → python3 → python の順で試し、無ければ生のまま。
if command -v perl >/dev/null 2>&1; then
  # pack("U") で \uXXXX を UTF-8 バイト列に展開する。-CO は使わない（既存の生UTF-8バイトを二重エンコードして壊すため）
  STDIN_TEXT="$(printf '%s' "$STDIN_JSON" | perl -pe 's/\\u([0-9a-fA-F]{4})/pack("U",hex($1))/ge' 2>/dev/null)"
elif command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
  PY="$(command -v python3 || command -v python)"
  STDIN_TEXT="$(printf '%s' "$STDIN_JSON" | "$PY" -c 'import sys,re; sys.stdout.write(re.sub(r"\\\\u([0-9a-fA-F]{4})", lambda m: chr(int(m.group(1),16)), sys.stdin.read()))' 2>/dev/null)"
fi
[ -n "$STDIN_TEXT" ] || STDIN_TEXT="$STDIN_JSON"

# JSON文字列へ埋め込む値のエスケープ（ページ/URL由来文字列で hook 出力JSONが壊れる=フェイルオープンを防ぐ）
json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr -d '\000-\037'
}

deny() {
  local msg; msg="$(json_escape "$1")"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$msg"
  exit 0
}

# --- deny 文言の減衰（2026-07-28 コンテキスト管理監査） ---
# 停止フラグが残っている間、同じ長文 deny を毎ツールコール再送すると
# コンテキストが理由文で埋まる（1回で伝わる情報を N 回払う）。
# 同一理由の deny が DENY_FULL_MAX 回を超えたら、以降は1行の短縮版だけ返す。
# カウンタは $WF_DIR/.deny_<reason>。理由が変わったら他の理由のカウンタを消す（=リセット）。
# フラグ解除でゲートを通り抜けたときは deny_reset で全カウンタを消す。
# session-start.sh も起動時に消す（セッションをまたいで減衰状態を持ち越さない）。
DENY_FULL_MAX="${DELVEWORK_DENY_FULL_MAX:-2}"

deny_reset() {
  rm -f "$WF_DIR"/.deny_* 2>/dev/null
  return 0
}

deny_decay() { # $1: 理由コード（英数_）, $2: フル文言, $3: 短縮文言（1行）
  local reason="$1" full="$2" short="$3" f other cnt=1
  mkdir -p "$WF_DIR" 2>/dev/null
  f="$WF_DIR/.deny_$reason"
  for other in "$WF_DIR"/.deny_*; do
    [ -e "$other" ] || continue
    [ "$other" = "$f" ] || rm -f "$other" 2>/dev/null
  done
  if [ -f "$f" ]; then
    cnt="$(head -c 8 "$f" 2>/dev/null | tr -dc '0-9')"
    [ -n "$cnt" ] || cnt=0
    cnt=$((cnt + 1))
  fi
  printf '%s' "$cnt" > "$f" 2>/dev/null
  if [ "$cnt" -gt "$DENY_FULL_MAX" ] && [ -n "$short" ]; then
    deny "$short"
  else
    deny "$full"
  fi
}

warn_pretool() {
  local msg; msg="$(json_escape "$1")"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}' "$msg"
  exit 0
}

warn_posttool() {
  local msg; msg="$(json_escape "$1")"
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}' "$msg"
  exit 0
}

warn_session() {
  local msg; msg="$(json_escape "$1")"
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$msg"
  exit 0
}
