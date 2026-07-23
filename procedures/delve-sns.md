# /SNS運用 — SNS媒体の統合入口（delve-sns）

## 0. どの媒体？（曖昧なときだけ聞く）

要望に媒体名（X/Twitter・インスタ・TikTok・note・YouTube・LINE）が含まれていればそのまま該当手順へ。含まれていなければ質問ツールで「どの媒体？」を選択肢で確認する（**複数選択可** — 「全SNSのストック確認」のような依頼は複数選び、媒体ごとに順次実行）。**選択肢は knowledge/config/setup.yaml の sns リスト（使うと答えた媒体）だけを出す**（未設定なら全媒体を出し、回答を setup.yaml に反映）。

## 1. 媒体別手順へ振り分け

| 媒体 | 手順書（見える範囲・制約・固有ルールの正本） |
|---|---|
| X | procedures/delve-sns-x.md |
| Instagram | procedures/delve-sns-instagram.md |
| TikTok | procedures/delve-sns-tiktok.md |
| note | procedures/delve-sns-note.md |
| YouTube | procedures/delve-sns-youtube.md |
| LINE公式 | procedures/delve-sns-line.md |

複数媒体まとめて（「全SNSのストック確認」等）は媒体ごとに順に実行し、締めで outcome-verifier の集計とダッシュボード更新につなぐ。

## 2. 共通フロー

各媒体手順は docs/sns-ops.md（実態照合→生成→予約/下書き→実績記録）に従う。投稿・予約・配信の変更操作はタスク開始手順（procedures/delve-start.md）のゲート下。LINE の配信実行は pre-send-verifier 監査 + ユーザー承認 + 費用見積もりが必須。
