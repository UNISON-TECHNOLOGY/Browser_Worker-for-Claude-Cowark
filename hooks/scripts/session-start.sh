#!/bin/bash
# Delvework Session Start — 前回未完了タスクの通知 + 環境情報

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

if [ -f "$WF_DIR/active" ] && [ ! -f "$WF_DIR/k_done" ]; then
  task="$(cat "$WF_DIR/active" 2>/dev/null | tr -d '\n"\\')"
  warn_session "【Delvework】前回のタスク「$task」が未完了です（k_done なし）。memory/session-log.md を確認して引き継いでください。"
fi

warn_session "【Delvework 運用ルール】(1)ブラウザの変更操作（computer/form_input または playwright の click/type等）はワークフローゲート対象。タスクは /delve-start で開始し、変更前記録（Step E）は read_page 等の読み取りツールで行う（computer のスクショはゲート対象）。(2)ルーティング: サイトやページに関する曖昧な依頼（『分析して』『調べて』『見て』等で観点が不明）には、質問ツールで観点の選択肢を提示して振り分けること — デザイン/配色/構成の調査→/delve-style、表示速度/品質/SEO/リンク切れ→/delve-audit、コンテンツ/訴求内容の要約→通常のブラウズ、作業成果の報告→/delve-report。観点が明確な依頼は確認せず直接対応する。(3)/delve-status で状態確認可。"
