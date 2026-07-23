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

# Money Watch 停止フラグ: 金銭・契約系画面の検知後は、ユーザー承認による解除まで変更操作を全て deny。
# JS実行系より前に置く（コード実行は mutation 可能なため、金銭停止中は無条件で止める＝フェイルクローズ）。
if [ -f "$WF_DIR/money_alert" ]; then
  deny "【Money Watch】金銭・契約・不可逆登録系の画面を検知したため変更操作を停止中です（検知: $(cat "$WF_DIR/money_alert" 2>/dev/null | head -c 80)）。strategy-advisor の助言を得てユーザーに操作内容を提示し、明示的な承認を得てから rm memory/.workflow/money_alert で解除してください。ユーザー承認なしの解除は禁止です。"
fi

# JS実行系（javascript_tool / browser_evaluate / browser_run_code）は読み取り計測にも使うため、
# 明らかに読み取り専用のコードだけ workflow-init ゲート（active/b4/e）を免除して素通しする。
# 注意: 任意 JS の mutation 判定を denylist で完全網羅はできない（eval/Function/難読化で回避可能）。
# よって denylist は best-effort に過ぎず、硬い防御は上の Money Watch と Credential Guard・URL Guard が担う。
# denylist に当たる or 判定不能なコードは素通しせず、下の workflow ゲートを必ず通す（フェイルクローズ寄り）。
if printf '%s' "$STDIN_JSON" | grep -qE '(javascript_tool|browser_evaluate|browser_run_code)'; then
  if ! printf '%s' "$STDIN_JSON" | grep -qE '\.click\(|\.submit\(|requestSubmit|dispatchEvent|\.value[[:space:]]*=|innerHTML[[:space:]]*=|insertAdjacentHTML|location(\.href)?[[:space:]]*=|location\.(assign|replace)|\.href[[:space:]]*=|window\.open|fetch\(|XMLHttpRequest|sendBeacon|navigator\.send|localStorage\.(set|remove|clear)|sessionStorage\.(set|remove|clear)|document\.cookie[[:space:]]*=|\.focus\(\).*type|execCommand|\beval\b|new[[:space:]]+Function|Function\(|setTimeout|setInterval|\bimport\b|Reflect\.(apply|set)|\[[[:space:]]*["'"'"']|\[[a-zA-Z_$][^]]*\][[:space:]]*\('; then
    exit 0
  fi
fi

if [ ! -f "$WF_DIR/active" ]; then
  deny "【Delvework Gate】ワークフロー未初期化。/タスク開始 でタスクを開始し、B-4（フェーズ判定）を完了してください。"
fi

if [ ! -f "$WF_DIR/b4_done" ]; then
  deny "【Delvework Gate】B-4（フェーズ判定）が未完了です。/タスク開始 の手順に戻り、B-4（フェーズ判定）まで完了してから変更操作を行ってください。フラグを直接 touch して迂回することは禁止です。"
fi

if [ ! -f "$WF_DIR/e_done" ]; then
  deny "【Delvework Gate】Step E（変更前記録）が未完了です。/タスク開始 の手順どおり、read_page（Claude in Chrome）または browser_snapshot（Playwright）で変更前の状態を記録・保存してから進んでください。記録せずフラグだけ立てる迂回は禁止です。"
fi

exit 0
