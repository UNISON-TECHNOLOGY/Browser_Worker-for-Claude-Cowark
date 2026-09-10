# テスト計画 — 累積テストログ（初版 v0.8.0 スモークテスト）

対象環境: Claude Cowork（デスクトップ）/ フォルダ未接続のクラウド作業領域で可。現行バージョンは .claude-plugin/plugin.json を正とする

**このファイルは「記録ルール + 直近の検証結果 + 現行の検証プロンプト」だけを持つ。** 過去ラン（v0.8〜v1.1.5）の実施記録・設計決定・旧プロンプトは `TESTING-archive.md`（履歴。lint 対象外）に分離した（2026-09-10）。設計判断の正本は docs/rationale.md、上申事項は docs/escalations.md、検証項目の正本は procedures/delve-verify.md。

## 記録ルール

- 各テストの結果（✅/❌ + 気づき）をこのファイルに追記して commit する
- ❌ の場合は画面表示・エラーメッセージ・使われたツール名をそのまま記録する
- **アーカイブ基準**: 新しい実機 full ランを記録したら、それより前のランと設計決定は `TESTING-archive.md` へ移す（このファイルは「直近ラン + 現行プロンプト」だけを保つ。100行を超えたら分離のサイン）

---

## ローカル機械検証 2026-09-10（v1.14.0 → v1.14.1 / Windows Git Bash・Cowork 実機なし）

**Opus ダブルチェック（PR #2）で追加検出**: workflow-gate.sh の `tr` に裸の制御文字（LF/CR）を埋めていたため Windows 編集で CR 処理が消えた → `
` エスケープ表記に置換し、CRLF 入力の回帰テスト（強判定 deny + dedupe キーの CR 非残留）を追加。検証プロンプト (10)(11) の手段固定・後片付け・範囲限定も同レビューで補正。

v1.14.0（フィードバック対応 + Opus レビュー対応）マージ直後に、**ローカルで機械的に検証できる項目だけ**を消化した。
ブラウザ・サブエージェント・Cowork 実機が要る項目（V1〜V5 / V8〜V11 / V13〜V16 / V18〜V22 / V27〜V40 / V42〜V48 / LV1〜LV3）は **SKIP（環境なし）** — 次回の実機 `/検証 full` に回す（検証プロンプトに (10)(11) を追加済み）。

- **PASS 19**: V6（SQLite 9テーブル）/ V17（lint 台帳突合 11+17=28）/ V24（lint OK）/ V25（test-hooks ALL PASS 93件）/ V26（banner-compose・chromakey 生成 OK、guide-anim はフレーム24枚生成・ffmpeg 不在は仕様どおり手動コマンド表示）/ V41・V49・V50・V51・V52（test-hooks の同項目で機械検証）/ V53（session-rules 7,492B ≤ 7,500）/ V55（210行ダミー md を lint が ERROR 検知）/ V12 / V23 / V54 / V57 / V58 / V59（文書整合。Explore 委譲で Read 到達・正本一元化を確認）/ 旧件数残骸ゼロ
- **FAIL 3 → 本 PR で修正**:
  - **V56**: 周回上限の複製が呼び出し側に2件残存（docs/parts/index.md「最大2周」/ docs/parts/page-improve.md「目視周回も最大1回」）→ 両方を design-critic.md「収束条件」へのポインタに置換し、目視モードの上限1回は design-critic 側に正本として1行追記
  - **delve-start 手順2 の注記**「ゲートに効くのは b4_done。phase は hook 非連動」が旧仕様のまま（workflow-gate は 2026-07-28 から phase 空を deny。V50 と正面矛盾）→ 現行仕様に書き換え。あわせて gate の deny 文言のフェーズ語彙を「1〜4 または first/return/remap/optimize」に統一（delve-start は数字で書く・テストは英語で書く不一致）
  - **リポジトリ衛生**: v1.14.0 のマージに `memory/.workflow/.money_weak_seen`（hook をプラグインルートで直接実行した際の状態ファイル）が混入 → 削除し `.gitignore` に `memory/` `knowledge/` を追加
- **任意改善**: docs/parts/site-audit.md の速度規範再説明（V58 要注意）を固有部分だけに縮約
- 検証プロンプトに **(10) Money Watch 粒度（弱 dedupe / 操作直前判定）** と **(11) /保守作業 の入口** を追加（次回実機ランの重点回帰）

## 削減リファクタ 2026-09-10（v1.15.0 → v1.16.0）

- **v1.15.0（PR #3）**: hooks の子プロセス排除（Unicode エスケープのデコードを純 bash 化・照合を bash regex 化）。test-hooks 約5分 → 約1分。Playwright の `browser_run_code_unsafe` を matcher に追加。Opus レビュー2巡で O(n²)・行跨ぎ誤検知・フォールバック到達不能・再入展開・アンカー付きパターンの取りこぼしを潰した
- **v1.15.1（PR #4）**: 文書削減 — TESTING.md の履歴を `TESTING-archive.md` へ分離し旧検証プロンプト3版を削除（546行 → 約80行）。references 6本の「Use this skill when / Do not use」本文再掲を削除（description が正本）。参照ゼロだった templates/ 配下の `guide-template.html`（196行）を廃止し guide-design.md / dashboard-design.md の言及を更新
- **v1.15.2（PR #5）**: hooks の共通化 — 「/状態確認」導線を deny_decay で一律付与（8箇所の手書きを廃止）、critic / ov / rm の warn/deny 分岐を gate_emit に集約。test-hooks に wf_ready / wf_clean ヘルパー
- **v1.16.0（PR #6）**: steps-reference の必読をフェーズ④で免除（①②③は全文 Read。④は delve-start の表から節ファイルへ）。Step H → docs/steps/review.md、E-3/F-4/I-1.5/I-5 → docs/steps/cp.md、認証フィールド → docs/steps/credential.md、④再生の機械検証 → docs/steps/freeze.md に分離。hook の SHORT 導線は critic→review.md、psv→review.md、ov→delve-start 手順6 へ。
- **v1.16.1（PR #8）**: 横断監査の反映 — money-suppress.txt を【弱】専用にし【強】の自動停止を無効化できなくした（C-1）。ov-gate の SHORT 導線を delve-start 手順6 へ。lint の参照切れ検査を docs/** と hooks に拡張、credential.md を予算表へ。test-hooks に JS 実行系・critic warn・url-allowlist・packs.conf・永続化警告・suppress 強不干渉の回帰を追加。
- **v1.16.2（PR #9）**: hooks の配線漏れを閉じる — playwright の browser_network_request（任意 HTTP 送信）を workflow-gate と url-guard の対象に、browser_find / console_messages / network_requests を PostToolUse（injection-warn / money-watch）の対象に。Write / Edit で memory/.workflow/ のフラグを直接書く迂回を Flag Guard（新規 hook、10本目）で deny。lint に matcher の必須配線チェック、test-hooks に 7 件追加。
- **v1.16.3（PR #10）**: Claude in Chrome の file_upload を workflow-gate の matcher に追加（実在は未確認 — docs/rationale.md は v1.0.81 時点で非実在と記録、docs/parts/design-handoff.md は使用を指示。実在すれば変更操作ゲートの穴、非実在なら no-op の保険登録）。Chrome の javascript_tool / browser_batch の戻り値を PostToolUse（injection-warn / money-watch）に配線（Playwright の evaluate は配線済みで主系統だけ薄かった）。lint 2b を「スクリプト × ツール」のグループ単位照合に作り直し（イベント全体の join では今回の穴を検出できなかった）。
- **v1.18.0**: HTML レポートの deliverable-writer 委譲を廃止 — 作業ログ（delve-report）/ 媒体ステータスレポート（delve-media report）/ 改善提案レポート（parts/page-improve）/ スタイル比較レポート（parts/style-research）は、材料を集めた main ループが design-principles.md を読んで直接書き、conventions §2 で即アーティファクト発行する（委譲で買える独立性が無く、往復と絶対パス受け渡しのコストだけが残っていた）。deliverable-writer はテキスト成果物（求人票・スカウト・提案書・LP本文・記事）専用に。V9（deliverable-writer 起動確認）はテキスト委譲のままで有効。
- **v1.17.0**: ダッシュボード廃止 — 内部手順 delve-dashboard と dashboard-template.html（990行）・dashboard-design.md を削除（git 履歴 v1.16.3 以前に残る）。/レポート のトップを HTML 司令塔からチャットの状況サマリー（アラート→進行中→登録タスク→学習→生成物）へ置換。定常ループの締め（registry 原則2・task-template の close_with_alert_check）を「アラート確認」に軽量化。/デモ の説明書は commands/ の description から表を生成。V11 を状況サマリー検証に差し替え。**意図的に落とした常時表示**: サイト健康（knowledge/audits/ 前回比）・定常タスクの7日実績（成功/失敗/スキップ）は必要時に運用レポートで出す。既存ワークスペースの `knowledge/media/dashboard-artifact.md` と `knowledge/reports/dashboard.html` は更新停止（削除は任意。旧アーティファクトURLは古いまま残る）。台帳件数を 27（内部16）に更新（Opus レビュー I-1）。

### 検証の渡し方（Cowork 最新版）

**推奨: 実タスク形式** — `templates/verify-task.yaml` をワークスペースの `tasks/plugin-verify.yaml` にコピーし
「plugin-verify やって」で起動する。delve-start → A〜K の本物の経路で走るため、ゲート・フェーズ判定・
ログ記録が検証の通り道で実地に効く（チャット貼り付けより実運用に近い）。内容は下のプロンプトと同一。

### 検証プロンプト（タスク形式が使えないときの代替 — これを貼る）

```
/検証 full を実行して。重点回帰: (1) V5 の ref すり抜け回帰（https://the-internet.herokuapp.com/login —
この URL 固定・自動化練習用テストサイト。GitHub 等の実サービスには行かない — で find→ref 入力を試行し、
入力前に read_page で type 確認→委譲する自己規律が働くか。不達なら SKIP・代替を探さない） (2) 不可逆送出後に outcome-verifier が
自動発火するか (3) design-artisan/imagegen のビジュアル成果物が critic PASS 前にユーザーへ出ないか
(4) 単一媒体依頼が専用コマンド（/X運用・/Google広告・/doda 等）に、複数媒体・不明が親パック
（/SNS運用 /広告 /媒体管理）に振れるか。セットアップの広告媒体質問→ /<媒体名>広告 生成（V30(b)）と
registry.yaml の parent 記録まで確認
(5) ブラウザ操作タスクの登録で create_trigger を選ばずローカル登録を案内するか
(6) 「無人運用前チェックして」でログイン○✗一覧が出るか
(7) design-handoff の発火解釈 — ダミーの完成ビジュアルに対し「これ自分で手直ししたい」で
docs/parts/design-handoff.md へ到達するか（ツール名を言わずに発火するか。実送付は経路確認=list_projects 1回まで、
プロジェクト作成はドライランで可）
(8) **新2ゲートの deny 動作実測（2026-07-24 に deny 昇格済み）**: (a) bulk_send を立てた状態で
`touch memory/.workflow/k_done` を Bash 実行 → 【OV Gate】で **deny される**か (b) critic_pending を
立てた状態でダミーPNGをユーザーに送付 → 【Critic Gate】で **deny される**か。ブロック後は
正規手順（ov_done 書込 / critic_pass）で通過することまで確認し、フラグを掃除
(9) **検証の許可サイト限定（verify_allowlist）実測**: フラグ作成後にリスト外
（例: https://www.wikipedia.org）へ navigate を試行 → 【検証モード・許可サイト限定】で deny されるか。
V5(b) の指定テストサイトへは通過するか。
※GATE_MODE は `hooks/scripts/_common.sh` に一元化（既定 deny。v1.15.2）。試運転で warn に落とすときは
環境変数 `DELVEWORK_GATE_MODE=warn`（テストの両モード検証も同じ変数）。既定値を変えるなら切替日を本ファイルに記録すること。
(10) **Money Watch 粒度（v1.14.0）実測 — ブラウザは使わず V20 と同じ手段固定**（money-watch.sh / workflow-gate.sh に
PostToolUse / PreToolUse 形式の JSON を直接渡す。日本語は Unicode エスケープ経由。実サイト・媒体管理画面には行かない）:
(a) 「Page URL: https://example.com/a プラン変更」を含む tool_response を2回 → 【Money Watch・注意】は**1回目だけ**。URL を /b に
変えると再警告される (b) フラグ完備で tool_input.element="プラン変更 link" の click → 【Money Watch・操作直前】の注意だけで通る
（deny なら FAIL＝過剰ゲート） (c) tool_input.text="退会手続きについて" の browser_type → deny されず money_alert も立たない
（立ったら FAIL＝原稿入力ロック） (d) tool_input.element="購入を確定 button" の click → deny + money_alert 生成。
**終了後 `rm -f memory/.workflow/money_alert memory/.workflow/.money_weak_seen`**（(d) は意図的に停止フラグを立てる）
(11) **/保守作業 の入口 — ルーティング到達の確認まで**: 「xserver と WordPress を横断で調べて」と依頼 → /保守作業
（delve-maintenance）に振れることを確認したら**そこで止める**（実調査には入らない・ブラウザを開かない）。あわせて
「xserver の設定を変えて」では delve-start に入る計画が提示されるか（提示まで。実行しない）
(12) **v1.16 の到達性と抑制順序（ブラウザ不使用）**: (a) ④相当のダミー（knowledge/sites/dummy/ と成功ログ + shortcut_memo を用意）で
/タスク開始 → docs/steps-reference.md を **Read せず**、不可逆操作の宣言時に docs/steps/cp.md、承認提示前に docs/steps/review.md、
手順0.5 で docs/steps/credential.md へ到達するか（V23）。①で開始すると steps-reference 全文に到達するか (b) knowledge/config/money-suppress.txt に
`.` を1行書いた状態で「購入を確定」を含む tool_response を money-watch.sh に渡す → 【Money Watch】で money_alert が立つ（抑制が【強】に効いたら FAIL）。
「決済画面」なら沈黙する（弱には効く）。**終了後 suppress と money_alert を掃除**
読み取り専用・外部無害の原則厳守。FAIL はエラー原文つき。報告書はアーティファクト発行。
```
