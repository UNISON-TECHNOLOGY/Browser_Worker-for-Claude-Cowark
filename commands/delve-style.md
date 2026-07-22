---
description: 参考サイトのデザインを計測・分析してスタイルリサーチレポートとデザイントークンを生成する（LP/UI制作の下調べ）
argument-hint: <URL...>（スペース区切りで複数可）
---

指定された参考サイト（$ARGUMENTS）のスタイルリサーチを実行してください。

## 手順（サイトごとに繰り返し）

1. Playwright で対象 URL に遷移し、フルページスクリーンショットを取得
2. `browser_evaluate` で computed style を計測する:
   - **カラー**: 全可視要素の background-color / color / border-color を集計し、使用面積・頻度の上位を抽出（rgba→hex 正規化、透明・白黒系はグループ化）
   - **タイポグラフィ**: body と h1〜h4 の font-family / font-size / font-weight / line-height / letter-spacing
   - **レイアウト**: メインコンテナの max-width、セクションの縦余白（padding/margin の代表値）、グリッド列数
   - **コンポーネント**: ボタン（`button, a[class*=btn], [role=button]`）の border-radius / box-shadow / padding / 色、カード要素の角丸と影
3. セクション構成を上から順に分類する（例: ヒーロー → 課題提起 → 特長 → 実績/ロゴ → 料金 → FAQ → CTA）

## 出力（2つ）

1. **デザイントークン JSON**: `knowledge/styles/<site-name>.json`
   ```json
   {
     "source": "<URL>", "date": "<日付>",
     "colors": {"primary": "#…", "accent": "#…", "background": "#…", "text": "#…", "palette": ["#…"]},
     "typography": {"body": {...}, "headings": {...}},
     "layout": {"maxWidth": "…", "sectionSpacing": "…", "sections": ["hero", "features", "cta"]},
     "components": {"button": {...}, "card": {...}}
   }
   ```
2. **スタイルリサーチ HTML レポート**: `knowledge/reports/style-research-<date>.html`（自己完結・外部依存なし）
   - サイトごとに: スクショ + カラーパレットのスウォッチ表示 + タイポグラフィ見本 + セクション構成図
   - 複数サイト指定時は**横断比較セクション**を先頭に置く（共通パターン / 各サイトの差別化ポイント / LP制作への示唆3点）

## 注意

- これは読み取り専用タスク（navigate / snapshot / evaluate / screenshot のみ）。変更操作は行わないため Delvework ゲートの対象外
- ログインが必要なサイトはスキップして報告する
- 生成後、トークン JSON は「このトークンで LP を作成」という次タスクの入力として使えることを伝える
