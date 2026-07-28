---
description: サイト診断 — ページスピード実測・SEO/品質チェック・リンク切れ検出のHTMLレポート生成。Use when ユーザーが「サイトを診断して」「表示速度を測って」「ページスピード/パフォーマンスを調べて」「SEOチェックして」「リンク切れないか見て」「サイトの健康診断」等、自社/対象サイトの状態確認を依頼したとき。Not for デザイン/見た目の調査（→style-research 部品（docs/parts/style-research.md））
argument-hint: <サイトURL> [最大ページ数（デフォルト10）]
---

対象サイト（$ARGUMENTS）のサイト診断を実行してください。

## 1. ページ一覧の収集

- まず `<URL>/sitemap.xml`（なければ robots.txt → sitemap 参照）を取得
- sitemap がなければトップページの内部リンクから収集
- 最大ページ数（指定なければ10ページ）まで。対象を選ぶ際は主要導線（トップ/サービス/料金/問い合わせ等）を優先

## 2. ページごとの計測（navigate + JS実行 + ネットワーク監視 — Claude in Chrome / Playwright どちらでも可）

> 速度規範の正本は docs/steps/speed.md。**下の3観点（スピード実測・品質チェック・リンク健全性の JS 部分）を観点ごとに分けず、1ページ = `javascript_tool` 1コールで `{speed, quality}` を1つのオブジェクトにまとめて返す**。複数ページは可能なら `browser_batch` で navigate + 抽出を束ねる（1ページずつ read_page で往復しない）。

**スピード実測** — JS 実行ツール（`javascript_tool` / `browser_evaluate`）で Performance API から取得:
```js
// Navigation Timing: TTFB, DOMContentLoaded, load
performance.getEntriesByType('navigation')[0]
// LCP / CLS: PerformanceObserver（buffered: true で過去エントリも取得）
// リソース内訳: performance.getEntriesByType('resource') を initiatorType 別に集計（件数・transferSize）
```

**品質チェック** — 同じく evaluate で:
- title / meta[name=description] の有無と文字数
- h1 の有無・個数
- alt 欠落画像の数、width/height 未指定画像（CLS 要因）
- viewport / OGP / canonical の有無

**リンク健全性**:
- ネットワーク監視ツール（`read_network_requests` / `browser_network_requests`）で 4xx/5xx レスポンスとリダイレクトチェーンを検出

## 3. 出力（2つ）

1. **計測データ JSON**: knowledge/data/delvework.db の audit_pages（DBが無ければ templates/db-schema.sql で初期化。detail_json に全計測値）
   - 過去の JSON があれば読み込み、**前回比**を算出する（改善/悪化の差分）
2. **診断 HTML レポート**: `knowledge/reports/site-audit-<date>.html`（templates/report-template.html を骨格に使用・自己完結）
   - サマリー: サイト全体のスコア感（速度/品質/リンク健全性の3軸）と最重要指摘 Top3
   - ページ別テーブル: TTFB / LCP / CLS / 転送量 / 品質チェック結果（閾値超えは色分け: LCP 2.5s・CLS 0.1 目安）
   - リソース内訳チャート（重いページの原因分析）
   - 前回データがあれば推移セクション
   - 改善提案: 実測値に基づく具体策（例: 「hero画像 1.8MB が LCP 4.2s の主因 → WebP 化で改善見込み」）

## 4. サイト種別 × 4段階マッピング（管理画面を伴う媒体・自社サイトを診断するとき）

公開ページだけを見て終わらせない。**まずサイト種別を判定し、種別ごとに実施する段階を出し分ける**（判定基準: 求職者/来訪者向けの公開URL（`public_url` 相当）があるか）。

| サイト種別 | 例 | FA（管理画面探索） | SA（公開ページ探索） | TA（競合テンプレ解析） | DA（運用データ解析） |
|---|---|---|---|---|---|
| 求人掲載型 | 公開求人ページあり（求人媒体・自社採用サイト） | 必須 | 必須 | 必須 | 任意 |
| スカウト送信型 | 管理画面のみ・公開ページなし | 必須 | **N/A** | **N/A** | **必須** |
| ハイブリッド型 | 管理画面＋公開ページ | 必須 | 必須 | 必須 | 任意 |

- **FA**: ログイン後の管理画面を網羅探索し「自社が何を操作・確認できるか」を把握（全リンクは `javascript_tool` 1コールで一括抽出 → サイトマップ化）
- **SA**: 公開ページを来訪者視点で見る + 同条件で出る競合を収集（上の §2 の計測はここ）
- **TA**: 競合3〜5社の詳細ページのセクション構造・訴求軸を抽出し、自社に欠けている要素を特定
- **DA（公開ページが無いときの代替）**: 運用データを解析する — **返信率×テンプレ / 検索条件セグメント別の効率 / パイプライン歩留まり（どの段階で落ちるか） / 未対応アラート / 時系列推移**。抽出は `javascript_tool` 一括（大量テーブルは read_page で往復しない）→ `knowledge/data/` に保存 → 効率ランキング・ボトルネック・改善仮説を導出
- 結果はサイトナレッジに記録し、`index.md` に各段階の状況（N/A も明記）を書く（構造・種別の規約は docs/steps/knowledge.md）

## 注意

- 読み取り専用タスク（navigate / evaluate / network_requests / screenshot のみ）。Delvework ゲート対象外
- 計測は本番環境の実測値であり、回線・キャッシュ状態の影響を受けることをレポートに明記する
- ログイン必須ページはスキップして報告
