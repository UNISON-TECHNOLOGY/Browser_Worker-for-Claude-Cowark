# Browser Worker for Claude Cowork

> *Delve into the unknown. Map by touch. Master through repetition.*

**Delvework** — AIがブラウザを手触りでマッピングし、経験を重ねて精度を上げるブラウザ自動化方法論の Claude Cowork プラグイン。

現在は **v0.1（スモークテスト版）**: hook ゲートとコマンドが Cowork 環境で動作するかの検証用。

## 構成

| パス | 内容 |
|------|------|
| `commands/delve-start.md` | タスク開始（フラグ初期化 + フェーズ判定） |
| `commands/delve-status.md` | ワークフロー状態の確認 |
| `hooks/hooks.json` | Playwright 変更操作のゲート（B-4/E 未完了ならブロック） |

## インストール（Cowork）

1. Cowork の Customize → プラグインでこのリポジトリの marketplace を追加:
   `https://github.com/UNISON-TECHNOLOGY/Browser_Worker-for-Claude-Cowark`
2. `browser-worker` プラグインを有効化
3. Playwright MCP を接続

## 設計原則

- **プラグイン = 方法論（読み取り専用）**: 手順・ゲート・地図の書式
- **ワークスペース = 育つデータ**: `knowledge/sites/`（地図）、`memory/`（セッションログ・フラグ）
- ワークスペースのパスは `CLAUDE_PROJECT_DIR` から解決（絶対パス直書き禁止）
- 認証情報は扱わない。ログインは人間に委譲

## スモークテスト手順

1. Cowork で `/delve-status` → コマンド読み込み確認
2. フラグなしで `browser_click` を試行 → hook がブロックすれば成功
3. `/delve-start テスト` → フラグ作成後に操作が通れば成功
