# /広告 — 広告制作・分析のカテゴリーパック（delve-ads）

要望を受けて実行粒度（docs/parts/index.md の3段）を判定し、タスク5型に振り分ける。各タスクは docs/parts/ の部品を Read して従う。

| 要望の型 | タスク | 部品 |
|---|---|---|
| 「競合広告/訴求を洗い出して」 | リサーチ | docs/parts/deep-research.md / docs/parts/sns-research.md（TikTok Creative Center 含む） |
| 「バナー用の素材/動画素材を探して」 | 収集 | docs/parts/asset-collect.md / docs/parts/video-asset-collect.md |
| 「画像/動画を生成して」 | クリエイティブ | docs/parts/imagegen.md / docs/parts/videogen.md |
| 「バナーにして」「背景を消して」「WebM/透過動画に」 | クリエイティブ | docs/parts/image-edit.md / docs/parts/video-edit.md |
| 「このバナーからLP作って」 | クリエイティブ | docs/parts/ad-to-lp.md |
| 「TikTok広告の台本」「動画のフック案」 | クリエイティブ | docs/parts/video-ad-script.md |
| 「Design/Canvaへ」「入稿準備」 | 掃き出し | docs/parts/design-sync.md / docs/parts/canva-export.md |

- 公開向けコピー・クリエイティブは references/ad-compliance-jp/SKILL.md のチェック必須
- 広告出稿・課金は AI 禁止（Money Watch / URL Guard）。入稿など不可逆送出は pre-send-verifier 監査 + ユーザー承認
- 技術地図（形式・レシピ・素材パック）は docs/media-pipeline.md
