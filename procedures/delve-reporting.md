# /レポート — 状況確認とレポートの統合入口（delve-reporting）

## 構成: トップは状況サマリー（チャット）

引数の指定がなければ、まず**運用全体の状況サマリー**をチャットのテキストで提示する（HTML・アーティファクトは作らない）。そのうえで追加の生成を選択肢で提案する:

1. **作業ログ** — 今日/期間にやった作業のHTML報告書 → procedures/delve-report.md
2. **運用レポート** — 期間の効果測定（スカウト送信→返信率 / SNS投稿→エンゲージ / LINE配信→開封）。outcome-verifier に集計させ、logical-writing + docs/conventions.md 準拠でレポート化。knowledge/analytics/ に記録
3. **全体状況だけでよい** — サマリーで終了

## 状況サマリーの内容（あるものだけ。ソースが無い項目は省く）

| 順 | 項目 | ソース | 表示 |
|---|---|---|---|
| 1 | **アラート** | knowledge/media/registry.yaml + status/ 最新 / knowledge/sns/*/queue.md + strategy.md / knowledge/watch/ 最新差分 / memory/.workflow/ | 媒体残数警告・契約更新30日前・SNSストック目標割れ・競合の重要変更・未完了タスク。ゼロなら「アラートなし ✅」の1行 |
| 2 | 進行中タスク | memory/.workflow/ + memory/session-log.md 末尾 | タスク名・フェーズ・引き継ぎ事項 |
| 3 | 登録タスク | tasks/*.yaml + knowledge/config/loops.yaml | タスク / 周期 / 最終実行（knowledge/logs/）/ 次回 |
| 4 | 学習記録 | knowledge/feedback/lessons.md | 直近に追加された OK/NG（3件まで） |
| 5 | 生成物 | knowledge/artifacts-index.md | 直近の発行物リンク（5件まで） |

- 各アラートに「次の一手」を1行添える（例: 「ストック残1日分 → 『Xの投稿ストック埋めて』」）
- 全体で20行程度に収める。推移・比較が必要なら 2（運用レポート）へ誘導する

## 引数がある場合の直行

| 言い方 | 直行先 |
|---|---|
| 「今どうなってる？」「全体状況」「アラートある？」 | サマリーのみ |
| 「今日の作業まとめて」「作業ログ」 | 1（トップのサマリーは省略可） |
| 「先週の成果」「返信率どう？」「効果測定」 | 2 |

## 共通ルール

- HTML成果物は docs/conventions.md 準拠、発行したら knowledge/artifacts-index.md に記録（同一レポートの再発行は同一URL更新）
- 定常ループの締めのアラート確認（registry 原則2）はこの手順の「アラート」行だけを実行し、定常タスクの完了サマリーに添える（無人実行時は docs/unattended-ops.md の Slack 通知へ）
