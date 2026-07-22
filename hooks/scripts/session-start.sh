#!/bin/bash
# Delvework Session Start — 前回未完了タスクの通知 + 環境情報

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# 注意: warn_session は exit するため、呼べるのは1回だけ。メッセージは PREFIX に集約する
PREFIX=""
if [ -f "$WF_DIR/active" ] && [ ! -f "$WF_DIR/k_done" ]; then
  task="$(cat "$WF_DIR/active" 2>/dev/null | tr -d '\n"\\')"
  PREFIX="【Delvework】前回のタスク「$task」が未完了です（k_done なし）。memory/session-log.md を確認して引き継ぐこと。 "
fi

# タスクPack設定（knowledge/config/packs.conf）: off のパックを通知に含める
PACKS_CONF="$PROJECT_DIR/knowledge/config/packs.conf"
if [ -f "$PACKS_CONF" ]; then
  OFF_PACKS="$(grep -E '^[a-z-]+=off' "$PACKS_CONF" 2>/dev/null | cut -d= -f1 | grep -v '^core$' | tr '\n' ',' | sed 's/,$//')"
  if [ -n "$OFF_PACKS" ]; then
    PREFIX="${PREFIX}【タスクPack】無効: ${OFF_PACKS} — 該当パックの機能は使わない・提案しない・自動発火させない（定義は /delve-config 参照。ユーザーが明示要求したときのみON化を1行案内）。 "
  fi
fi

# 運用ルール本文は session-rules.txt が正本（bash文字列への直書き禁止 — 編集性とエスケープ事故防止）
RULES_FILE="$SCRIPT_DIR/session-rules.txt"
if [ -f "$RULES_FILE" ]; then
  RULES="$(tr '\n' ' ' < "$RULES_FILE" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  warn_session "${PREFIX}${RULES}"
fi

# フォールバック（rules ファイル欠損時）
warn_session "${PREFIX}【Delvework】session-rules.txt が見つかりません（プラグイン破損の可能性）。docs/conventions.md と各 delve コマンドの手順に従い、変更操作は必ず /delve-start から行うこと。"
