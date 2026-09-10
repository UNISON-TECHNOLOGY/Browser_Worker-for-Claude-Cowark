#!/bin/bash
# Delvework Navigate Warn — PreToolUse hook（警告のみ、ブロックしない）

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# ページ遷移で Money Watch【弱】の再警告抑止をリセット（新しいページでは改めて1回警告する）。
# 同じ PreToolUse で url-guard が deny した場合もここは走りリセットされるが、余分に1回警告する安全側なので許容。
money_weak_seen_reset

if [ -f "$WF_DIR/active" ] && [ ! -f "$WF_DIR/e_done" ]; then
  warn_pretool "【Delvework】Step E（変更前記録）が未完了のままページ遷移します。変更操作の前に browser_snapshot で記録してください。"
fi

exit 0
