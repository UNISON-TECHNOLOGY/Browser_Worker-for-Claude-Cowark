#!/bin/bash
# Delvework Money Watch — PostToolUse hook
# ページ読み取り結果に金銭・契約・不可逆登録系のパターンを検知したら、
# (1) 停止フラグ memory/.workflow/money_alert を設置（以降の変更操作を workflow-gate が deny）
# (2) 上位モデル（strategy-advisor）への相談とユーザー承認を要求する警告を注入する。
# 検知は決定論的（grep）、判断は strategy-advisor、解除はユーザー承認 — の三段構え。
#
# 検知は2段階（2026-07-27 過剰ゲート監査で導入）+ 弱の重複抑止と操作直前判定（2026-09-10）:
#   【強】money-watchlist.txt      … 停止する（確定表現・金額確定・不可逆文言のみ）
#   【弱】money-watchlist-weak.txt … 停止しない・注意喚起のみ（ナビに常在する名詞）
# 単独の「決済」「請求」「課金」で停止していた頃は、媒体の管理画面を開いた時点で
# 定常タスクが毎回詰み、解除に strategy-advisor + ユーザー承認を要していた。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# 抑制リスト（誤検知チューニング用）: ユーザーが knowledge/config/money-suppress.txt に
# 書いたパターンにマッチするページは検知対象から除外する（例: 日常業務で開く媒体の管理画面URL/文言）
money_suppressed "$STDIN_TEXT" && exit 0

matched="$(money_strong "$STDIN_TEXT")"

# 【強】に当たらなければ【弱】を照合。弱は停止せず注意喚起のみ（フラグを立てない）。
# 同じ「ページURL × 弱パターン」は再警告しない（.money_weak_seen。navigate-warn / session-start が全消去）—
# 「操作直前」の本判定は workflow-gate.sh が操作対象（tool_input）に対して行う。
if [ -z "$matched" ]; then
  weak="$(money_weak "$STDIN_TEXT")"
  [ -z "$weak" ] && exit 0
  key="$(money_weak_key "$weak")"
  money_weak_seen "$key" && exit 0
  money_weak_mark "$key"
  warn_posttool "【Money Watch・注意】この画面に金銭系の表示があります（パターン: $weak）。停止はしていません — 同じページ（URL）ではこの警告を繰り返しません。操作対象の要素に金銭系文言があれば操作直前にゲートが改めて知らせます。触れる場合は自己判断で進めず docs/steps/money-recovery.md に従うこと。"
fi

mkdir -p "$WF_DIR" 2>/dev/null
printf '%s' "$matched" > "$WF_DIR/money_alert"

# hook 出力は「フラグを設置した事実 + 正本へのポインタ」に留める（復帰手順の文言を二重管理しない。
# 正本は docs/steps/money-recovery.md — ここに写すと乖離してどちらが正か分からなくなる）
warn_posttool "【Money Watch】いま読み取った画面に金銭・契約・不可逆登録系の要素を検知したため、memory/.workflow/money_alert を設置しました（パターン: $matched）。以降の変更操作はゲートが deny します。復帰手順の正本 docs/steps/money-recovery.md を Read して従うこと（ユーザーの明示承認なしの解除は禁止）。"
