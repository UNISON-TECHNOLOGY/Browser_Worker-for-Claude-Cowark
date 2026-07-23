#!/bin/bash
# Delvework Workflow Gate — PreToolUse hook
# ブラウザ変更操作（click/type/fill_form/select_option/file_upload/press_key）を
# B-4（フェーズ判定）と E（変更前記録）の完了フラグなしではブロックする。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Credential Guard: パスワード/認証情報フィールドへの「入力」を常時ブロック（フラグの有無に関係なく）
# 対象は入力系操作のみ（form_input / playwright type・fill / computer の type・key）。
# クリックやスクショは対象外（「パスワードをお忘れですか」リンクのクリック等を誤爆させない）
IS_INPUT_OP=0
if printf '%s' "$STDIN_JSON" | grep -qE '(form_input|browser_type|browser_fill_form)'; then
  IS_INPUT_OP=1
elif printf '%s' "$STDIN_JSON" | grep -q 'claude-in-chrome__computer' && \
     printf '%s' "$STDIN_JSON" | grep -qE '"action"[[:space:]]*:[[:space:]]*"(type|key)"'; then
  IS_INPUT_OP=1
fi
if [ "$IS_INPUT_OP" = "1" ] && printf '%s' "$STDIN_JSON" | grep -qiE '(password|passwd|パスワード|暗証|otp|verification.?code|認証コード|secret|credential)'; then
  deny "【Credential Guard】パスワード・認証情報フィールドへの入力はAIには許可されていません。ログイン・認証入力は人間が行ってください（ブラウザのパスワードマネージャ推奨）。完了したら操作を再開します。"
fi

# Read-only pass-through: In Chrome の computer ツールは読み取り操作（screenshot/scroll等）も
# 同じツール名で来るため、action を見て変更を伴わない操作は素通しする
if printf '%s' "$STDIN_JSON" | grep -q 'claude-in-chrome__computer'; then
  if printf '%s' "$STDIN_JSON" | grep -qE '"action"[[:space:]]*:[[:space:]]*"(screenshot|scroll|zoom|cursor_position|wait|hover|mouse_move)"'; then
    exit 0
  fi
fi

# JS実行系（javascript_tool / browser_evaluate / browser_run_code）は読み取り計測にも使うため、
# 変更を伴うAPI呼び出しを含むコードのみゲート対象にする（読み取りJSは素通し）
if printf '%s' "$STDIN_JSON" | grep -qE '(javascript_tool|browser_evaluate|browser_run_code)'; then
  if ! printf '%s' "$STDIN_JSON" | grep -qE '\.click\(|\.submit\(|dispatchEvent|\.value[[:space:]]*=|innerHTML[[:space:]]*=|location(\.href)?[[:space:]]*=|window\.open|fetch\(|XMLHttpRequest|sendBeacon|localStorage\.(set|remove|clear)|document\.cookie[[:space:]]*=|\.focus\(\).*type|execCommand'; then
    exit 0
  fi
fi

if [ ! -f "$WF_DIR/active" ]; then
  deny "【Delvework Gate】ワークフロー未初期化。/delve-start でタスクを開始し、B-4（フェーズ判定）を完了してください。"
fi

if [ ! -f "$WF_DIR/b4_done" ]; then
  deny "【Delvework Gate】B-4（フェーズ判定）が未完了です。/delve-start の手順に戻り、B-4（フェーズ判定）まで完了してから変更操作を行ってください。フラグを直接 touch して迂回することは禁止です。"
fi

if [ ! -f "$WF_DIR/e_done" ]; then
  deny "【Delvework Gate】Step E（変更前記録）が未完了です。/delve-start の手順どおり、read_page（Claude in Chrome）または browser_snapshot（Playwright）で変更前の状態を記録・保存してから進んでください。記録せずフラグだけ立てる迂回は禁止です。"
fi

exit 0
