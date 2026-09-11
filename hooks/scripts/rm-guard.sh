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

# --- 照合対象の絞り込み（v1.17.1: V39(b) 誤爆の修正。Opus レビュー C-1〜C-3 / I-1〜I-2 反映） ---
# 旧実装は hook ペイロード JSON 全文を照合していたため、「再帰削除が deny された」等の説明文を
# ヒアドキュメントで文書に書き出す Bash が、削除を一切していないのに deny された。
# 実行されるコマンド位置とデータとして渡される文章を分ける（単一 command 前提）:
#   1. tool_input.command だけを取り出す（取れなければ全文 = fail-closed）
#   2. クォート付きデリミタのヒアドキュメント本文（<<'EOF' / <<"EOF"）は展開されないので落とす。
#      クォート無しデリミタの本文は $(...) / ` が実行されるため、それを含む行だけ残す。
#      終端行が見つからない（解析失敗）場合は落とした本文を全部戻す（fail-closed）
#   3. シングルクォート内の文字列は、コマンドが「出力系のみ」（echo / printf / cat / tee / true / : の
#      連結）で構成され、$( ) / ` / プロセス置換を含まないときだけ落とす。それ以外（bash -c / eval /
#      awk / find -exec / 未知の実行語）は文字列を再実行し得るので落とさない（allowlist 方式）。
#      空白を含まないクォート（'rm' -rf 等の分割）はクォート記号だけ外して中身を残す
rm_guard_json_unescape() { # $1: JSON 文字列本体（\uXXXX は _common.sh で展開済み）→ stdout。左から1回走査なので「エスケープ済み \ + n」を改行に誤展開しない
  local s="$1" out="" pre
  while [ -n "$s" ]; do
    pre="${s%%\\*}"; out+="$pre"; s="${s:${#pre}}"
    [ -n "$s" ] || break
    case "${s:1:1}" in
      n) out+=$'\n' ;; t) out+=$'\t' ;; r) ;; '"') out+='"' ;; /) out+='/' ;; \\) out+='\' ;;
      *) out+="${s:0:2}" ;;
    esac
    s="${s:2}"
  done
  printf '%s' "$out"
}
rm_guard_extract_command() { # STDIN_TEXT → stdout: command フィールド。無ければ戻り値1
  local pat='"command":"((\\.|[^"\\])*)"'
  [[ $STDIN_TEXT =~ $pat ]] || return 1
  rm_guard_json_unescape "${BASH_REMATCH[1]}"
}
rm_guard_strip_heredoc() { # stdin → stdout
  awk '
    BEGIN { q = sprintf("%c", 39); inh = 0; nbuf = 0 }
    inh == 1 {
      line = $0; sub(/\r$/, "", line)
      if (dash) sub(/^[ \t]+/, "", line)
      if (line == delim) { inh = 0; nbuf = 0; next }
      buf[nbuf++] = $0                                  # 終端が来なければ END で戻す
      if (!quoted && ($0 ~ /\$\(/ || index($0, "`"))) print   # 未クォートの本文は展開が走る行だけ残す
      next
    }
    {
      print
      if (match($0, /<<-?[ \t]*["'"'"']?[A-Za-z_][A-Za-z0-9_]*["'"'"']?/)) {
        pre = substr($0, 1, RSTART - 1)
        if (index(pre, "\"") || index(pre, q) || index(pre, "#")) next   # クォート内・コメント内の << は開始扱いしない（本文を落とさない＝安全側。Opus 再レビュー C-A）
        tok = substr($0, RSTART, RLENGTH)
        dash = (tok ~ /^<<-/)
        sub(/^<<-?[ \t]*/, "", tok)
        quoted = (substr(tok, 1, 1) == "\"" || substr(tok, 1, 1) == q)
        gsub(/["'"'"']/, "", tok)
        delim = tok; inh = 1; nbuf = 0
      }
    }
    END { if (inh == 1) for (i = 0; i < nbuf; i++) print buf[i] }'
}
rm_guard_output_only() { # $1: コマンド → 0 なら全セグメントの先頭語が出力系のみ
  # allowlist の条件は「引数文字列をコマンドとして再実行しない語」であること（tee は引数ファイルを切り詰めるが再実行はしない）。
  # 分類は「クォート span を空白に潰した写し」で行う（クォート内の改行・; ・& で段落が割れて誤爆しないように — Opus 再レビュー I-A）。
  # 照合本体はクォート込みの CMD_TEXT で行う
  local seg first probe
  printf '%s' "$1" | grep -qE '\$\(|`|[<>]\(' && return 1
  probe="$(printf '%s' "$1" | tr '\n' '\001' | sed -e "s/'[^']*'/ /g" -e 's/"[^"]*"/ /g' | tr '\001;|&(){}' '\n\n\n\n\n\n\n\n\n')"
  while IFS= read -r seg; do
    seg="${seg#"${seg%%[![:space:]]*}"}"
    [ -n "$seg" ] || continue
    case "$seg" in [0-9]*|'>'*|'<'*) continue ;; esac      # 2>&1 の「1」、リダイレクト先はコマンドではない
    while [[ $seg =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+ ]]; do seg="${seg:${#BASH_REMATCH[0]}}"; done
    first="${seg%%[[:space:]]*}"
    case "$first" in echo|printf|cat|tee|true|:|ls|wc|head|tail|date|pwd) ;; *) return 1 ;; esac
  done <<< "$probe"
  return 0
}
RAW_CMD="$(rm_guard_extract_command)" || RAW_CMD="$STDIN_TEXT"
CMD_TEXT="$RAW_CMD"
if command -v awk >/dev/null 2>&1; then
  t="$(printf '%s\n' "$CMD_TEXT" | rm_guard_strip_heredoc)"
  [ -n "$t" ] && CMD_TEXT="$t"       # awk 異常終了（空）なら未加工のまま（fail-closed）
fi
# 空白を含まないクォート（'rm' "-rf" 等の分割）と英数字前のバックスラッシュ（\rm）は常に外して中身を照合に出す
# （内容を隠す方向には働かないので無条件。旧実装から抜けていた経路 — Opus レビュー C-2）
t="$(printf '%s' "$CMD_TEXT" | sed -e "s/'\([^'[:space:]]*\)'/\1/g" -e 's/"\([^"[:space:]]*\)"/\1/g' -e 's/\\\([[:alnum:]]\)/\1/g')"
[ -n "$t" ] && CMD_TEXT="$t"
if rm_guard_output_only "$CMD_TEXT"; then
  # 出力系のみのコマンドに限り、空白を含むシングルクォート文字列（文章）を落とす（複数行クォートも1本として扱う）
  t="$(printf '%s' "$CMD_TEXT" | tr '\n' '\001' | sed -e "s/'[^']*'//g" | tr '\001' '\n')"
  [ -n "$t" ] && CMD_TEXT="$t"
fi

# 対象コマンド判定（該当しなければ即通過）
# 照合は CMD_TEXT と「クォート記号を全削除した写し」の両方に対して行い、どちらかで当たれば対象
# （rm' '-rf のような空白入りクォートでの分割を塞ぐ。写しは内容を隠す方向に働かない。.workflow 免除は CMD_TEXT で判定）
MATCH_TEXT="$CMD_TEXT"$'\n'"$(printf '%s' "$CMD_TEXT" | tr -d "'\"")"
DANGEROUS=0
# rm の再帰フラグ（-r/-R/--recursive、-rf 等の複合も拾う）
if printf '%s' "$MATCH_TEXT" | grep -qE '(^|[^[:alnum:]_-])rm[[:space:]]+(-[[:alnum:]]*[rR]|--recursive)'; then
  DANGEROUS=1
# rm のグロブ一括（rm ... * / rm dir/*.png 等）
elif printf '%s' "$MATCH_TEXT" | grep -qE '(^|[^[:alnum:]_-])rm[[:space:]][^;|&]*\*'; then
  DANGEROUS=1
# find -delete / git clean / PowerShell Remove-Item -Recurse
elif printf '%s' "$MATCH_TEXT" | grep -qE '(^|[^[:alnum:]_-])find[[:space:]][^;|&]*-delete'; then
  DANGEROUS=1
elif printf '%s' "$MATCH_TEXT" | grep -qE '(^|[^[:alnum:]_-])git[[:space:]]+clean'; then
  DANGEROUS=1
elif printf '%s' "$MATCH_TEXT" | grep -qiE 'remove-item[^;|&]*-recurse'; then
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
MSG="【RM Guard】一括・再帰削除は機械ガード対象です。出口は2つ: (1) 自分が作成したファイルのパスを列挙し、個別に rm する（推奨。1コマンドに複数パスを並べるのは可、グロブ・-r は不可）。(2) どうしてもフォルダごと・グロブで消す必要がある場合は、実行しようとしたコマンドをそのままユーザーに提示し、ユーザー自身の手で実行してもらう。**AI 側で再試行・分割・別手段での回避を試みないこと**。削除できないまま終わる場合は、残置したパスを報告して完了してよい（削除の失敗はタスクの失敗ではない）。削除手順の**文書化**が目的ならクォート付きヒアドキュメントで書けます。"
gate_emit rm "RM Guard" "$MSG"
