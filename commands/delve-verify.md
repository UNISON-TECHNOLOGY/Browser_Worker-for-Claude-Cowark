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
| V4 | ゲート解除フロー | /delve-start 検証テスト → 変更前記録 → クリック | 段階的に通る（B-4→E→実行） |
| V5 | Credential Guard | example.com で「パスワード欄に test と入力」を試行（実在フィールド不要、ダミーで可） | 入力系+password語でブロック。※クリックは誤爆しないことも確認 |
| V6 | SQLite 初期化 | templates/db-schema.sql で knowledge/data/delvework.db を初期化し、テーブル一覧を取得 | 9テーブル作成される |
| V7 | テンプレート到達 | report-template.html / design-principles.md を Read（相対→Globフォールバック） | どちらの経路でも実体に到達できる |
| V17 | 台帳整合 | docs/command-registry.md と commands/ の実体を突合 | 本体と日本語エイリアスが1対1で、台帳の行と過不足なく一致 |

### B. 機能（full のみ）

| # | 項目 | 手順 | PASS基準 |
|---|---|---|---|
| V8 | 自然文発火 | このセッションのここまでで、delve コマンドがコマンド名なしの依頼から発火したか振り返り | 事例があれば PASS、なければ「未観測」 |
| V9 | サブエージェント | deliverable-writer に小さな執筆（3行のテスト文書）を委譲 | 起動し成果が返る。使用モデルも記録 |
| V10 | design-artisan モデル | design-artisan を最小タスクで起動 | fable で起動できたか、sonnet フォールバックか記録 |
| V11 | ダッシュボード | /delve-dashboard を実行 | HTML生成+アーティファクト発行（2回目なら同一URL更新） |
| V12 | ガイド | /delve-guide を実行 | Pack状態が反映されたガイドが発行される |
| V13 | Pack制御 | packs.conf に deep=off を書き→挙動確認→元に戻す | 無効通知が次セッションに出る（今セッションでは conf の読み書きのみ確認） |
| V14 | 日本語コマンド | /状態確認 を実行 | 日本語名で発火する |
| V15 | スキル化 | ダミー手順（「検証用: example.comを開いて閉じる」）を /delve-skillify | .claude/skills/ に生成され、frontmatter が規約通り |
| V16 | Slack | Slack ツールの有無を確認、あればテスト通知1件 | 到達 or 「コネクタ未接続」を記録 |

### C. 後片付け

- 検証で作ったフラグ・ダミースキル・テストデータを削除（delvework.db は残してよい）
- session-log に検証実施を1行記録

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
