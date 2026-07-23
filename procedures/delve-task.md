---
description: 定常タスクの自動追加 — ヒアリングからタスクYAML・スキル割当・ループ登録・ダッシュボード連動までを一括構築する。Use when ユーザーが「〜を定常タスクにして」「毎朝◯◯するようにして」「タスクを追加して」「この作業を毎回やって」等、繰り返し実行する業務の登録を求めたとき。単発の変更作業は /タスク開始 へ。
argument-hint: [register <タスク名> | list | remove <タスク名>]（省略時は register）
---

定常タスク管理を実行してください。サブコマンド: $ARGUMENTS

## register（デフォルト）— タスクの自動構築

### 1. ヒアリング（足りないものだけ聞く。依頼文から読み取れる項目は確認に留める）

1. **ドメイン**: 企画リサーチ / SNS運用 / 求人媒体 / 広告分析（docs/command-registry.md の分類軸）
2. **場所**: どのサイト・媒体・アカウントか（knowledge/sites/ のキー。未登録なら新キーを起こす）
3. **やること**: 手順を自然言語で（1操作=1ステップに分解するのはこちらの仕事）
4. **変動値**: 毎回変わる値（params 化）
5. **周期**: 毎朝/平日/週次など（単発なら schedule なし）
6. **禁止事項・承認したい箇所**: destructive 判定に加えたいものがあれば

### 2. タスクYAML生成

- `templates/task-template.yaml` を骨格に `tasks/<タスク名>.yaml` を生成（タスク名は英語ケバブ）
- 送信/公開/投稿/保存を含むステップは **destructive を明示**（Step H で人の承認を必ず通る設計にする）
- `generate_text` にはスキル台帳（docs/command-registry.md）からドメインに合うスキルを割当
  （スカウト本文=recruit-writing、投稿=content-design+sns-jp、コピー=copywriting 等）
- 同種の文面生成を高頻度で行うタスクなら、あわせて /スキル化 でのワークスペーススキル化を提案する

### 3. ナレッジの足場

- `knowledge/sites/<place>/` が未整備なら作成し、index.md に「初回実行時に Delvework 方式でマッピングする（フェーズ①）」と記録

### 4. ループ登録

- `knowledge/config/loops.yaml` に追記（なければ作成）:
  ```yaml
  loops:
    - task: <タスク名>
      domain: <ドメイン>
      cadence: "平日 10:00"
      close_with_dashboard: true
  ```
- **スケジュール登録**: trigger 系ツール（`create_trigger`）が使える環境なら、ユーザーに周期を確認のうえ直接登録してよい。使えなければ登録文を提示してユーザーに委ねる。登録時の必須ルール（詳細は docs/unattended-ops.md）:
  - cron は **UTC 評価**（JST−9時間。例: 平日 JST 10:00 → `0 1 * * 1-5`）。登録後に `list_triggers` の next_run_at を JST に直して読み上げ、ユーザーに時刻を確認する
  - 最小間隔1時間・発火時刻にジッターあり・**発火は新規セッション**として走る
  - 発火プロンプトは「<タスク名>やって。終わったらダッシュボード更新して」の短文のみ。詳細手順は `tasks/<タスク名>.yaml` が正本

### 5. 壁打ち（設計のセカンドオピニオン）

YAML 案を確定する前に、strategy-advisor サブエージェントに (a)タスクYAML案の絶対パス、(b)目的とKPI、(c)関連する knowledge/ のパスを渡して審査させる。VERDICT が GO-WITH-CHANGES / RETHINK なら指摘を検討して反映または理由付きで却下し、採否を YAML のコメントか knowledge/logs/ に1行記録する。

### 6. 確認

生成した YAML とループ登録内容（壁打ちの VERDICT 含む）をユーザーに提示し、修正があれば Edit で反映してから完了報告。

### 7. 以後の実行（このコマンドの仕事ではない）

- 実行は従来どおり **/タスク開始** が担う: 「<タスク名>やって」→ delve-start が `tasks/<タスク名>.yaml` を読み、steps を実行計画の正として A〜K を回す（destructive ステップは H で承認）
- ダッシュボードは `tasks/*.yaml` + `loops.yaml` を読んでタスク一覧・タブ・次回実行を自動反映する

## list

`tasks/*.yaml` と `knowledge/config/loops.yaml` を突き合わせ、表で表示: タスク / ドメイン / 場所 / 周期 / 最終実行（knowledge/logs/ から）/ 状態

## remove <タスク名>

`tasks/<タスク名>.yaml` と loops.yaml の該当行を削除（**knowledge/sites/ の蓄積は消さない**）。削除前に対象を提示して確認を取る。
