#!/bin/bash
# RM Guard — 一括・再帰削除の機械ガード（PreToolUse:Bash）
# 背景: 2026-07-24 ローカル検証で Sonnet・Opus の両方が「後片付け」を拡大解釈し outputs フォルダの
# 一括削除を提案（harness の許可プロンプトで停止）。モデル差でなく指示解釈の構造問題のため機械強制する。判断はエージェント・強制は hook の原則に従い、
# 再帰削除（rm -r）・グロブ一括削除（rm *）・find -delete・git clean を機械層で止める。
# 個別ファイルの rm と memory/.workflow/ 配下のフラグ掃除には干渉しない。
# 導入手順（昇格の記録は TESTING-archive.md「GATE_MODE 昇格」/ 切替の手順は TESTING.md 検証プロンプト (9) の注記）: 初期は warn（注入のみ）で運用し、誤爆ゼロ確認後に deny へ昇格。
# 2026-07-24 deny 昇格済み（v1.1.5 実機2ランで warn 発火・正当な個別削除の誤爆ゼロを確認。V39 実測）。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# --- 照合対象の絞り込み（v1.17.1: V39(b) 誤爆の修正） ---
# 旧実装は hook ペイロード JSON 全文を照合していたため、「再帰削除が deny された」等の説明文を
# ヒアドキュメントで文書に書き出す Bash が、削除を一切していないのに deny された。
# 実行されるコマンド位置とデータとして渡される文章を分ける:
#   1. tool_input.command だけを取り出す（取れなければ全文 = fail-closed）
#   2. クォート付きデリミタのヒアドキュメント本文（<<'EOF' / <<"EOF"）は展開されないので落とす。
#      クォート無しデリミタの本文は $(...) / ` が実行されるため、それを含む行だけ残す
#   3. シングルクォート内の文字列はシェルが展開しないので落とす — ただし bash -c / eval / xargs /
#      パイプ先のシェル等、文字列を再びコマンドとして実行し得る語が1つでもあれば落とさない
rm_guard_extract_command() { # STDIN_TEXT → stdout: command フィールド（JSON エスケープ解除済み）。無ければ戻り値1
  local pat='"command":"((\.|[^"\])*)"' c
  [[ $STDIN_TEXT =~ $pat ]] || return 1
  c="${BASH_REMATCH[1]}"
  c="${c//\\\"/\"}"          # \" → "
  c="${c//\\//\/}"          # \/ → /
  printf '%b' "$c"           # \n \t \ を展開
}
rm_guard_strip_heredoc() { # stdin → stdout
  awk '
    inh == 1 {
      if ($0 == delim) { inh = 0; next }
      if (!quoted && ($0 ~ /\$\(/ || $0 ~ /`/)) print   # 未クォートの本文は展開が走る行だけ残す
      next
    }
    {
      print
      if (match($0, /<<-?[ \t]*["\047]?[A-Za-z_][A-Za-z0-9_]*["\047]?/)) {
        tok = substr($0, RSTART, RLENGTH)
        sub(/^<<-?[ \t]*/, "", tok)
        quoted = (tok ~ /^["\047]/)
        gsub(/["\047]/, "", tok)
        delim = tok; inh = 1
      }
    }'
}
RUNNER_RE='(^|[^[:alnum:]_./-])(bash|sh|zsh|dash|ksh|eval|exec|xargs|source|su|sudo|ssh|pwsh|powershell|cmd|node|python[0-9.]*|perl|ruby)([[:space:]]|$|\))|\$\(|`'
CMD_TEXT="$(rm_guard_extract_command)" || CMD_TEXT="$STDIN_TEXT"
CMD_TEXT="$(printf '%s\n' "$CMD_TEXT" | rm_guard_strip_heredoc)"
if ! printf '%s' "$CMD_TEXT" | grep -qE "$RUNNER_RE"; then
  CMD_TEXT="$(printf '%s' "$CMD_TEXT" | sed "s/'[^']*'//g")"
fi

# 対象コマンド判定（該当しなければ即通過）
DANGEROUS=0
# rm の再帰フラグ（-r/-R/--recursive、-rf 等の複合も拾う）
if printf '%s' "$CMD_TEXT" | grep -qE '(^|[^[:alnum:]_-])rm[[:space:]]+(-[[:alnum:]]*[rR]|--recursive)'; then
  DANGEROUS=1
# rm のグロブ一括（rm ... * / rm dir/*.png 等）
elif printf '%s' "$CMD_TEXT" | grep -qE '(^|[^[:alnum:]_-])rm[[:space:]][^;|&]*\*'; then
  DANGEROUS=1
# find -delete / git clean / PowerShell Remove-Item -Recurse
elif printf '%s' "$CMD_TEXT" | grep -qE '(^|[^[:alnum:]_-])find[[:space:]][^;|&]*-delete'; then
  DANGEROUS=1
elif printf '%s' "$CMD_TEXT" | grep -qE '(^|[^[:alnum:]_-])git[[:space:]]+clean'; then
  DANGEROUS=1
elif printf '%s' "$CMD_TEXT" | grep -qiE 'remove-item[^;|&]*-recurse'; then
  DANGEROUS=1
fi
[ "$DANGEROUS" = "1" ] || exit 0

# 免除: memory/.workflow/ 配下のみを対象とするフラグ掃除（再帰フラグなし）は素通し
# 例: rm -f memory/.workflow/{b4_done,e_done} / rm memory/.workflow/verify_*
if printf '%s' "$CMD_TEXT" | grep -q 'memory/\.workflow/' && \
   ! printf '%s' "$CMD_TEXT" | grep -qE '(^|[^[:alnum:]_-])rm[[:space:]]+(-[[:alnum:]]*[rR]|--recursive)'; then
  # rm の対象パスが .workflow 以外を含まないことを確認（含む場合はゲート対象）
  if ! printf '%s' "$CMD_TEXT" | sed 's|memory/\.workflow/[^[:space:]]*||g' | grep -qE '(^|[^[:alnum:]_-])rm[[:space:]][^;|&]*[[:alnum:]/*]'; then
    exit 0
  fi
fi

# deny 時は「実行可能な出口」まで書く。承認を求めるだけの文言だと、ユーザーが承認しても
# hook は依然 deny のため AI が「承認 → やはり実行できない」を往復して進まない（2026-07-27 過剰ゲート監査）。
MSG="【RM Guard】一括・再帰削除は機械ガード対象です。出口は2つ: (1) 自分が作成したファイルのパスを列挙し、個別に rm する（推奨。1コマンドに複数パスを並べるのは可、グロブ・-r は不可）。(2) どうしてもフォルダごと・グロブで消す必要がある場合は、実行しようとしたコマンドをそのままユーザーに提示し、ユーザー自身の手で実行してもらう。**AI 側で再試行・分割・別手段での回避を試みないこと**。削除できないまま終わる場合は、残置したパスを報告して完了してよい（削除の失敗はタスクの失敗ではない）。削除手順を**文書として**書き出したいだけなら、クォート付きヒアドキュメント（<<'"'"'EOF'"'"'）の本文は照合対象外。"
gate_emit rm "RM Guard" "$MSG"
