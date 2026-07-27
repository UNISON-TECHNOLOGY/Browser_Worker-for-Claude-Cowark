#!/bin/bash
# Delvework Money Watch — PostToolUse hook
# ページ読み取り結果に金銭・契約・不可逆登録系のパターンを検知したら、
# (1) 停止フラグ memory/.workflow/money_alert を設置（以降の変更操作を workflow-gate が deny）
# (2) 上位モデル（strategy-advisor）への相談とユーザー承認を要求する警告を注入する。
# 検知は決定論的（grep）、判断は strategy-advisor、解除はユーザー承認 — の三段構え。
#
# 検知は2段階（2026-07-27 過剰ゲート監査で導入）:
#   【強】money-watchlist.txt      … 停止する（確定表現・金額確定・不可逆文言のみ）
#   【弱】money-watchlist-weak.txt … 停止しない・注意喚起のみ（ナビに常在する名詞）
# 単独の「決済」「請求」「課金」で停止していた頃は、媒体の管理画面を開いた時点で
# 定常タスクが毎回詰み、解除に strategy-advisor + ユーザー承認を要していた。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# 抑制リスト（誤検知チューニング用）: ユーザーが knowledge/config/money-suppress.txt に
# 書いたパターンにマッチするページは検知対象から除外する（例: 日常業務で開く媒体の管理画面URL/文言）
SUPPRESS="$PROJECT_DIR/knowledge/config/money-suppress.txt"
if [ -f "$SUPPRESS" ]; then
  while IFS= read -r pat; do
    case "$pat" in ''|'#'*) continue ;; esac
    if printf '%s' "$STDIN_TEXT" | grep -qiE "$pat" 2>/dev/null; then
      exit 0
    fi
  done < "$SUPPRESS"
fi

match_lists() { # $@: リストファイル群。最初にマッチしたパターンを stdout に返す
  local LIST pat
  for LIST in "$@"; do
    [ -f "$LIST" ] || continue
    while IFS= read -r pat; do
      case "$pat" in ''|'#'*) continue ;; esac
      # 照合は STDIN_TEXT（\uXXXX デコード済み）に対して行う — 生JSONだと日本語パターンが不発になる
      if printf '%s' "$STDIN_TEXT" | grep -qiE "$pat" 2>/dev/null; then
        printf '%s' "$pat"
        return 0
      fi
    done < "$LIST"
  done
  return 1
}

matched="$(match_lists "$SCRIPT_DIR/money-watchlist.txt" "$PROJECT_DIR/knowledge/config/money-watchlist.txt")"

# 【強】に当たらなければ【弱】を照合。弱は停止せず注意喚起のみ（フラグを立てない）
if [ -z "$matched" ]; then
  weak="$(match_lists "$SCRIPT_DIR/money-watchlist-weak.txt" "$PROJECT_DIR/knowledge/config/money-watchlist-weak.txt")"
  [ -z "$weak" ] && exit 0
  warn_posttool "【Money Watch・注意】この画面に金銭系の表示があります（パターン: $weak）。停止はしていません — 変更操作を行う前に、操作対象の要素が金銭・契約・不可逆登録に触れないことを自分で確かめてください。触れる場合は自己判断で進めず、strategy-advisor の助言とユーザーの明示承認を得ること。"
fi

mkdir -p "$WF_DIR" 2>/dev/null
printf '%s' "$matched" > "$WF_DIR/money_alert"

warn_posttool "【Money Watch】いま読み取った画面に金銭・契約・不可逆登録系の要素を検知しました（パターン: $matched）。変更操作は一時停止されます（ゲートが deny）。docs/steps-reference.md 末尾『Money Watch 停止からの復帰』の手順に従うこと: (1) strategy-advisor サブエージェントにこの画面の状況と実行しようとしていた操作を渡し、続行可否の助言（STOP/RESPOND/MONITOR）を得る。(2) 助言と操作内容をユーザーに提示し、明示的な承認を得る。(3) 承認を得た場合のみ手順書記載の方法で解除し、承認の事実を session-log に1行記録して再開する。ユーザー承認なしの解除は禁止。"
