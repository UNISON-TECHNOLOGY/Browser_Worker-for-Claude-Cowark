# 台帳（Registry）── 4層アーキテクチャの正本

**このファイルがコマンド・部品・定常ループの一覧の正本。** 追加・改名・削除は必ずここを同時に更新する。
`/検証` はこの台帳と `commands/`・`procedures/`・`docs/parts/`・`references/` の実体の突合を検証項目に含める。

## 構造の芯 — 4層アーキテクチャ（2026-07-23 ユーザー決定で確定）

| 層 | 概念 | 実体 |
|---|---|---|
| **コマンド** | カテゴリーレベル（媒体・対象のタスクパック）。要望は引数に自由に書かせる | `commands/`（20本・日本語名）+ `procedures/delve-*.md`（1対1） |
| **ワークフロー** | 進め方 = タスクの連なり。A〜K 実行チェーン + タスク5型の連結 | `docs/steps-reference.md` + hooks のゲート + フェーズ①〜④ |
| **タスク** | 単一の仕事。動詞レベル: **リサーチ / 収集 / クリエイティブ / 分析 / 掃き出し** | `tasks/*.yaml`（/定常タスク が登録）+ `docs/parts/`（部品） |
| **サブエージェント** | 専門作業の職人。タスクから呼ばれる | `agents/`（5体: writer / artisan / critic / advisor / verifier） |

**実行粒度の3段**（全パック共通）: ①タスク単体で完結 ②ワークフローで解決（タスク連結） ③まるっと（パックの定常ループ一式）。振り分け原則は `docs/parts/index.md`。

新しい媒体を増やす＝パック1個追加。できることを増やす＝部品（docs/parts/）の追加。**エンジン側（ワークフロー層）は一切変えない。**

**動的パック**: 求人媒体の個別コマンド（例: /ワンキャリア）は /媒体管理 register 時にワークスペースの `.claude/commands/` へ自動生成する（プラグイン20本は増やさない。delve-media の「動的コマンド生成」節参照）。

## 命名ルール

1. **登録コマンド（`commands/`）は日本語名が本体** — メニューに並ぶのはこの20本のみ。description には自動発火用の「Use when」を日本語で書く
2. **手順の正本は `procedures/delve-*.md`（英語ケバブケース、登録対象外）** — 日本語コマンドは薄いラッパー（procedures を Read + Glob フォールバック）。1対1で、片方だけの追加は禁止
3. 部品（docs/parts/）はコマンド登録しない。パックのタスクが Read して使う
4. `/スキル化` が生成するワークスペーススキルも同ルール: name は英語ケバブ、description の発火例は日本語の言い方で書く

## コマンド台帳（20本）

| 手順書（procedures/） | コマンド名（登録） | カテゴリー | Pack | 代表的な言い方 |
|---|---|---|---|---|
| delve-sns-x | X運用 | SNS媒体 | sns | 「Xの投稿ストック作って」 |
| delve-sns-instagram | Instagram運用 | SNS媒体 | sns | 「インスタの投稿作って」 |
| delve-sns-tiktok | TikTok運用 | SNS媒体 | sns | 「TikTokの企画して」 |
| delve-sns-note | note運用 | SNS媒体 | sns | 「noteを書いて」 |
| delve-sns-youtube | YouTube運用 | SNS媒体 | sns | 「YouTubeの台本作って」 |
| delve-sns-line | LINE運用 | SNS媒体 | sns | 「LINEの配信を作って」 |
| delve-media | 媒体管理 | 求人媒体 | media | 「全媒体の状況見せて」「スカウト送って」 |
| delve-website | Webサイト | 自社・広告 | research | 「表示速度を測って」「このLP改善して」 |
| delve-ads | 広告 | 自社・広告 | creative | 「バナー作って」「競合広告を洗い出して」 |
| delve-task | 定常タスク | 基盤 | core | 「毎朝◯◯するタスクを追加して」 |
| delve-dashboard | ダッシュボード | 基盤 | core | 「ダッシュボード見せて」（説明書=ガイド統合） |
| delve-report | 作業ログ | 記録 | core | 「今日の作業まとめて」 |
| delve-verify | 検証 | 記録 | core | 「プラグインを検証して」※開発用 — 配布時には削除する |

**計: 登録コマンド 13 / 内部手順 7 / 手順書 20（procedures/）**

## 内部手順台帳（メニュー非表示 — 自然文・ルール発火で動く。手順書は procedures/ に残す）

| 手順書 | 旧コマンド名 | 発火のさせ方 |
|---|---|---|
| delve-start | （内部）タスク開始 | 変更操作の前段として各パックが内部で通す関所（session-rules (1)） |
| delve-status | （内部）状態確認 | 「今どうなってる？」等の自然文（session-rules (8)） |
| delve-demo | （内部）デモ | 「何ができるの？」→ ダッシュボードの説明書へ誘導 |
| delve-config | （内部）機能設定 | 「SNS機能を切って」等の自然文 |
| delve-skillify | （内部）スキル化 | 手順を教わった・同一パターン2回目の自動検知（session-rules (3c)） |
| delve-feedback | （内部）メモリ保存 | 成果物への評価・修正指示の自動検知（session-rules (3b)） |
| delve-memory | （内部）メモリ圧縮 | 「ログを整理して」/ session-log 肥大時に提案 |

## 部品台帳（docs/parts/ — タスク5型。詳細は docs/parts/index.md が正本）

| タスク型 | 部品 |
|---|---|
| リサーチ | style-research / deep-research / sns-research |
| 収集 | asset-collect / video-asset-collect |
| クリエイティブ | jobpost-writing / scoutmail-writing / imagegen / videogen / image-edit / video-edit / page-improve / ad-to-lp / video-ad-script |
| 分析 | site-audit / sns-research（数値読み） |
| 掃き出し | design-sync / canva-export |

SNS 共通運用フローは `docs/sns-ops.md`、メディア技術地図は `docs/media-pipeline.md` が正本。

## 執筆リファレンス台帳（references/ — スキル一覧には登録しない内部教科書）

> 登録方針: references/ は**全て Read 専用**（skills/ 規約に置かず自動発火させない）。ワークスペース側で同名スキルが Skill 登録されている場合も正本はプラグインの references/ とし、更新はこちらに行う（二重管理の乖離防止）。

| リファレンス | 主な使い手 | 用途 |
|---|---|---|
| logical-writing | Webサイト・全パックのレポート | 分析レポート・戦略提案 |
| sns-jp | SNS媒体パック | 日本のSNS文化・ハッシュタグ・投稿時間帯・LINE配信設計 |
| content-design | SNS媒体パック | 投稿コンテンツの設計・カレンダー |
| storytelling | SNS媒体・求人媒体 | 社員ストーリー・採用広報記事 |
| recruit-writing | 求人媒体（jobpost/scoutmail 部品） | 求人原稿・スカウト本文 |
| copywriting | 広告・求人媒体・SNS | キャッチコピー・件名13字 |
| video-ad | 広告 | 動画広告の構成・台本 |
| ad-compliance-jp | 広告・全公開物 | 日本の広告表現規制チェック |
| web-design | Webサイト・広告 | LP/ページのデザイン実装 |
| business-writing | 基盤 | 社内外メール・事務連絡・校正 |
| sales-writing | 基盤 | 受注目的の提案書・テレアポ |

## 定常ループ台帳（標準セット。実運用の正本はワークスペースの `knowledge/config/loops.yaml` — /定常タスク が登録・管理）

| カテゴリー | ループ | 標準周期 | 使うコマンド | 締め |
|---|---|---|---|---|
| 自社・広告 | 自社サイト診断 | 週次（月曜） | Webサイト | ダッシュボード更新 |
| SNS媒体 | 予約投稿・実績記録 | 毎朝 | 各運用パック | 同上 |
| SNS媒体 | ストック補充 | 週次 or 残量アラート時 | 各運用パック | 同上 |
| 求人媒体 | 媒体ステータス巡回 | 毎朝 | 媒体管理 | 同上 |
| 求人媒体 | スカウト送信 | 平日（承認後のみ送信） | 媒体管理 + タスク開始 | 同上 |
| 広告 | 広告リサーチ・制作 | 依頼時（定常化も可） | 広告 | 同上 |

**原則1: 実行系（変更操作）は全カテゴリー共通で `delve-start` が担う**（A〜Kワークフロー + 変更前記録/承認の関所）。パック別の実行コマンドは新設しない。

**原則2: 各ループの締めに `delve-dashboard` を実行**し、司令塔を常に最新へ。

**原則3: 最適化（フェーズ④）は標準の裏側動作** — マッピングとタスク順序を記録し、成功の繰り返しで最短ルート整備・スクリプト化を自動で提案する（バックグラウンドエージェントへの委譲可）。ユーザーが頼まなくても走る。

## カテゴリー → knowledge/ フォルダ対応

| カテゴリー | 主な保存先 |
|---|---|
| SNS媒体 | knowledge/sns/<platform>/（ネタ帳は queue.md、調査は research/） |
| 求人媒体 | knowledge/media/・approvals/・drafts/ |
| 自社・広告 | knowledge/audits/・styles/・mockups/・assets/・drafts/ |
| 基盤・記録（横断） | knowledge/sites/・logs/・reports/・tacit/・feedback/・data/・config/・artifacts-index.md |

## 追加時のチェックリスト

- [ ] 新しい媒体 → `commands/<日本語名>.md` + `procedures/delve-<name>.md`（パック。部品への振り分け表を持つ）
- [ ] 新しい能力 → `docs/parts/<name>.md`（部品）+ parts/index.md に行追加。**コマンドは増やさない**
- [ ] この台帳に1行追加（カテゴリー + Pack）
- [ ] 定常実行するものはループ台帳にも追加
- [ ] README のコマンド数を更新
- [ ] 両 version ファイルを bump
