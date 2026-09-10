#!/bin/bash
# Delvework Hook — shared functions (Cowork / Linux VM compatible)
# ワークスペースのパスは CLAUDE_PROJECT_DIR から解決する（絶対パス直書き禁止）

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
WF_DIR="${DELVEWORK_WF_DIR:-$PROJECT_DIR/memory/.workflow}"

# Capture stdin (hook payload JSON) for input inspection
STDIN_JSON="$(cat 2>/dev/null || true)"

# STDIN_TEXT: ツール結果JSONは日本語が \uXXXX エスケープで来ることがあり、そのままでは
# 日本語パターン（決済/クレジットカード等）が一切マッチしない（Money Watch がサイレント無効化）。
# 日本語照合は必ず STDIN_TEXT に対して行うこと。
# v1.15.0: 純 bash でデコードする（以前は perl/python を hook 呼び出しごとに子プロセス起動しており、
# Windows の test-hooks が5分かかる主因だった。本番の hook もツールコールごとに1プロセス減る）。
# ロケールに依存しないよう UTF-8 バイト列は自前で組む（bash printf の \u はロケール依存で不可）。
# サロゲートペア（絵文字等）も合成する。デコードしきれない \u が残った場合だけ perl/python にフォールバック。
json_unescape_u() { # $1: 文字列 → stdout: \uXXXX を UTF-8 に展開した文字列
  local s="$1" lo cp ch hex re2
  local re='\\u([0-9a-fA-F]{4})'
  while [[ $s =~ $re ]]; do
    hex="${BASH_REMATCH[1]}"; cp=$((16#$hex)); lo=""
    if (( cp >= 0xD800 && cp <= 0xDBFF )); then   # 上位サロゲート → 直後の下位と合成
      re2="\\\\u${hex}\\\\u([dD][c-fC-F][0-9a-fA-F]{2})"
      if [[ $s =~ $re2 ]]; then
        lo="${BASH_REMATCH[1]}"
        cp=$(( 0x10000 + ((cp - 0xD800) << 10) + ($((16#$lo)) - 0xDC00) ))
      fi
    fi
    if (( cp < 0x80 )); then
      printf -v ch '\\x%02x' "$cp"
    elif (( cp < 0x800 )); then
      printf -v ch '\\x%02x\\x%02x' $((0xC0 | (cp >> 6))) $((0x80 | (cp & 0x3F)))
    elif (( cp < 0x10000 )); then
      printf -v ch '\\x%02x\\x%02x\\x%02x' $((0xE0 | (cp >> 12))) $((0x80 | ((cp >> 6) & 0x3F))) $((0x80 | (cp & 0x3F)))
    else
      printf -v ch '\\x%02x\\x%02x\\x%02x\\x%02x' $((0xF0 | (cp >> 18))) $((0x80 | ((cp >> 12) & 0x3F))) $((0x80 | ((cp >> 6) & 0x3F))) $((0x80 | (cp & 0x3F)))
    fi
    printf -v ch "$ch"
    if [ -n "$lo" ]; then s="${s//\\u${hex}\\u${lo}/$ch}"; else s="${s//\\u${hex}/$ch}"; fi
  done
  printf '%s' "$s"
}
STDIN_TEXT="$(json_unescape_u "$STDIN_JSON")"
if [[ $STDIN_TEXT =~ \\u[0-9a-fA-F]{4} ]]; then   # 取りこぼし時のみ外部ツール（従来経路）
  if command -v perl >/dev/null 2>&1; then
    STDIN_TEXT="$(printf '%s' "$STDIN_JSON" | perl -pe 's/\\u([0-9a-fA-F]{4})/pack("U",hex($1))/ge' 2>/dev/null)"
  elif command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
    PY="$(command -v python3 || command -v python)"
    STDIN_TEXT="$(printf '%s' "$STDIN_JSON" | "$PY" -c 'import sys,re; sys.stdout.write(re.sub(r"\\\\u([0-9a-fA-F]{4})", lambda m: chr(int(m.group(1),16)), sys.stdin.read()))' 2>/dev/null)"
  fi
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

# --- Money Watch 共通照合（money-watch.sh の PostToolUse と workflow-gate.sh の操作直前判定で共用） ---
# money_suppressed <text>: knowledge/config/money-suppress.txt のパターンに当たれば 0（検知対象外）。
# 抑制は「ページ（読み取り結果）」に対する誤検知チューニング用。**操作直前の強判定には効かせない**
# （ユーザー編集可能ファイルが硬いゲートの無効化スイッチにならないように — 2026-09-10 レビュー指摘）
money_suppressed() {
  local text="$1" SUPPRESS="$PROJECT_DIR/knowledge/config/money-suppress.txt" pat
  [ -f "$SUPPRESS" ] || return 1
  while IFS= read -r pat; do
    case "$pat" in ''|'#'*) continue ;; esac
    if printf '%s' "$text" | grep -qiE "$pat" 2>/dev/null; then return 0; fi
  done < "$SUPPRESS"
  return 1
}

# list_match <text> <list files...>: コメント・空行を除いた各行を大文字小文字無視の ERE として照合し、
# 最初にマッチしたパターンを stdout に返す（無ければ戻り値1）。bash の [[ =~ ]] を使い外部プロセスを起動しない
# （v1.15.0: 以前はパターンごとに grep を起動しており、1 hook 呼び出しで最大20プロセスだった）。
# url-guard と Money Watch の両方がこれを使う（ワークスペース側リストとの2層構造も同じ関数で扱う）。
list_match() {
  local text="$1" LIST pat; shift
  local _nc; _nc="$(shopt -p nocasematch)"; shopt -s nocasematch
  for LIST in "$@"; do
    [ -f "$LIST" ] || continue
    while IFS= read -r pat; do
      case "$pat" in ''|'#'*) continue ;; esac
      if [[ $text =~ $pat ]]; then
        eval "$_nc"; printf '%s' "$pat"; return 0
      fi
    done < "$LIST"
  done
  eval "$_nc"; return 1
}
# money_match_lists は後方互換の別名（照合は \uXXXX デコード済みテキストに対して行う）
money_match_lists() { list_match "$@"; }
money_strong() { money_match_lists "$1" "$SCRIPT_DIR/money-watchlist.txt" "$PROJECT_DIR/knowledge/config/money-watchlist.txt"; }
money_weak()   { money_match_lists "$1" "$SCRIPT_DIR/money-watchlist-weak.txt" "$PROJECT_DIR/knowledge/config/money-watchlist-weak.txt"; }

# 【弱】の再警告抑止: 同じ「ページURL × パターン」は1回だけ警告する。
# サイドメニューに「プラン変更」が常在する管理画面（xserver 等）で、読み取りのたびに同文の警告が出ると
# 注意が薄れて実際の金銭操作と区別がつかなくなる（2026-09-10 フィードバック）。
# キーは読み取り結果から拾った最初の URL（無ければパターンのみ）。サイドメニュークリック等の
# navigate を通らない遷移でも URL が変われば再警告される。navigate / SessionStart では全消去。
# ファイルは末尾 50 行に刈り取る（追記のみで肥大しないように）。
WEAK_SEEN="$WF_DIR/.money_weak_seen"
money_weak_seen_reset() { rm -f "$WEAK_SEEN" 2>/dev/null; return 0; }
money_weak_key() { # $1: パターン。stdout: "<url>	<pattern>"
  local url; url="$(printf '%s' "$STDIN_TEXT" | grep -oE 'https?://[^"[:space:]\]+' 2>/dev/null | head -n 1)"
  printf '%s	%s' "$url" "$1"
}
money_weak_seen() { [ -f "$WEAK_SEEN" ] && grep -qxF -- "$1" "$WEAK_SEEN" 2>/dev/null; }
money_weak_mark() {
  mkdir -p "$WF_DIR" 2>/dev/null
  printf '%s
' "$1" >> "$WEAK_SEEN" 2>/dev/null
  if [ "$(wc -l < "$WEAK_SEEN" 2>/dev/null | tr -dc '0-9')" -gt 50 ] 2>/dev/null; then
    tail -n 50 "$WEAK_SEEN" > "$WEAK_SEEN.tmp" 2>/dev/null && mv -f "$WEAK_SEEN.tmp" "$WEAK_SEEN" 2>/dev/null
  fi
  return 0
}

