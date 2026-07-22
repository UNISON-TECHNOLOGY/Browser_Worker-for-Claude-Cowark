---
description: 媒体管理 — 運用中の媒体（求人媒体・SNSアカウント・広告アカウント等）の台帳管理と横断ステータス巡回、期限・残数アラート、横断ダッシュボード生成。Use when ユーザーが「媒体を登録して」「全媒体の状況を見せて」「掲載状況をまとめて」「チケット残数を確認して」「契約期限の近い媒体は？」等、複数媒体の一元管理・棚卸しを求めたとき。
argument-hint: [register <媒体名> | status | report]（省略時は status）
---

媒体管理を実行してください。サブコマンド: $ARGUMENTS

## 台帳（正本）

`knowledge/media/registry.yaml` — なければ初回に作成:

```yaml
media:
  - id: onecareer            # 英語ケバブケース
    name: ONE CAREER Cloud
    type: 求人媒体            # 求人媒体 / SNS / 広告 / オウンドメディア
    url: https://…           # 管理画面URL
    login: human             # 認証は人間に委譲（認証情報は書かない）
    contract:
      renew_date: 2026-12-31 # 契約更新日
      plan: スカウト定額
    quota:                   # 残数管理したいもの（媒体により異なる）
      - name: スカウトチケット
        warn_below: 50       # この値を下回ったらアラート
    watch:                   # 巡回時に見るページと取得項目
      - page: /tickets
        items: [チケット残数, 有効期限]
    notes: 週次でスカウト送信に使用
```

## サブコマンド

### register <媒体名>
ユーザーにヒアリング（種別・URL・契約情報・残数管理項目・巡回で見たい数値）して registry.yaml に追記。knowledge/sites/<id>/ が未整備なら「初回巡回時に Delvework 方式でマッピングする」と案内

### status（デフォルト）
1. registry.yaml の全媒体について、ブラウザで管理画面を巡回（read_page、読み取り専用）
   - ログインが必要な媒体は人間にログインを依頼し、不可ならスキップして「未取得」と報告
2. watch 定義の項目（残数・掲載件数・有効期限等）を取得し、`knowledge/media/status/<date>.json` に記録
3. チャットに横断サマリー表を表示:
   - 媒体 / 種別 / 主要数値(前回比) / アラート（⚠️ quota.warn_below 割れ・契約更新30日前・前回から急減）
4. アラートがあれば対応の提案（例: 「チケット残 32、今週の送信予定 40 件 — 追加購入 or 送信調整が必要」）

### report
status の履歴（knowledge/media/status/）から横断ダッシュボード HTML を生成（templates/report-template.html 準拠・deliverable-writer 委譲）:
- 媒体別の残数・利用ペースの推移（stat + delta + CSS横棒）
- 契約更新カレンダー（時系列順・30日以内は warn 色）
- 媒体別の費用対効果メモ欄（データがあれば: 送信数→返信率等）

## 運用の推奨

- status は週1の定期実行と相性が良い（Cowork のスケジュール機能を案内）
- 数値取得の巡回手順は媒体ごとに knowledge/sites/<id>/ へ Delvework 方式で蓄積し、2回目以降を高速化する

## 注意

- 読み取り専用（巡回・記録のみ）。媒体側の設定変更・購入操作は行わない（必要なら別タスクとして /delve-start から）
- 認証情報は registry.yaml にも他のどこにも記録しない
