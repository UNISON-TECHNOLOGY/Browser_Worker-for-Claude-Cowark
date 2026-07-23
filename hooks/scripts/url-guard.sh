#!/bin/bash
# Delvework URL Guard — PreToolUse hook（ページ単位権限）
# navigate 系ツールの遷移先URLを拒否リストと照合し、金銭発生・広告出稿・課金設定
# ページへの遷移をブロックする。誤操作・自律判断による広告出稿（＝金銭発生）の防止が目的。
#
# リストの優先順位:
#   1. knowledge/config/url-allowlist.txt … マッチしたら許可（拒否リストより優先。ユーザーが明示的に開放）
#   2. knowledge/config/url-denylist.txt  … ワークスペース固有の追加拒否
#   3. hooks/scripts/url-denylist.txt     … プラグイン同梱のデフォルト拒否

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# ペイロードから URL を抽出（claude-in-chrome navigate / playwright browser_navigate とも "url" キー）
URL="$(printf '%s' "$STDIN_JSON" | grep -oE '"url"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)".*/\1/')"
[ -z "$URL" ] && exit 0

match_list() {
  # $1: リストファイル。コメント・空行を除いた各パターンで URL を照合
  local file="$1" pat
  [ -f "$file" ] || return 1
  while IFS= read -r pat; do
    case "$pat" in ''|'#'*) continue ;; esac
    if printf '%s' "$URL" | grep -qiE "$pat" 2>/dev/null; then
      return 0
    fi
  done < "$file"
  return 1
}

# 1. 許可リスト（ユーザーの明示開放）が最優先
if match_list "$PROJECT_DIR/knowledge/config/url-allowlist.txt"; then
  exit 0
fi

# 2-3. 拒否リスト照合
for LIST in "$PROJECT_DIR/knowledge/config/url-denylist.txt" "$SCRIPT_DIR/url-denylist.txt"; do
  if match_list "$LIST"; then
    deny "【URL Guard】このページ（$URL）は金銭発生・広告出稿・課金設定に該当するため遷移をブロックしました。広告出稿や課金操作はAIには許可されていません。業務上必要な場合は、ユーザー本人が knowledge/config/url-allowlist.txt に該当パターンを追記して明示的に開放してください（AIが代行して追記することは禁止）。"
  fi
done

exit 0
