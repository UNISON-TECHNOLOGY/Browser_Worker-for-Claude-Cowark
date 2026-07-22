# テスト計画 — v0.8.0 スモークテスト

対象環境: Claude Cowork（デスクトップ）/ プラグイン v0.8.0 / フォルダ未接続のクラウド作業領域で可

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
| T7 | `/delve-style <参考サイトURL>` | 巡回→トークンJSON生成→**deliverable-writer（Opus）に委譲**→比較HTMLレポート生成 |
| T8 | T7 の実行ログで委譲を確認 | Agent ツールで deliverable-writer が起動し、モデルが opus になっている |
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

## 記録ルール

- 各テストの結果（✅/❌ + 気づき）をこのファイルに追記して commit する
- ❌ の場合は画面表示・エラーメッセージ・使われたツール名をそのまま記録する
