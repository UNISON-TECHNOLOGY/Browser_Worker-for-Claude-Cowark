# 台帳（Registry）── ドメイン基準の正本

**このファイルがコマンド・スキル・定常ループの一覧の正本。** 追加・改名・削除は必ずここを同時に更新する。
`/検証` はこの台帳と `commands/`・`procedures/`・`references/` の実体の突合を検証項目に含める。

## 構造の芯 — 2層アーキテクチャ（2026-07-22 確定）

> ブラウザワーカーの思想は「まずちゃんとマッピングして、徐々に最速化する」仕組み。
> その上に「スカウト送りたい」「SNS投稿したい」が載っているだけ。

| 層 | 中身 | 実体 |
|---|---|---|
| **エンジン層**（本体） | 触ってマッピング（①初回）→ 地図を残す → 再訪で厚くする（②）→ 構造変化に追随（③）→ 最短手順に収束（④最適化）。変更前記録と人の承認の関所 | delve-start（A〜K）/ knowledge/sites/ / hooks のゲート / フェーズ①〜④ |
| **荷物層**（用途） | やりたいこと。下のドメイン分類はすべてこの層 | tasks/*.yaml / スキル / ドメイン別コマンド |

**/定常タスク は荷物をエンジンに載せる積み込み口**。新しい用途を増やすとき、エンジン側は一切変えない。

## 分類軸（荷物層の整理。2026-07-22 ユーザー指定で確定）

荷物は**事業ドメイン**で分類する。種類（調査/作る/運用）ではなくドメインが第一軸:

| ドメイン | 中身 |
|---|---|
| **企画リサーチ** | サイトの構想抽出（競合ウォッチ・サイト診断・スタイル調査・徹底調査） |
| **SNS運用** | レポート / 投稿 / ストック |
| **求人媒体** | スカウト / 求人更新 / 掲載枠・応募管理 |
| **広告分析** | LP / 動画広告の分析・制作 |
| **基盤** | どのドメインでも使う共通機能（開始・状態・学習・設定・ダッシュボード等） |

ダッシュボードのタブもこのドメインで切る（dashboard-design.md）。

## 命名ルール

1. **登録コマンド（`commands/`）は日本語名が本体** — ユーザーのメニューに並ぶのはこの20本のみ。description には自動発火用の「Use when」を日本語で書く
2. **手順の正本は `procedures/delve-*.md`（英語ケバブケース、登録対象外）** — 日本語コマンドは薄いラッパー（procedures を Read して従う + Glob フォールバック）。1対1で、片方だけの追加は禁止
3. コマンドの description 末尾に「（英語名: /delve-◯◯。手順の正本は procedures/delve-◯◯.md）」を付記する
4. `/スキル化` が生成するワークスペーススキルも同ルール: name は英語ケバブ、description の発火例は**日本語の言い方**で書く。**所属ドメインを SKILL.md の frontmatter か冒頭に明記する**

## コマンド台帳

| 手順書（procedures/） | コマンド名（登録） | ドメイン | Pack | 代表的な言い方 |
|---|---|---|---|---|
| delve-watch | 競合ウォッチ | 企画リサーチ | research | 「競合を監視して」 |
| delve-audit | サイト診断 | 企画リサーチ | research | 「表示速度を測って」 |
| delve-style | スタイル調査 | 企画リサーチ | research | 「このサイトのデザイン調べて」 |
| delve-deep | 徹底モード | 企画リサーチ | deep | 「徹底的に洗い出して」 |
| delve-sns | SNS運用 | SNS運用 | sns | 「Xの投稿ストック作って」 |
| delve-media | 媒体管理 | 求人媒体 | media | 「全媒体の状況を見せて」 |
| delve-improve | ページ改善 | 広告分析 | creative | 「このLPを改善して」 |
| delve-adlp | 広告からLP | 広告分析 | creative | 「このバナーからLP作って」 |
| delve-adscript | 動画広告 | 広告分析 | creative | 「TikTok広告の台本作って」 |
| delve-assets | 素材探し | 広告分析 | creative | 「バナー用の素材探して」 |
| delve-canva | キャンバ | 広告分析 | creative | 「Canvaで作って書き出して」 |
| delve-imagegen | 画像生成 | 広告分析 | creative | 「Geminiで画像作って」 |
| delve-start | タスク開始 | 基盤 | core | 「◯◯を更新して」(変更操作の前段) |
| delve-task | 定常タスク | 基盤 | core | 「毎朝◯◯するタスクを追加して」 |
| delve-status | 状態確認 | 基盤 | core | 「今どうなってる？」 |
| delve-report | 作業レポート | 基盤 | core | 「今日の作業まとめて」 |
| delve-dashboard | ダッシュボード | 基盤 | core | 「ダッシュボード見せて」 |
| delve-guide | ガイド | 基盤 | core | 「操作ガイド作って」 |
| delve-demo | デモ | 基盤 | core | 「何ができるの？」 |
| delve-config | 機能設定 | 基盤 | core | 「SNS機能を切って」 |
| delve-skillify | スキル化 | 基盤 | core | 「これ覚えて」 |
| delve-feedback | フィードバック | 基盤 | core | 「ここはNG、次からこうして」 |
| delve-verify | 検証 | 基盤 | core | 「プラグインを検証して」 |

**計: 日本語コマンド 23（登録） / 手順書 23（procedures/）**（1対1で完全対応）

## 執筆リファレンス台帳（references/ — スキル一覧には登録しない内部教科書）

> 登録方針: references/ は**全て Read 専用**（skills/ 規約に置かず自動発火させない）。ワークスペース側で同名スキルが Skill 登録されている場合も正本はプラグインの references/ とし、更新はこちらに行う（二重管理の乖離防止）。

| リファレンス | ドメイン | 用途（共用先） |
|---|---|---|
| logical-writing | 企画リサーチ | 分析レポート・戦略提案（全ドメインのレポートで共用） |
| sns-jp | SNS運用 | 日本のSNS文化・ハッシュタグ・投稿時間帯 |
| content-design | SNS運用 | 投稿コンテンツの設計・カレンダー |
| storytelling | SNS運用 | 社員ストーリー・採用広報記事（求人媒体と共用） |
| recruit-writing | 求人媒体 | 求人原稿・スカウト本文 |
| copywriting | 広告分析 | キャッチコピー・件名13字（求人媒体・SNSと共用） |
| video-ad | 広告分析 | 動画広告の構成・台本 |
| ad-compliance-jp | 広告分析 | 日本の広告表現規制チェック |
| web-design | 広告分析 | LP/ページのデザイン実装（企画リサーチと共用） |
| business-writing | 基盤 | 社内外メール・事務連絡・校正 |
| sales-writing | 基盤 | 受注目的の提案書・テレアポ |

## 定常ループ台帳（標準セット。実運用の正本はワークスペースの `knowledge/config/loops.yaml` — /定常タスク が登録・管理）

| ドメイン | ループ | 標準周期 | 使うコマンド | 締め |
|---|---|---|---|---|
| 企画リサーチ | 競合巡回 | 毎朝 | delve-watch | ダッシュボード更新 |
| 企画リサーチ | 自社サイト診断 | 週次（月曜） | delve-audit | 同上 |
| SNS運用 | 予約投稿・実績記録 | 毎朝 | delve-sns | 同上 |
| SNS運用 | ストック補充 | 週次 or 残量アラート時 | delve-sns | 同上 |
| 求人媒体 | 媒体ステータス巡回 | 毎朝 | delve-media | 同上 |
| 求人媒体 | スカウト送信 | 平日（承認後のみ送信） | delve-media + delve-start | 同上 |
| 広告分析 | LP/動画分析 | 依頼時（定常化も可） | delve-adlp / delve-adscript / delve-improve | 同上 |

**原則1: 実行系は全ドメイン共通で `delve-start` が担う**（A〜Kワークフロー + 変更前記録/承認の関所）。
スカウト送信・求人更新・予約投稿などの変更操作はすべて delve-start のタスクとして走らせる。
**ドメイン別の実行コマンドは新設しない**（2026-07-22 ユーザー決定「実行系はそもそもこの中にある」）。
文面はスキルの自動発火で賄う（スカウト本文=recruit-writing、投稿=content-design/sns-jp 等）。

**原則2: 各ループの締めに `delve-dashboard` を実行**し、司令塔を常に最新へ。

## ドメイン → knowledge/ フォルダ対応

knowledge/ の物理フォルダは記録の種類別（変更しない。既存ワークスペース互換のため）。
ドメインから引くときはこの表を使う:

| ドメイン | 主な保存先 |
|---|---|
| 企画リサーチ | knowledge/watch/・audits/・styles/・sites/ |
| SNS運用 | knowledge/sns/（ネタ帳は sns/<platform>/queue.md に一本化） |
| 求人媒体 | knowledge/media/・approvals/・drafts/ |
| 広告分析 | knowledge/styles/・mockups/・drafts/・assets/ |
| 基盤（横断） | knowledge/sites/・logs/・reports/・tacit/・feedback/・data/・config/・artifacts-index.md |

## 追加時のチェックリスト

- [ ] `commands/<日本語名>.md`（本体。description に Use when + 言い方、本文は procedures/delve-<name>.md への Glob フォールバック付き参照。**commands/delve-*.md は作らない** — 命名ルール参照）
- [ ] `procedures/delve-<name>.md`（手順の正本）
- [ ] この台帳に1行追加（**ドメインを決める** + Pack）
- [ ] 定常実行するものはループ台帳にも追加
- [ ] `delve-guide` は台帳駆動なので追加作業なし（次回生成で反映）
- [ ] README のコマンド数を更新
- [ ] 両 version ファイルを bump
