---
description: Delvework ワークフロー状態（フラグ・ナレッジ有無）を表示するスモークテストコマンド
---

Delvework の現在状態を確認して報告してください。

1. `memory/.workflow/` ディレクトリの各フラグ（active / phase / b4_done / e_done / k_done）の有無を Bash で確認する:
   ```bash
   ls -la memory/.workflow/ 2>/dev/null && cat memory/.workflow/active memory/.workflow/phase 2>/dev/null
   ```
2. `knowledge/sites/` にサイトナレッジがあるか確認する:
   ```bash
   ls knowledge/sites/ 2>/dev/null
   ```
3. 結果を表にまとめて報告する:
   - ワークフロー状態（未初期化 / 進行中タスク名 / フェーズ / 各フラグ）
   - サイトナレッジ一覧
   - hook ゲートの想定挙動（現在のフラグ状態で変更操作がブロックされるか）

このコマンドが動けば、プラグインのコマンド読み込みが機能している証拠になります。
