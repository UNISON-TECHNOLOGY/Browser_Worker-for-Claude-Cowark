---
description: ブラウザ操作タスクの開始手続き（ワークフローフラグ初期化 + フェーズ判定）。Use when ユーザーがサイトへの入力・クリック・投稿・設定変更などブラウザの変更操作を伴う作業を依頼したとき、変更操作の前に必ずこれを実行する（ゲートが変更操作をブロックするため）。閲覧・調査だけの依頼では不要
argument-hint: <タスク名>
---

Delvework のタスク「$ARGUMENTS」を開始してください。

0. `tasks/$ARGUMENTS.yaml`（登録済み定常タスク。/定常タスク が生成）があれば Read し、その steps を実行計画の正とする（destructive: true/auto のステップは Step H で人の承認を必ず取る）。なければ依頼文から計画を組む
1. ワークスペースに `memory/.workflow/` と `knowledge/sites/` がなければ作成する
2. フラグを初期化する:
   ```bash
   mkdir -p memory/.workflow knowledge/sites knowledge/logs
   rm -f memory/.workflow/{b4_done,e_done,k_done}
   echo "$ARGUMENTS" > memory/.workflow/active
   ```
3. `knowledge/sites/` を確認し、対象サイトのナレッジ有無でフェーズを判定する:
   - ナレッジなし → ① 初回 (First Delve)
   - ナレッジあり、成功ログなし → ② 再訪問 (Return)
   - 成功ログ + 短縮メモあり → ④ 最適化 (Optimize)
4. フェーズを記録する:
   ```bash
   echo "<phase>" > memory/.workflow/phase && touch memory/.workflow/b4_done
   ```
5. ブラウザで変更操作を行う前に、必ず read_page（Claude in Chrome）または browser_snapshot（Playwright）で変更前の状態を記録してから:
   ```bash
   touch memory/.workflow/e_done
   ```
6. タスク完了時は `memory/session-log.md` に学びを記録してから:
   ```bash
   touch memory/.workflow/k_done
   ```
