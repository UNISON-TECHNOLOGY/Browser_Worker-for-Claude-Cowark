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

## 設計決定 2026-07-23 — HTML組み込みは Claude Design（DesignSync）へ

- メディア素材（アルファWebM・切り抜き画像等）を HTML/LP に組み込む工程は **DesignSync で claude.ai/design のプロジェクトへ流すのが正ルート**（ユーザー決定）。ローカルHTML直書きはプレビュー用途のみ
- media-pipeline 正本 + delve-improve / delve-adlp の DesignSync 節に既定ルート化を反映（v0.77.1）。同期は従来どおり finalize_plan の承認を経る

## 設計決定 2026-07-23 — ファイル形式の線引き + 素材パック規約（v0.78.0）

- **確定**: PPTX/DOCX/XLSX/PDF は Cowork 内蔵の文書生成スキルに委ねプラグインは橋渡しのみ / SVG は既知の穴（DesignSync に直接流せる唯一の画像形式・将来優先候補）/ PSD/AI は対象外 → media-pipeline に「ファイル形式カバレッジ」節
- **確定**: Claude Design へは素材単品でなくパック（`knowledge/assets/packs/<名>/` + **DESIGN.md マニフェスト必須**: 用途/寸法/カラー/埋め込みスニペット/出典）。ZIP は DesignSync に使わず人間・他ツール向け配布のみ → media-pipeline に「素材パック規約」節
- **未検証**（下の検証プロンプトで実施）: DesignSync のバイナリ受け入れ / PPTX・PDF 橋渡し / パック運用のE2E

### 検証プロンプト（Cowork に貼り付け）

```
Delvework の素材パック検証を3点。読み取り+自ワークスペース内の生成のみで、外部サイトへの送信・変更はしないこと。

1) DesignSync バイナリ受け入れ: 小さな PNG（templates/banner-compose.py のダミー出力でよい）を
   DesignSync write_files で claude.ai/design のテストプロジェクトに書き込めるか試す。
   通る/通らない、通らない場合のエラー原文を記録。data URI 化したテキストなら通るかも試す。
2) PPTX/PDF 橋渡し: (a) その PNG を1枚スライドの PPTX に流し込む（Cowork 内蔵の文書スキル）
   (b) 任意の HTML レポートを PDF 化。どのツール/スキルで実現できたかを記録。
3) 素材パック E2E: knowledge/assets/packs/test-pack/ に PNG+DESIGN.md（docs/media-pipeline.md の
   素材パック規約どおり: 用途/寸法/カラー/スニペット/出典）を作り、DesignSync で DESIGN.md → 素材の順に
   同期。Design 側プロジェクトで DESIGN.md が読める状態になったかを確認。

報告: 各項目 PASS/FAIL/PARTIAL + 観測事実（エラー原文）。終わったら test-pack と
テストプロジェクトの後片付けをして、knowledge/verification/ に結果を保存。
```

## 実施記録 2026-07-23（Cowork）— 素材パック検証 3/3 PASS → v0.79.0 で確定昇格

- ✅ **DesignSync バイナリ受け入れ**: PNG 直接 write_files 成功（written:1、get_file で image/png・isBase64・全量一致読み戻し）。data URI テキストも成功 → media-pipeline の未検証注記を解消、フォールバック規定撤去。残る未知: get_file 256KiB 上限の兆候（巨大バイナリは未検証）
- ✅ **PPTX/PDF 橋渡し**: python-pptx 1.0.2（プリインストール）で PNG→16:9 PPTX / headless Chromium `--print-to-pdf` で HTML→PDF（コマンドを media-pipeline に確定記載）
- ✅ **素材パック E2E**: packs/test-pack/{DESIGN.md, PNG} を DESIGN.md 先行で同期、Design 側で逐語読み戻し確認。規約そのままで運用可
- 後片付け: Design 側4ファイル delete_files 済み。**残置: 空のテストプロジェクト delvework-verification-test（DesignSync に削除メソッドなし→UI から手動削除）**
- 副次確認: delete_files も finalize_plan 承認制 / banner-compose.py が Cowork サンドボックスで動作（Noto Sans CJK 検出）

## 大規模再編 2026-07-23 — 4層アーキテクチャ + カテゴリーレベルコマンド（v0.80.0）

- **概念確定（ユーザー決定）**: コマンド=カテゴリーレベル（媒体・対象のパック、要望は引数に自由記述）/ ワークフロー=タスクの連なり（A〜K + タスク5型連結）/ タスク=単一の仕事（リサーチ・収集・クリエイティブ・分析・掃き出し）/ サブエージェント=専門作業。実行粒度3段（タスク単体/ワークフロー連結/まるっと）
- **コマンド 23→20 に再編**: SNS媒体6（X/Instagram/TikTok/note/YouTube/LINE — 媒体別の見える範囲・制約を各パックに記載、LINEは配信承認+費用見積もり必須）+ 媒体管理 + Webサイト + 広告 + 基盤6 + 記録5（作業ログ/スキル化/メモリ保存/メモリ圧縮※新設/検証※配布時削除）
- **共有部品庫 docs/parts/ 新設（18部品）**: 旧単機能コマンド（スタイル調査/サイト診断/徹底/素材探し/画像生成/キャンバ/ページ改善/広告からLP/動画広告）+ 新部品（sns-research/jobpost/scoutmail/image-edit/video-edit/videogen/video-asset-collect/design-sync）を部品化。パックのタスクが Read して使う
- **廃止**: 競合ウォッチ（→Webサイト パックのリサーチ）/ ガイド（→ダッシュボードの説明書に統合）/ SNS運用（→docs/sns-ops.md 共通フロー正本 + 媒体別パック）
- **動的パック**: /媒体管理 register 時にワークスペース .claude/commands/ へ媒体コマンド（例: /ワンキャリア）を自動生成
- lint 20/20 OK

## 表裏の切り分け 2026-07-23 — メニュー 13本に圧縮（v0.81.0）

- **登録コマンド 20→13**: パック9（SNS6+媒体管理+Webサイト+広告）+ /定常タスク /ダッシュボード /作業ログ + /検証（配布時削除）
- **内部手順 7（メニュー非表示・機能は維持）**: タスク開始（パックが内部で通す関所）/ 状態確認 / デモ / 機能設定 / スキル化 / メモリ保存 / メモリ圧縮 — session-rules に手順書パス付きの発火導線を明記、自然文で動く
- lint を内部手順許容に改修（登録13+内部7=手順書20 を突合）。registry に内部手順台帳を新設。README は表側（ユーザー向け）記述に統一

## 機能追加 2026-07-23 — /ワーク追加（v0.82.0）

- 新媒体（ワンキャリア/doda等）を1コマンドで運用に載せる: ヒアリング → registry.yaml 登録 → **その場で初期マッピング（フェーズ①・読み取り専用、knowledge/sites/<id>/ 生成）** → ワークスペース .claude/commands/ に専用コマンド自動生成 → 定常ループ提案
- 削除フローも定義（地図は資産として残す）。delve-media の動的コマンド生成節は /ワーク追加 への後方互換ポインタに変更。登録14+内部7=手順書21

## 機能追加 2026-07-23 — /セットアップ（v0.83.0）

- 導入直後の初期ヒアリングをチェックリスト化: ①運用SNS（未選択は packs.conf で sns-<媒体>=off → 提案・自動発火停止） ②生成AIアカウント（accounts.md） ③素材サイト ④求人媒体（→/ワーク追加 接続） ⑤専用DLフォルダ ⑥自社サイト。回答は knowledge/config/setup.yaml に保存
- **コンテキスト経済**: session-start は「未回答時のみ」1行案内を注入。回答済みなら何も注入しない（質問リストは /セットアップ 実行時にだけ読まれる）
- 制約の明記: プラグイン本体のメニュー表示自体は動的に消せない（Cowork 仕様）。実質無効化は packs.conf + ルール注入で実現

## 外部監査反映 2026-07-23 — 公式/GitHub/テックブログ調査の5点実装（v0.84.0）

外部調査（Anthropic公式 skills/blog・awesome系リポジトリ・Cognition/Browserbase/LLM-as-judge 実証等）に基づく強化。Cowork 環境・日本語運用に翻案:
1. **アクション・キャッシング**（Browserbase型）: shortcut_memo を「操作+期待ランドマーク」形式に拡張。再生時はランドマーク照合→一致で決定的実行、不一致で自動フェーズ③（Remap発動を主観に依存させない）
2. **鮮度管理**: knowledge/sites/*/index.md に last_verified/verify_count/confidence フロントマター。30日超過 or low はフェーズ④でも②に落とす陳腐化ポリシー
3. **outcome-verifier 新設（6体目）**: 送信後の証跡検証（VERIFIED: n/m、証跡なき成功を認めない）+ 効果測定（返信率・エンゲージ集計→knowledge/analytics/）。定番ロール欠落（送信後QA・analytics）の補完
4. **監査の較正ループ**: pre-send-verifier が verdict-log.md（人間の差し戻し・見逃し事例）を判定基準に取り込む。「監査は回帰の床、人間承認の代替ではない」を明記（LLM-as-judge の recall 低下実証への対策）
5. **eval ハーネス**: docs/evals.md に golden タスク G1〜G7（執筆3/監査2/ルーティング2、機械判定基準つき）。/検証 full の V27 で実機実行、FAIL は本体修正（タスクを緩めるの禁止）
- 付随: compaction 保存必須リスト（決定/制約/パス/未解決）を /メモリ圧縮 に、First Delve「一番難しいページから」原則を steps-reference に
- 見送り（根拠あり）: 自己修復Healerの自作（工数過大・フェーズ③で代替）/ 並列writerスウォーム（Cognition「Don't Build Multi-Agents」）/ bot検知回避（ToS違反リスク、現行の人間ログイン委譲が業界推奨と一致）

## スキル強化 2026-07-23 — 外部監査の残項目C（v0.85.0）

- **references 11→13**: seo-jp（日本語SEO/AEO — 検索意図設計・E-E-A-T・AI検索対応・診断チェックリスト）/ cro-jp（CRO/ABテスト — 改善優先順位・仮説の型・小母数時は前後比較・ダークパターン禁止）。コミュニティ定番（marketingskills 60+等）のうち採用マーケに効く2領域を日本語圏向けに新設
- **/スキル化 に公式規約チェック**: 生成 SKILL.md の保存前チェックリスト（name規約 / Use when・Not for / 段階的開示5,000語 / 既存との重複禁止）— skill-creator の思想を翻案
- ルーティング配線: session-rules 執筆振り分け・parts/index・page-improve に接続

## UX改善 2026-07-23 — コマンド説明の全面書き直し（v0.85.1）

- 登録15コマンドの description / argument-hint を平易な日本語に全面刷新（「〜をまとめて任せるコマンド」形式 + 引数ヒントは具体例つき: 「やってほしいこと（例: 来週分の投稿ストックを3日分作って）」）
- README から「人材業界パック」指定を撤去し業界非依存の記述に（求人・スカウトは業界を問わない業務のため）。「業種カスタマイズ」→「自社カスタマイズ」

## メニュー統合 2026-07-23 — 質問駆動のコマンド展開（v0.86.0）

- **SNS 6本→/SNS運用 1本に統合**: 媒体名が要望にあれば直行、無ければ「どの媒体？」を選択式で確認（選択肢は setup.yaml で選んだ媒体のみ = セットアップ連携）。媒体別の見える範囲・制約は procedures/delve-sns-*.md に内部手順として全部残る（知識の消失なし）
- **/リサーチ 新設（横断入口）**: 「どの媒体・対象を調べる？」→ SNS/広告/サイトデザイン/サイト品質/徹底/求人市場の各調査手順に振り分け。読み取り専用
- メニュー 15→11本（登録11+内部13=手順書24）。/広告 の対象確認（v0.85.2）と同じ質問駆動パターンに統一
