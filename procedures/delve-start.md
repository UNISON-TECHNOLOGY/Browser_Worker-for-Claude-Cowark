---
description: ブラウザ操作タスクの開始手続き（ワークフローフラグ初期化 + フェーズ判定）。Use when ユーザーがサイトへの入力・クリック・投稿・設定変更などブラウザの変更操作を伴う作業を依頼したとき、変更操作の前に必ずこれを実行する（ゲートが変更操作をブロックするため）。閲覧・調査だけの依頼では不要
argument-hint: <タスク名>
---

Delvework のタスク「$ARGUMENTS」を開始してください。

手順の正本は `${CLAUDE_PLUGIN_ROOT}/docs/steps-reference.md`（見つからなければ Glob `**/docs/steps-reference.md`）。
**最初に必ず Read すること** — CP証跡定義（E-3）・レギュレーション検証（F-4）・ログ記録スキーマ（I-3）・ナレッジ構造（D-2）はそちらに従う。以下はフラグ操作の最短経路のみ。

0. `tasks/$ARGUMENTS.yaml`（登録済み定常タスク。/カスタマイズ のタスク登録が生成）があれば Read し、その steps を実行計画の正とする（destructive: true/auto のステップは Step H で人の承認を必ず取る）。なければ依頼文から計画を組む

0.5. **実行環境を判定する（cloud / local の両対応）**。使えるツール名で見分け、結果を記録する:

   | 観測 | 環境 | ゲートの効き方 |
   |------|------|--------------|
   | シェルが `Bash`、送付が `SendUserFile` | **Cowork cloud** | plugin hooks が配線済み＝**全ゲートが機械強制**される |
   | シェルが `mcp__workspace__bash`、送付が `mcp__cowork__present_files` | **Cowork ローカル** | **hooks が未配線＝ゲートは一切効かない**（escalations E4）。安全性は自己規律のみ |
   | 判別できない | ローカル扱い（保守側） | 同上 |

   **ローカルと判定したら、ゲート前提の運用（一括送出・金銭近傍・無人運用）はここで行わず、cloud セッションに回す**ようユーザーに1行で伝えること。「hooks が効かないので、この環境では一括送出はやりません」と明示してから代替を提案する。

   **フラグ操作はどちらの環境でも同じように行う**（ローカルで hook が効かなくても、状態記録として意味があり、配線され次第そのまま効く）。

### bash とブラウザは常に別マシンにいる（cloud / ローカル共通）

環境判定より重要な構造がこれ。**cloud でもローカルでも、bash はサンドボックス（ローカルは Hyper-V 上の Linux VM）の中で動き、ブラウザ操作はユーザーのマシン側の Chrome に届く。この2つは別のマシン**。

- **サンドボックスの bash から `localhost:9222`（CDP）でユーザーの Chrome には届かない**。ローカルセッションでも同じ（2026-07-27 に `%APPDATA%\Claude\vm_bundles\claudevm.bundle` の vmlinuz / rootfs.vhdx を実地確認）
- したがって **Playwright / CDP 接続を前提としたスクリプトは、Cowork からは実行できない**。「ローカルなら動くはず」と思って書き始めないこと
- サンドボックスの bash でできるのは**データ加工**（CSV・集計・判定ロジック・画像・PPTX/PDF・SQLite）。ブラウザを動かすのはブラウザツールだけ
- **この分業が凍結のしかたを決める**: DOM 操作は `javascript_tool` / `browser_batch` に凍結し、判定ロジック（適合判定・重複除外・上限管理）は bash 側のスクリプトに凍結する。詳細は steps-reference.md の G'

### 使える能力を確定し、ナレッジの `requires:` と照合する

環境判定と同時に、**このセッションで使える能力**を確認しておく（B や C でナレッジを読む前に）。
判定は「そのツール・コマンドが実際に呼べるか」で行い、推測しない:

`claude-in-chrome` / `playwright` / `cdp-9222` / `bash` / `python3` / `ffmpeg` / `sqlite` /
`design-sync`（認可済みか）/ `slack`（コネクタ接続済みか）/ `local-schedule`

**ナレッジを読むとき、`kind: operation` のファイルは冒頭の `requires:` を先に見る**（steps-reference D-2「有効条件」）:

- 満たす → 通常どおり使う
- **満たさない → そのファイルは読まない・従わない・他手段へ「移植」しない**。
  代替手段を自分で探し始めないこと。実行できない旨と、何が足りないかを報告して指示を仰ぐ
- 恒久的に満たせないと判明したら、手段非依存の知識（セレクタ・判定順・事故防止ルール）だけを
  現行ファイルへ救出してから `_archive/` へ移す。**丸ごと捨てない**
1. ワークスペースに `memory/.workflow/` と `knowledge/sites/` がなければ作成する
2. フラグを初期化する:
   ```bash
   mkdir -p memory/.workflow knowledge/sites knowledge/logs
   rm -f memory/.workflow/{b4_done,e_done,k_done,bulk_send,psv_done,ov_done,critic_pending,critic_pass}
   echo "$ARGUMENTS" > memory/.workflow/active
   ```
   （`money_alert` は**意図的に消さない** — 前回の金銭停止は新タスクに持ち越し、解除は Money Watch 復帰手順のみ。手順8参照。`verify_allowlist` も**消さない** — 検証セッション中にタスク開始すると防壁が消える事故が 2026-07-24 に実測されたため、作成と削除は検証手順（delve-verify 後片付け）だけが行う）
3. `knowledge/sites/` を確認し、対象サイトのナレッジ有無でフェーズを判定する:
   - ナレッジなし → ① 初回 (First Delve)
   - ナレッジあり、成功ログなし → ② 再訪問 (Return)
   - 成功ログ（knowledge/logs/ のフロントマター status: success）+ shortcut_memo あり → ④ 最適化 (Optimize)
   - **実行中にナレッジと実ページの構造差異を検出したら → ③ 構造変更 (Remap)**: `rm -f memory/.workflow/e_done` して Step E からやり直し、`echo "3" > memory/.workflow/phase` に更新、ナレッジの差異箇所を修正してから再開する
4. フェーズを記録する:
   ```bash
   echo "<phase>" > memory/.workflow/phase && touch memory/.workflow/b4_done
   ```
   （`phase` は hook 非連動の状態メモ。ゲートに効くのは b4_done の方）
5. 変更操作の前（Step E）— 順に:
   - **変更前の状態をテキスト読取で記録**する（read_page / browser_snapshot。**スクリーンショットのみでの代替不可** — Money Watch の検知面のため）
   - **フェーズ②③④なら Step J（差分比較）**: 前回ログの after_state と今回の before_state を比較し、外部変更・リセットを検出したらユーザーに報告（steps-reference.md J）
   - **不可逆操作（送信・投稿・公開・削除・保存）があるなら CP（Critical Point）と成功証跡を宣言**（steps-reference.md E-3）
   - 済んだら:
   ```bash
   touch memory/.workflow/e_done
   ```
5.5. **実行（Step G）— 凍結物があるならそれを使う**。フェーズ④（成功ログ＋手順固定）のタスクは、1要素ずつブラウザツールを叩くのではなく、確立済みの手順を凍結した資産で実行する。1操作ごとの LLM 往復が消えるため速く、手順が固定されるため揺れない。

   - `knowledge/sites/<site>/snippets/*.js`（抽出・一括操作の JS）があれば Read して `javascript_tool` に渡す
   - `scripts/<タスク名>.js`（判定ロジック）があれば、**まず dry-run（既定）で対象と件数をユーザーに提示 → 承認 → `--apply` 相当で実行**する
   - まだ無く、今回の手順が安定していると判断できるなら、Step I の後に凍結を提案する（作り方の正本は `${CLAUDE_PLUGIN_ROOT}/docs/steps-reference.md` の Step G'）

6. 実行後（Step I）— 順に:
   - **CP 証跡を照合**する（証跡なしで成功扱い禁止）
   - **不可逆送出（送信・投稿・公開・配信）があったタスクは outcome-verifier に after_state と CP 証跡を渡して独立検証させ、確定成功数で報告**（必須。steps-reference.md I）。判定を受領したら `echo "<VERIFIED n/m と1行要約>" > memory/.workflow/ov_done`（OV Gate: bulk_send 宣言タスクは ov_done なしで k_done 不可）
     - **1件も送出せずに終わった場合**（DRY-RUN のみ・対象0件・途中で中止）は検証する対象がないので `echo "NO_SEND: <理由>" > memory/.workflow/ov_done` として完了してよい。送っていないのに VERIFIED と書くことは禁止
   - `knowledge/logs/<タスク名>_<日付>.md` に **YAMLフロントマター付き**でログを記録し、サイトナレッジを更新（steps-reference.md I-1.5〜I-5。フロントマター無しだと次回のフェーズ判定が壊れる）
7. タスク完了時は `memory/session-log.md`（正本はここ。`knowledge/logs/session-log.md` ではない — logs/ はタスク単位ログ専用）に学びを記録してから:
   ```bash
   touch memory/.workflow/k_done
   ```
   （Log Gate = 運用ルール: session-log を更新するまで k_done を作らない。hook の技術的強制はないため自己規律で守る）
8. タスク中に Money Watch 停止（money_alert）が立った場合の復帰手順は steps-reference.md 末尾に従う（strategy-advisor 助言 → ユーザー明示承認 → 解除。承認なしの解除は禁止）
