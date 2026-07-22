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

## インストール（Cowork）— 2ステップ

1. Cowork の Customize → プラグインでこのリポジトリの marketplace を追加:
   `https://github.com/UNISON-TECHNOLOGY/Browser_Worker-for-Claude-Cowark`
2. `browser-worker` プラグインを有効化

## ブラウザエンジン

**Cowork では Claude in Chrome を前提エンジンとする**（v0.9.0〜）。ユーザーの実ブラウザで
動くためログイン済みセッションがそのまま使え、追加セットアップ不要。
ゲートは `mcp__claude-in-chrome__computer` / `form_input` を捕捉する。

ローカル Claude Code で使う場合は Playwright MCP（`mcp__playwright__*`）にも同じゲートが
効く（マッチャーは両エンジン対応）。同梱の `.mcp.json` は Claude Code 用
（Cowork はプラグイン同梱 MCP をチャットに供給しない — TESTING.md T1 参照）。

**本運用時**: 「フォルダを追加」で業務フォルダを接続すること。未接続だとクラウド VM の
一時領域に knowledge/memory が作られ、セッション終了で消える。

## 設計原則

- **プラグイン = 方法論（読み取り専用）**: 手順・ゲート・地図の書式
- **ワークスペース = 育つデータ**: `knowledge/sites/`（地図）、`memory/`（セッションログ・フラグ）
- ワークスペースのパスは `CLAUDE_PROJECT_DIR` から解決（絶対パス直書き禁止）
- 認証情報は扱わない。ログインは人間に委譲

## スモークテスト手順

1. Cowork で `/delve-status` → コマンド読み込み確認
2. フラグなしで `browser_click` を試行 → hook がブロックすれば成功
3. `/delve-start テスト` → フラグ作成後に操作が通れば成功
