---
description: プラグイン自己検証 — 検証項目を自動実行し、PASS/FAIL/SKIP の検証報告書を生成する（開発者へのフィードバック用）。Use when ユーザーが「検証して」「セルフテストして」「動作確認して」「プラグインのテストを回して」と求めたとき、またはプラグイン更新後の動作確認時。
argument-hint: [quick（コア項目のみ） | full（全項目）]（省略時は quick）
---

プラグインの自己検証を実行してください。モード: $ARGUMENTS

## 検証の原則

- **読み取り専用・外部無害**: 検証中に実サイトへの送信・投稿・変更は一切しない。ブラウザ検証は example.com のみ使用
- 各項目は PASS / FAIL / SKIP(理由) で判定し、**FAIL には必ず実際のエラーメッセージ・観測事実を添える**（「たぶん」禁止）
- 1項目の失敗で止めない。全項目を消化してから報告する

## 検証項目

### A. 基盤（quick/full 共通）

| # | 項目 | 手順 | PASS基準 |
|---|---|---|---|
| V1 | ブラウザ系統の確認 | 使えるツール系統を列挙 | claude-in-chrome / playwright のどちらが生えているか特定できる |
| V2 | 読み取りフリー | フラグなしで example.com を開き、スクショ or read_page | ゲートにブロックされず取得できる |
| V3 | 変更ゲート | フラグなしで example.com のリンクをクリック試行 | 【Delvework Gate】でブロックされる |
| V4 | ゲート解除フロー | タスク開始手順（procedures/delve-start.md）で「検証テスト」を開始 → 変更前記録 → クリック | 段階的に通る（B-4→E→実行） |
| V5 | Credential Guard | example.com で「パスワード欄に test と入力」を試行（実在フィールド不要、ダミーで可） | 入力系+password語でブロック。※クリックは誤爆しないことも確認 |
| V6 | SQLite 初期化 | templates/db-schema.sql で knowledge/data/delvework.db を初期化し、テーブル一覧を取得（sqlite3 CLI 不在なら python3 の sqlite3 モジュールで代替可） | 9テーブル作成される |
| V7 | テンプレート到達 | report-template.html / design-principles.md を Read（相対→Globフォールバック） | どちらの経路でも実体に到達できる |
| V17 | 台帳整合 | docs/command-registry.md と commands/・procedures/・docs/parts/・references/ の実体を突合 | 登録コマンド13（commands/）+ 内部手順7 = 手順書20（procedures/delve-*.md）が台帳の行と過不足なく一致。部品台帳が docs/parts/ と、リファレンス台帳が references/ と一致し、コマンド全行にカテゴリー（SNS媒体/求人媒体/自社・広告/基盤/記録）が付いている |

### B. 機能（full のみ）

| # | 項目 | 手順 | PASS基準 |
|---|---|---|---|
| V8 | 自然文発火 | このセッションのここまでで、delve コマンドがコマンド名なしの依頼から発火したか振り返り | 事例があれば PASS、なければ「未観測」 |
| V9 | サブエージェント | deliverable-writer に小さな執筆（3行のテスト文書）を委譲 | 起動し成果が返る。使用モデルも記録 |
| V10 | design-artisan モデル | design-artisan を最小タスクで起動 | fable で起動できたか、sonnet フォールバックか記録 |
| V11 | ダッシュボード | /レポート を実行（トップのダッシュボード生成まで） | dashboard-template（浮世絵ヘッダー+旅人）準拠で生成（説明書=旧ガイド統合を含む）、タブ=全体+カテゴリー、停留点数=タブ数、アラート+場所とタスク一覧が実データ。アーティファクト発行（2回目なら同一URL更新） |
| V12 | 部品庫到達 | docs/parts/index.md を Read し、表の部品から2つ（imagegen / design-sync）を Read | 部品に到達でき、実行粒度3段の原則が読める |
| V13 | Pack制御 | packs.conf に deep=off を書き→挙動確認→元に戻す | 無効通知が次セッションに出る（今セッションでは conf の読み書きのみ確認） |
| V14 | 日本語コマンド | /レポート を実行 | 日本語名で発火する。あわせて内部手順（「今どうなってる？」→ delve-status）が自然文で発火することを確認 |
| V15 | スキル化 | ダミー手順（「検証用: example.comを開いて閉じる」）を「これ覚えて」で内部スキル化手順に | .claude/skills/ に生成され、frontmatter が規約通り |
| V16 | Slack | Slack ツールの有無を確認、あればテスト通知1件 | 到達 or 「コネクタ未接続」を記録 |
| V18 | タスク登録 | /カスタマイズ でタスク登録 verify-loop（内容: example.com を開いて見出しを確認するだけの読み取り専用タスク・cadence「手動」）| tasks/verify-loop.yaml と knowledge/config/loops.yaml が task-template.yaml のスキーマ準拠で生成される |
| V19 | タスクYAML実行連携 | 「verify-loop やって」と依頼 | delve-start が tasks/verify-loop.yaml を Read し、その steps を実行計画に使う（読み取り専用なので承認不要で完走）。終了後 /カスタマイズ のタスク削除で verify-loop を掃除し、YAML と loops 行が消えることまで確認 |
| V20 | Money Watch | 「決済・お支払い方法」等の watchlist 語を含むローカルHTML（file:// か data: で自作）を read_page/snapshot で読み取り → 変更操作を試行 → 検証後 `rm memory/.workflow/money_alert` | 読み取り直後に【Money Watch】警告が注入され、money_alert が生成され、変更操作が deny される。**日本語語句（Unicodeエスケープ経由）でも検知されること** |
| V21 | strategy-advisor | ダミーのタスクYAML案を渡して壁打ち | VERDICT（GO/GO-WITH-CHANGES/RETHINK）形式で助言が返る |
| V22 | pre-send-verifier | ダミー送信計画（本文+宛先2件、うち1件をわざと基準違反に）を渡して監査 | VERDICT: NO-GO/GO-WITH-FIXES が返り、違反の1件を根拠つきで FAIL 指摘する |
| V23 | steps正本到達 | docs/steps-reference.md を Read（${CLAUDE_PLUGIN_ROOT} → Glob フォールバック） | 到達でき、CP定義（E-3）とログスキーマ（I-3）の節が読める |

### C. 後片付け

- 検証で作ったフラグ・ダミースキル・テストデータを削除（delvework.db は残してよい）
- session-log に検証実施を1行記録

### D. 機械チェック（quick/full 共通・環境に bash/python があれば）

| # | 項目 | 手順 | PASS基準 |
|---|---|---|---|
| V24 | lint | `python3 scripts/lint.py`（プラグインルートで。python3 不在なら python） | `lint: OK`（参照整合・frontmatter・台帳・バージョン一致） |
| V25 | hooks回帰 | `bash scripts/test-hooks.sh` | `test-hooks: ALL PASS`（防御系） |
| V26 | 画像/動画テンプレ | ダミー画像で `templates/banner-compose.py`（--headline 指定）・`templates/chromakey.py`（緑背景→透過PNG）・`templates/guide-anim.py`（スクショ+steps.json→フレーム生成、ffmpeg あれば mp4/GIF まで）を実行 | 3本ともエラーなく出力生成（chromakey は四隅 alpha=0・被写体 alpha=255） |

実行不可の環境（bash/python なし）では SKIP(理由) とし、CI（GitHub Actions）の最新結果に言及する。

### E. 評価ハーネス（full のみ）

| # | 項目 | 手順 | PASS基準 |
|---|---|---|---|
| V27 | golden タスク | docs/evals.md の G1〜G7 を実行 | 各タスクの PASS 基準（機械判定）を満たす。FAIL は evals.md の運用に従い本体を修正して記録 |

## 報告書（必ず2形式）

1. **チャット内サマリー**: PASS/FAIL/SKIP の集計 + FAIL の詳細
2. **開発者向け報告書**（そのままコピペで開発側に渡せる形式）を `knowledge/verification/<date>-verify.md` に保存し、内容をコードブロックでチャットにも表示:

```
## Delvework 検証報告 <date> / plugin vX.Y.Z / 環境: Cowork|ClaudeCode
| # | 項目 | 結果 | 証跡 |
|---|---|---|---|
| V1 | ... | PASS/FAIL/SKIP | 観測事実・エラー原文 |
### FAIL詳細
- V◯: <再現手順 / エラー原文 / 推定原因>
### 環境メモ
- ツール系統: ... / フォルダ接続: 有無 / 特記事項
```

アーティファクト発行が可能なら報告書も発行して URL を添える。

**full モードではさらに**: docs/conventions.md 準拠の HTMLレポート（report-template 骨格。集計サマリー・カテゴリ別 PASS/FAIL 表・FAIL詳細・環境メモ）を `knowledge/reports/verify-<date>.html` に生成し、成果物として必ず届ける（アーティファクト発行→不可ならファイル送信→不可なら保存パス明示）。
