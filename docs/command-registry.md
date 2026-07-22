# コマンド台帳（Command Registry）

**このファイルがコマンド一覧の正本。** コマンドの追加・改名・削除は必ずここを同時に更新する。
`/delve-verify` はこの台帳と `commands/` の実体の突合を検証項目に含める。

## 命名ルール

1. **本体は英語ケバブケース**（`delve-*.md`）— 手順の実体はここだけに書く
2. **日本語エイリアスを必ず対で作る** — 薄いラッパー（本体を Read して従う + Glob フォールバック）。本体と1対1で、片方だけの追加は禁止
3. エイリアスの description は「/delve-◯◯ の日本語エイリアス。<一言要約>」形式、argument-hint は本体の短縮版（日本語）
4. `/delve-skillify` が生成するワークスペーススキルも同ルール: name は英語ケバブ、description の発火例は**日本語の言い方**で書く

## 台帳

| 本体 | 日本語名 | Pack | 分類 | 代表的な言い方 |
|---|---|---|---|---|
| delve-start | タスク開始 | core | 運用 | 「◯◯を更新して」（変更操作の前段） |
| delve-status | 状態確認 | core | 設定・確認 | 「今どうなってる？」 |
| delve-report | 作業レポート | core | 運用 | 「今日の作業まとめて」 |
| delve-audit | サイト診断 | research | 調査 | 「表示速度を測って」 |
| delve-style | スタイル調査 | research | 調査 | 「このサイトのデザイン調べて」 |
| delve-watch | 競合ウォッチ | research | 調査 | 「競合を監視して」 |
| delve-deep | 徹底モード | deep | 調査 | 「徹底的に洗い出して」 |
| delve-improve | ページ改善 | creative | 作る | 「このLPを改善して」 |
| delve-adlp | 広告からLP | creative | 作る | 「このバナーからLP作って」 |
| delve-adscript | 動画広告 | creative | 作る | 「TikTok広告の台本作って」 |
| delve-sns | SNS運用 | sns | 運用 | 「Xの投稿ストック作って」 |
| delve-media | 媒体管理 | media | 運用 | 「全媒体の状況を見せて」 |
| delve-dashboard | ダッシュボード | core | 設定・確認 | 「ダッシュボード見せて」 |
| delve-guide | ガイド | core | 設定・確認 | 「操作ガイド作って」 |
| delve-demo | デモ | core | 設定・確認 | 「何ができるの？」 |
| delve-config | 機能設定 | core | 設定・確認 | 「SNS機能を切って」 |
| delve-skillify | スキル化 | core | 学ばせる | 「これ覚えて」 |
| delve-feedback | フィードバック | core | 学ばせる | 「ここはNG、次からこうして」 |
| delve-verify | 検証 | core | 設定・確認 | 「プラグインを検証して」 |

**計: 本体 19 / 日本語エイリアス 19**（1対1で完全対応）

## 追加時のチェックリスト

- [ ] `commands/delve-<name>.md`（本体、description に Use when + 言い方）
- [ ] `commands/<日本語名>.md`（エイリアス、Glob フォールバック付き）
- [ ] この台帳に1行追加（Pack 分類を決める）
- [ ] `delve-guide` は台帳駆動なので追加作業なし（次回生成で反映）
- [ ] README のコマンド数を更新
- [ ] 両 version ファイルを bump
