#!/bin/bash
# Delvework Session Start — 前回未完了タスクの通知 + 環境情報

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

if [ -f "$WF_DIR/active" ] && [ ! -f "$WF_DIR/k_done" ]; then
  task="$(cat "$WF_DIR/active" 2>/dev/null | tr -d '\n"\\')"
  warn_session "【Delvework】前回のタスク「$task」が未完了です（k_done なし）。memory/session-log.md を確認して引き継いでください。"
fi

warn_session "【Delvework 運用ルール】ブラウザの変更操作（computer/form_input または playwright の click/type等）はワークフローゲート対象。タスクは /delve-start で開始し、変更前記録（Step E）は read_page / browser_snapshot 等の読み取りツールで行うこと（computer のスクリーンショットはゲート対象なので E 完了前は read_page を使う）。/delve-status で状態確認可。"
