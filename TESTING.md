# テスト計画 — 累積テストログ（初版 v0.8.0 スモークテスト）

対象環境: Claude Cowork（デスクトップ）/ フォルダ未接続のクラウド作業領域で可。現行バージョンは .claude-plugin/plugin.json を正とする

## 判定済み

| # | 項目 | 結果 |
|---|------|------|
| T0 | プラグイン読み込み（/delve-status 実行） | ✅ 合格（2026-07-22） |
| T0b | marketplace 更新検知（version フィールド） | ✅ 合格（version 明記で解決） |
| T1 | プラグイン同梱 MCP（playwright）のチャット供給 | ❌ **不合格**（2026-07-22）: 設定画面のコネクタタブには表示されるが、チャットの「+」メニューに現れずツールとして供給されない。**回避策**: claude_desktop_config.json の mcpServers に playwright を直接登録（適用済み）。チャットでは Claude in Chrome を OFF にして playwright に限定する |

## Phase 1: 基盤（全ての前提）

| # | 手順 | 期待結果 | 失敗時の対応 |
|---|------|---------|-------------|
| T1 | コネクタタブで playwright をクリックして接続 | 接続済み表示になる | 同梱MCP仕様の問題 → コネクタとして手動登録に切替 |
| T2 | 「example.com を開いてリンクをクリックして」 | `mcp__playwright__*` ツールが使われ、**【Delvework Gate】ワークフロー未初期化** でブロック | Chrome が使われた→使用ツール名を記録して matcher 調整。ブロックされない→hook 実行有無の切り分けへ |

**T2 がこの計画全体の核心。** ブロックが出れば「Cowork で PreToolUse hook + ゲート」が成立。

> ✅ **T2 合格（2026-07-22, v0.9.0）**: Claude in Chrome の `computer`（クリック）実行時に
> 「【Delvework Gate】ワークフロー未初期化」で正しくブロック。navigate / find（読み取り）は通過。
> Cowork での hook ゲート成立を確認。
>
> ✅ **T1 も条件付き合格に更新**: v0.9.0 更新時に「ローカルMCPサーバーを含む」承認ダイアログが表示された。
> 同梱 MCP は承認後に供給される仕様（初回インストール時は出なかったが、いずれかの更新で評価された）。
> ただし v0.9.0 以降は Claude in Chrome が前提エンジンのため playwright は必須ではない。

## Phase 2: ワークフロー遷移

| # | 手順 | 期待結果 |
|---|------|---------|
| T3 | `/delve-start テスト` | memory/.workflow/ にフラグ作成、フェーズ①判定 |
| T4 | 再度クリック指示 | 今度は **Step E（変更前記録）未完了** のブロックに変わる |
| T5 | snapshot 実行 → e_done 作成 → クリック指示 | 操作が通る（ゲート解除） |
| T6 | 新しいセッションを開始 | session-start hook が「前回タスク未完了」を通知 |

> ✅ **T3-T5 合格（2026-07-22, v0.9.0）**: /delve-start → フェーズ①自己判定 → read_page で Step E →
> ゲート解除後にクリック成功（Clicked on element ref_4）→ k_done + セッションログ記録まで
> ワークフロー一周が Cowork 上で自走完了。
>
> ⚠️ **既知の環境癖（In Chrome 方式固有）**: クリック後にユーザーの Chrome の別拡張がタブを
> 乗っ取ると「Cannot access a chrome-extension:// URL」で以降の操作が失敗する。
> 実ブラウザを使う方式の宿命。対処: navigate で直接遷移する / 干渉する拡張を無効化する。

## Phase 3: 実用機能

| # | 手順 | 期待結果 |
|---|------|---------|
| T7 | `/delve-style <参考サイトURL>` | 巡回→トークンJSON生成→**deliverable-writer（sonnet）に委譲**→比較HTMLレポート生成 |
| T8 | T7 の実行ログで委譲を確認 | Agent ツールで deliverable-writer が起動し、モデルが sonnet になっている（agents/deliverable-writer.md の frontmatter が正） |
| T9 | `/delve-audit <自社サイトURL> 5` | 速度実測+品質チェック+診断HTMLレポート |
| T10 | `/delve-report` | タスク成果のHTMLレポート生成 |

## Phase 4: 永続化（本運用前に1回）

| # | 手順 | 期待結果 |
|---|------|---------|
| T11 | 「フォルダを追加」で業務フォルダを接続して T3〜T5 を再実行 | knowledge/ と memory/ が PC 側フォルダに作られ、セッション終了後も残る |

## Phase 5: v0.12〜v0.22 で追加された未検証項目

| # | 手順 | 期待結果 |
|---|------|---------|
| T12 | コマンド名を言わず「〇〇のデザインを調べて」 | delve-style が自然文から自動発火 |
| T13 | 曖昧に「このページを分析して」 | 観点の選択肢（デザイン/速度品質/コンテンツ/報告）が提示されルーティング |
| T14 | 「/」入力 | 日本語コマンド（/サイト診断 等6本）が候補一覧に表示・実行可能 |
| T15 | 「このLPを改善して」（delve-improve フルコース） | 計測再利用→診断→artisan生成→critic審査→修正ループ→アーティファクト発行→目視検証 |
| T16 | T15 の実行ログ | design-artisan のモデルが fable（不可なら sonnet フォールバックが機能） |
| T17 | HTMLレポート出力（経路問わず） | report-template.html 準拠の見た目 + knowledge/reports/ 保存（我流CSSでない） |
| T18 | 画像を添付して「この写真を使ってモックアップ作って」 | knowledge/assets/ 保存→Pillow加工→埋め込み（VMにPillowがあるか要確認） |

## Phase 6: v0.23〜v0.35 で追加された未検証項目

| # | 手順 | 期待結果 |
|---|------|---------|
| T19 | 更新後、フラグなしでスクショ指示 | computer の screenshot がゲートを素通り（v0.34修正の確認） |
| T20 | ログインフォームでパスワード入力を指示 | Credential Guard がブロック（type/fill のみ。クリックは誤爆しない） |
| T21 | 「Xの投稿ストック埋めて」 | /delve-sns の3フェーズ（実態照合→分析→充足）が発火・knowledge/sns/ 初期化 |
| T22 | 「媒体を登録して」→「全媒体の状況見せて」 | registry.yaml 作成→巡回→アラート表 |
| T23 | 「ダッシュボード更新して」×2回 | 1回目 create、2回目は**同一URL**の update |
| T24 | Slack コネクタ接続後、承認キューの一周 | pending.md 記録→Slack投稿→✅→次回実行で送信 |
| T25 | 前回タスク未完了状態で新セッション開始 | 引き継ぎ通知**と**運用ルールの両方が注入される（v0.36修正の確認） |

## /delve-verify 実施記録

### 2026-07-22 初回実行（Cowork, v0.43+）

- `/delve-verify` は Cowork で発火した（コマンド供給・引数 `full` の受理を確認。補完に出るのはコマンド名まで、`full` は手打ち引数）
- ⚠️ **V9/V10 で委譲プロンプトがユーザーへ手渡しされた**: 本来 Agent ツールで deliverable-writer / design-artisan に内部委譲されるはずのタスク文（`/home/claude/tmp-verify/v9-test.md` 等）がチャット本文として出力された。**Cowork チャットで Agent（サブエージェント）ツールが未供給、または Fable が委譲経路を取れなかった**ことを示唆
  - 影響: V9/V10（writer/artisan 起動・モデル確認）、delve-improve の審査ループ、delve-deep のオーケストレーションは Cowork では main ループ直執筆にフォールバックする前提で設計を見直す必要
  - 対処案: conventions.md の委譲規範に「Agent ツールが無い環境では main ループが直接執筆し、その旨を成果物に1行記録」を追記（次版）
- PASS/FAIL 表形式の報告書（`knowledge/verification/<date>-verify.md`）の受領は未確認。以降の実行では報告書コードブロックの出力を必須とする

## 検証ワークフロー v0.63 — ドメイン再編 + /delve-task + ダッシュボードv9 の総合検証

今日の大改修（v0.44→0.63: MCP撤去 / 台帳ドメイン再編 / ダッシュボード「秘湯紀行」タスク自動追加）を
コワーク側で一括検証する手順。**開発側（このリポジトリ）とコワーク側（実行環境）の往復で完結する。**

### 手順（コワーク側 — ユーザーがそのまま貼る）

1. プラグインを **v0.63.0** に更新（プラグインを管理 → 更新）→ **新チャット**を開く
2. 次を1行貼る:
   > /delve-verify full を実行して。V18・V19（タスク登録・実行連携）とV11（ダッシュボードのテンプレ準拠）は特に丁寧に。最後に必ずPASS/FAIL表のコードブロックを出力して。
3. 実行が終わったら、出力された **PASS/FAIL 表のコードブロックをそのままこのチャット（開発側）に貼り戻す**

### 重点確認（今回の変更に対応する項目）

| 項目 | 見るところ |
|---|---|
| V11 | ダッシュボードが dashboard-template 準拠（浮世絵ヘッダー・旅人・タブ=全体+ドメイン・停留点数=タブ数）で、見本データでなく実データ |
| V17 | 台帳20コマンド/20手順 + スキル台帳11件が実体と一致、全行にドメイン |
| V18 | /delve-task register で YAML + loops.yaml が生成される（積み込み口の成立） |
| V19 | delve-start が tasks/*.yaml を実行計画として読む（エンジンと荷物の接続） |
| V14 | 日本語エイリアス（/定常タスク を含む）が発火する |

### 実施記録 2026-07-22（Cowork, v0.63.0）— ✅ 合格

**PASS 17 / FAIL 0 / SKIP 2**（V8 自然文発火=未観測、V16 Slack=コネクタ未接続）

- コア全通過: ゲート（V3/V4）・Credential Guard（V5・クリック誤爆なし）・DB 9テーブル（V6）・台帳20/20+スキル12一致（V17）
- **新機能全通過**: V18 タスク登録（verify-loop.yaml + loops.yaml 生成・スキーマ機械確認）/ V19 YAML実行連携（delve-startが steps を計画の正に採用→読み取り完走→remove で消滅確認、navigate-warn.sh の警告も観測）/ V11 ダッシュボード（ドメイン5タブ・stops5点・旅人保持・実データ、攻略済みの峰の社が実数=1軒に連動）
- サブエージェント: V9 deliverable-writer=sonnet-5 / V10 design-artisan=**fable-5で起動**（フォールバックなし）。チャットに委譲プロンプト文面が見えるのは Cowork の Agent 呼び出し表示仕様で、手渡しではない
- 環境知見: ①プラグイン実体は `/root/.claude/plugins/synced/browser-worker`（相対 templates/ 不達 → Globフォールバック必須・現行記述で対応済み）②sqlite3 CLI 不在 → python3 標準ライブラリで代替可 ③create_artifact は一過性502あり（リトライで解消）・既存IDは update 経路が正
- 生成物確認: user-guide.html は guide-template 準拠（定常タスク登録の言い方も掲載）。dashboard.html はドメインタブ+未運用ドメインの案内+「次の一手」導線まで正しく生成
- 注: この検証は v0.63.0 実施のため、ダッシュボードは委譲生成（全文執筆）。v0.63.1 以降は**テンプレのファイルコピー+データ行Edit**が正

### 開発側（貼り戻し受領後）

1. 表を本セクション直下に「実施記録」として追記して commit
2. FAIL 項目は原因を切り分け、修正 → bump → 再検証の指示文を再発行
3. V9/V10（サブエージェント）は前回チャットでは動作確認済み — 今回も委譲プロンプトが
   ユーザーに手渡しされた場合のみ問題として記録（conventions.md にフォールバック規範あり）

## 記録ルール

- 各テストの結果（✅/❌ + 気づき）をこのファイルに追記して commit する
- ❌ の場合は画面表示・エラーメッセージ・使われたツール名をそのまま記録する

---

## v0.69.0 検証プロンプト（Cowork に貼り付けて実行）

前提: marketplace 更新で v0.69.0 を取り込み済み（/状態確認 でバージョン確認）。永続フォルダ接続推奨。

```
プラグインの検証を full モードで実行して（/検証 full）。
今回の重点は v0.69.0 の改修点。以下を必ず含めて、最後に PASS/FAIL 表を TESTING.md 形式で出して:

1. V20 Money Watch: 「決済・お支払い方法」を含むローカルHTMLを読み取り、
   (a) 警告が注入される (b) memory/.workflow/money_alert が生成される
   (c) その状態でクリック等の変更操作が deny される、の3点。
   確認後は rm memory/.workflow/money_alert で解除すること。
2. ダイアログゲート: confirm ダイアログの承認ツール（handle_dialog 系）がフラグ未設定で
   ブロックされるか（example.com 上で beforeunload 等の無害な方法で試す。実サイトでの確定操作は禁止）。
3. V22 pre-send-verifier: ダミー送信計画（本文+宛先2件、うち1件をわざと「許可リスト外の大学」に）を
   渡して監査させ、VERDICT: NO-GO/GO-WITH-FIXES と違反1件の根拠つき FAIL 指摘が返ること。
4. V21 strategy-advisor: ダミーのタスクYAML案で壁打ちし、VERDICT 形式の助言が返ること。
5. V23 steps正本: docs/steps-reference.md に到達でき（Globフォールバック含む）、
   E-3（CP証跡）と I-3（ログスキーマ）の節が読めること。
6. フェーズ③: /タスク開始 のダミータスク中に「ナレッジと実ページの構造差異を検出した」と仮定し、
   手順書の指示どおり e_done 削除→phase=3 更新→E 再実行の流れを自走できるか（example.com で可）。
7. V10 design-artisan: fable で起動するか、不可なら sonnet フォールバックが手順どおり機能するか。
8. 既存コア回帰: V2〜V5（読み取りフリー/変更ゲート/解除フロー/Credential Guard）、
   V17（台帳整合: 20コマンド/20手順/リファレンス11/エージェント5）。

原則: 読み取り専用・外部無害（実サイトへの送信・投稿・変更は一切しない。ブラウザは example.com と
ローカルHTMLのみ）。FAIL には観測事実の原文を添える。全項目消化後、報告書を
knowledge/verification/<date>-verify.md に保存してチャットにも表示して。
```

期待: PASS 基準は procedures/delve-verify.md（V1〜V26）。FAIL があれば TESTING.md に追記して開発側に戻す。

---

## 実施記録 2026-07-23（Cowork）— DesignSync パイプライン検証 ✅

- **Cowork レビュー（v0.69.3 時点）**: 「0.63.0 から別物レベルに堅牢化。前回指摘はほぼ実装済み」。lint/test-hooks を Cowork 側ローカルでも全 PASS 確認。残件 a（money deny 文言の解除コマンド）・b（読み取り専用 batch）は v0.69.4 で修正済み
- **DesignSync（Claude Design 連携）が Cowork セッションに供給されることを実機確認**。運用ダッシュボードのデザインモック（KPIタイル4+週次推移折れ線+棒グラフ+媒体台帳+承認キュー、ライト/ダーク対応）を作成し、①チャットHTML ②アーティファクト ③**claude.ai/design プロジェクト（dashboards/delvework-ops/）への登録**の3経路で送達成功
- 次の段階候補: /ダッシュボード の定期実行と knowledge/ 実データ流し込みをこのフォーマットに接続

## 実施記録 2026-07-23（Cowork）— Gemini 画像生成 E2E ✅（生成◎・取り込み△）

- ログイン済み Chrome で Gemini を操作: /delve-start→変更前記録→プロンプト入力→送信→**約10秒で生成成功**（Flash）。ゲート手続き一連通過、ref 指定クリック+タイプで安定
- 取り込みは Downloads 未接続のためスクショ（zoom）経由 = **約565×330px で本番素材には粗い**。フレーミングずれで1回トリミング要
- 結論: 案出し用途は現状で実用。本番用途は (a)Downloads フォルダ接続→保存ボタン回収 (b)Gemini API 切替。→ delve-imagegen（v0.71.0）の取り込み表に反映済み

## 実施記録 2026-07-23（Cowork）— 画像加工パイプライン（2勝1敗）

- ✅ Gemini 生成画像 → 16:9センタートリミング → 1280×720 → 下部グラデーション → コピー焼き込み（Noto Sans CJK）を1スクリプトで全自動処理成功 → **templates/banner-compose.py としてテンプレ化**（v0.72.0、Windows ローカルでも機能テスト済み）
- ❌ 背景除去（rembg）: インストール可だがモデル本体 u2net.onnx（GitHub/HF 配布）のDLがサンドボックスの許可リストでブロック。回避: (a)ユーザーPCでDLして接続フォルダ搬入 (b)Canva/Claude Design 側に寄せる → delve-imagegen 3b に記録済み

## 実施記録 2026-07-23（Cowork）— グリーンバック + クロマキー切り抜き ✅

- Gemini に「背景 #00FF00 一色」指定 → 忠実な緑背景人物を出力 → numpy クロマキー（緑優勢度→連続アルファ+スピル抑制）で透過PNG化に成功。輪郭・足元の影までクリーン。MLモデル不要・数秒・決定論的
- → **templates/chromakey.py としてテンプレ化**（v0.73.0、Windows でも機能テスト済み: 四隅 alpha=0 / 被写体 alpha=255）
- 発見: Gemini UI に「フルサイズの画像をダウンロード」ボタンあり → 専用DLフォルダ接続でフル解像度原画に対して同処理可能
- これで「生成（GB指定）→ クロマキー → 背景合成 → コピー焼き込み（banner-compose.py）」の素材制作ラインが全部内蔵で完結

## 実施記録 2026-07-23（Cowork）— 動画系（2/2成功）

- ✅ スクショ+注釈アニメ: Python 72フレーム描画 → ffmpeg で mp4/GIF 書き出し成功（暗幕+パルスリング+吹き出し+ステップ表示）。ffmpeg はサンドボックス標準搭載 → **templates/guide-anim.py としてテンプレ化**（v0.74.0、Windows でフレーム生成テスト済み）
- ✅ 画面録画（gif_creator）: 録画→スクロール→書き出し成功。制約: ブラウザタブ内のみ / GIF 最大50フレーム / 保存先はユーザー Downloads
- 線引き: 本格動画編集は ffmpeg で素材持ち込みなら可 / 実録画はブラウザ操作の GIF 記録まで。MP4 生成も確認済み

## 実施記録 2026-07-23（Cowork）— WebM / 透過動画 ✅

- ✅ mp4→WebM(VP9): 88KB→67KB ワンコマンド。AV1 エンコーダも搭載確認
- ✅ **アルファ付き WebM**: クロマキー切り抜き人物 → 背景完全透過の浮遊ループ動画（13KB）。yuva420p + -auto-alt-ref 0 が必須。確認HTML（グラデ/市松背景）で透過を目視確認（guide-animation_1.mp4 / person-alpha.webm 生成）
- → **docs/media-pipeline.md（正本）に部品一覧+ffmpegレシピ+定番3ラインとして統合**（v0.75.0）

## 実施記録 2026-07-23（Cowork）— 動画生成（Gemini 経由）✅

- ✅ Gemini 経由での動画生成が実機で成功（画像生成と同じ UI 操作の型で到達）
- → **delve-imagegen §2b（動画生成）として手順化**（v0.76.0）: 本数を先に合意 / wait で完了待機 / 採用本体のみ専用DLフォルダ or blob fetch で取り込み / 後段は media-pipeline の ffmpeg レシピへ接続
- media-pipeline.md 部品一覧に「動画生成」行を追加

## 実施記録 2026-07-23（Cowork）— 動画フルライン + 取り込みルートの教訓 ✅/❌

- ✅ **Gemini 動画生成 → 背景除去 → WebM 化のフルラインが実機で完走**（media-pipeline 定番ライン2が動画起点でも成立）
- ❌ 取り込みが Downloads → チャット手動アップロード経由だとレンダリング（加工処理）に失敗する
- → **専用DLフォルダ接続をメディア制作の必須セットアップに格上げ**（v0.77.0）: README に3手順の節を新設 / delve-imagegen §3 に失敗実測を明記 / media-pipeline 共通ルールに「未接続なら代替せず止まってセットアップ依頼」を追加
