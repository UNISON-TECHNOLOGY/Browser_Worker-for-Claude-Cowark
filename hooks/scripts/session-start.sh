#!/bin/bash
# Delvework Session Start — 前回未完了タスクの通知 + 環境情報

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

if [ -f "$WF_DIR/active" ] && [ ! -f "$WF_DIR/k_done" ]; then
  task="$(cat "$WF_DIR/active" 2>/dev/null | tr -d '\n"\\')"
  warn_session "【Delvework】前回のタスク「$task」が未完了です（k_done なし）。memory/session-log.md を確認して引き継いでください。"
fi

warn_session "【Delvework 運用ルール】(0)ブラウザに関わる依頼（サイトの閲覧・調査・診断・操作・入力すべて）は必ず本プラグイン（Delvework）の機能を経由すること。我流でブラウズを始めず、該当する delve コマンドの手順に従う。該当がなければ通常ブラウズでよいが、変更操作を伴うなら必ず /delve-start から。(1)ブラウザの変更操作（computer/form_input または playwright の click/type等）はワークフローゲート対象。タスクは /delve-start で開始し、変更前記録（Step E）は read_page 等の読み取りツールで行う（computer の screenshot/scroll 等の読み取り action はゲート対象外で自由に使える）。(2)ルーティング: サイトやページに関する曖昧な依頼（『分析して』『調べて』『見て』等で観点が不明）には、質問ツールで観点の選択肢を提示して振り分けること — デザイン/配色/構成の調査→/delve-style、表示速度/品質/SEO/リンク切れ→/delve-audit、コンテンツ/訴求内容の要約→通常のブラウズ、作業成果の報告→/delve-report。観点が明確な依頼は確認せず直接対応する。(3)広告・求人・SNS系のコピーを生成したら公開前に ad-compliance-jp スキル（景表法/ステマ規制/薬機法/職安法）のチェックを必ず通すこと。(3b)成果物にユーザーが評価・修正指示をしたら knowledge/feedback/lessons.md への学習記録（/delve-feedback の手順）を行うこと。(4)HTML形式のレポート・分析資料を作成する際は、依頼経路を問わず必ずプラグインの templates/design-principles.md と templates/report-template.html を使い、knowledge/reports/ に保存すること（執筆は deliverable-writer エージェントに委譲）。独自CSSでの我流レポートは禁止。create_artifact が使える環境ではレポート/モックアップをアーティファクトとしても発行し共有URLを報告する。(5)巡回先でログアウト状態を検知したら黙って失敗せず、ログインページで autofill を試し（クリックのみ・パスワード入力はしない）、不可ならユーザーに通知して該当媒体をスキップし残りを続行する。2FA遭遇時は即中断して通知。(6)ブラウザ操作前に、この環境で使える系統（mcp__claude-in-chrome__* / mcp__playwright__*）を確認してから進めること。両方あれば Claude in Chrome を優先（ログイン済みセッション）。手順書内のツール名は使える系統に読み替える。ツールが見つからなくても遅延ロードの可能性があるため検索・再試行してから判断する。(7)Slack ツールが使える環境では、通知・完了報告・送信系の承認依頼を docs/unattended-ops.md の「Slack連携」手順（非同期承認キュー: knowledge/approvals/pending.md が正本）で行うこと。(7b)生成した成果物は書いて終わりにせず必ずユーザーに届ける — アーティファクト発行、不可ならファイル送信、どちらも不可なら保存パスと開き方を明示する。(8)/delve-status で状態確認可。"
