#!/bin/bash
# Delvework Session Start — 前回未完了タスクの通知 + 環境情報

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

if [ -f "$WF_DIR/active" ] && [ ! -f "$WF_DIR/k_done" ]; then
  task="$(cat "$WF_DIR/active" 2>/dev/null | tr -d '\n"\\')"
  warn_session "【Delvework】前回のタスク「$task」が未完了です（k_done なし）。memory/session-log.md を確認して引き継いでください。"
fi

warn_session "【Delvework 運用ルール】ブラウザ操作は必ず Playwright MCP（mcp__playwright__browser_* ツール）を使うこと。Claude in Chrome / Cowork 標準ブラウザは Delvework のワークフローゲート対象外のため使用禁止。Playwright が利用できない場合は操作せずユーザーに報告する。/delve-status で状態確認可。"
