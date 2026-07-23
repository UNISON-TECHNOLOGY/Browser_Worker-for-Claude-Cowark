# 共有部品庫（docs/parts/）— タスク5型 × 部品の正本

コマンド（カテゴリー）は媒体・対象ごと。動詞（リサーチ/収集/クリエイティブ/分析/掃き出し）はタスクレベルで、**各パックのタスクがここの部品を Read して使う**。単発依頼（「Geminiで画像作って」等）もここへ直接ルーティングしてよい（変更操作は /タスク開始 のゲート下）。

## 実行粒度の3段（全パック共通の振り分け原則）

1. **タスク単体で完結** — 要望が1動詞なら該当部品だけ実行（例:「速度測って」→分析のみ）
2. **ワークフローで解決** — 要望が連なりなら タスクを連結（例:「診断して改善案まで」→分析→クリエイティブ→掃き出し）
3. **まるっと** — カテゴリー丸ごとの依頼はパックの定常ループ一式を回す（例:「Xの運用よろしく」）

| タスク型 | 部品 |
|---|---|
| リサーチ | style-research.md（デザイン・配色） / deep-research.md（徹底洗い出し） / sns-research.md（SNSトレンド・競合） |
| 収集 | asset-collect.md（画像素材・ライセンス証跡） / video-asset-collect.md（動画素材） |
| クリエイティブ | jobpost-writing.md（求人票） / scoutmail-writing.md（スカウト文面） / imagegen.md（画像生成・Gemini実証） / videogen.md（動画生成・Gemini実証） / image-edit.md（バナー合成・クロマキー） / video-edit.md（WebM・アルファ・注釈アニメ） / page-improve.md（ページ改善モック） / ad-to-lp.md（広告→LP） / video-ad-script.md（動画広告台本） |
| 分析 | site-audit.md（速度・SEO・品質） / sns-research.md（数値読み） / 各媒体パックの分析タスク |
| 掃き出し | design-sync.md（Claude Design 同期・既定ルート） / canva-export.md（Canva 書き出し） / 各媒体の投稿・配信・入稿（必ず /タスク開始 経由 + 不可逆なら pre-send-verifier） |

メディア系の技術地図（ffmpegレシピ・形式カバレッジ・素材パック規約）は docs/media-pipeline.md が正本。

## ルーティング一覧（タスク5型 × スキル・サブエージェント）

| タスク型 | 読む執筆リファレンス（references/） | 呼ぶサブエージェント |
|---|---|---|
| リサーチ | logical-writing（レポート化するとき） | 大規模並列調査のみ調査系サブエージェントに分割 |
| 収集 | —（ライセンスCPが規範） | — |
| クリエイティブ（文章） | recruit / copy / sales / logical / business / storytelling / sns-jp / content-design / video-ad を依頼内容で選択 | 本格執筆は **deliverable-writer** へ委譲 |
| クリエイティブ（画像・動画・ページ） | web-design + 公開物は ad-compliance-jp 必須 | モックアップは **design-artisan**（生成）→ **design-critic**（審査）のループ |
| 分析 | logical-writing | 効果測定（返信率・エンゲージ集計）は **outcome-verifier** |
| 掃き出し | —（不可逆送出の規律が規範） | 不可逆な一括送出は **pre-send-verifier**（敵対的監査）必須 → ユーザー承認 → 完了後に **outcome-verifier**（証跡検証） |
| （横断）設計判断 | — | 長く効く判断・確信のない分岐は **strategy-advisor** に壁打ち（session-rules (11)(12)） |

