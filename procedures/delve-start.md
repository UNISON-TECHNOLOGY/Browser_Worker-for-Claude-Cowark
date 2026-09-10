---
description: ブラウザ操作タスクの開始手続き（ワークフローフラグ初期化 + フェーズ判定）。Use when ユーザーがサイトへの入力・クリック・投稿・設定変更などブラウザの変更操作を伴う作業を依頼したとき、変更操作の前に必ずこれを実行する（**ゲートの有無に関わらず必須の前段** — cloud はゲートが機械強制し、ローカルはゲートが発火しないからこそこの手順が唯一の防御線になる）。閲覧・調査だけの依頼では不要
argument-hint: <タスク名>
---

Delvework のタスク「$ARGUMENTS」を開始してください。

手順の正本は `${CLAUDE_PLUGIN_ROOT}/docs/steps-reference.md`（見つからなければ Glob `**/docs/steps-reference.md`）。
**読む量はフェーズで決める（手順2で判定してから読む。先に全文を読まない）**:
- ①初回 / ②再訪問 / ③構造変更 → steps-reference を全文 Read（探索・初回実行の骨格が要る）。**迷ったら①扱いで全文 Read**（読み落としの損が大きい）
- ④最適化（成功ログ + shortcut_memo あり）→ steps-reference は**読まない**。以下の手順表と、当たったときだけ読む docs/steps/ の節で足りる: 不可逆操作→cp.md / 承認・送出・ビジュアル引き渡し→review.md / N件の一括送出→bulk-send.md / 複数ページ・複数候補の読み取り→speed.md（常に1コール集約） / 凍結・④再生→freeze.md / ログ→logging.md / ナレッジ→knowledge.md / money_alert→money-recovery.md。実行中に③へ落ちたらその時点で全文 Read
各ステップの判断基準・書式はこれらの正本に従う（ここには複製しない）。**エラー時**: スクショ→報告して指示を仰ぐ→ログ記録。**自動リカバリー禁止**。

0. `tasks/$ARGUMENTS.yaml`（登録済み定常タスク。/カスタマイズ のタスク登録が生成）があれば Read し、その steps を実行計画の正とする（destructive: true/auto のステップは Step H で人の承認を必ず取る）。なければ依頼文から計画を組む

0.5. **環境と使える能力を確定する**（cloud / local 両対応）。ツール名で見分ける:

   | シェル / 送付ツール | 環境 | ゲート |
   |---|---|---|
   | `Bash` / `SendUserFile` | Cowork cloud | hooks 配線済み＝**機械強制される** |
   | `mcp__workspace__bash` / `mcp__cowork__present_files`（不明なときも） | Cowork ローカル | **hooks 未配線＝効かない**（E4）。自己規律のみ |

   ローカルなら**ゲート前提の運用（一括送出・金銭近傍・無人）はここで行わず cloud に回す**旨を
   ユーザーに1行で伝える。フラグ操作はどちらの環境でも同じように行う。

   **運用ルール（session-rules）の自力取得**: このセッションで運用ルール全文の注入が
   見当たらない（SessionStart の【Delvework 運用ルール】ブロックが文脈に無い＝ローカル等）なら、
   プラグインの `hooks/scripts/session-rules.txt` を **Read する**（正本。パス解決は
   docs/conventions.md §0 の3段方式 — `${CLAUDE_PLUGIN_ROOT}` → 相対 → `~/.claude/plugins` 起点の Glob）。
   インジェクション耐性・金銭ガード・削除ガード・エスカレーション発火条件は他ファイルに複製が無く、
   読まないと丸ごと欠落する（E4）。

   **認証フィールドの自己規律 `docs/steps/credential.md` を Read**（全フェーズ必読）。

   **bash とブラウザは常に別マシン**（cloud もローカルも。ローカルは Hyper-V 上の Linux VM）。
   **サンドボックスから `localhost:9222` には到達できず、Playwright / CDP 前提のスクリプトは
   Cowork では実行できない**。bash の役割はデータ加工（CSV・集計・判定ロジック・画像・PDF・SQLite）で、
   ブラウザを動かすのはブラウザツールだけ（実測根拠は docs/rationale.md）。

   **使える能力**を実際に呼べるかで確認し（推測しない）、ナレッジの `requires:` と照合する:
   `claude-in-chrome` / `playwright` / `cdp-9222` / `bash` / `python3` / `ffmpeg` / `sqlite` /
   `design-sync` / `slack` / `local-schedule`。
   **満たさない `kind: operation` のファイルは読まない・従わない・移植しない**
   （代替手段を自分で探さず、足りないものを報告して指示を仰ぐ。詳細は docs/steps/knowledge.md「有効条件」）。

1. 作業場とフラグを初期化する:
   ```bash
   mkdir -p memory/.workflow knowledge/sites knowledge/logs
   rm -f memory/.workflow/{b4_done,e_done,k_done,bulk_send,psv_done,ov_done,critic_pending,critic_pass}
   echo "$ARGUMENTS" > memory/.workflow/active
   ```
   `money_alert` と `verify_allowlist` は**この rm に含めない**（前者の解除は docs/steps/money-recovery.md の手順だけ、後者の作成・削除は検証手順 delve-verify だけが行う）
2. フェーズを判定して記録する（①サイトナレッジなし / ②ナレッジあり・成功ログなし / ③探索中に構造差異 / ④成功ログ + shortcut_memo あり。④以外は**ここで** steps-reference を全文 Read。③は開始時には選べない — 手順8 で落ちる）:
   ```bash
   echo "2" > memory/.workflow/phase && touch memory/.workflow/b4_done   # 値は 1〜4（または first/return/remap/optimize）。丸数字は書かない
   ```
   （ゲートは b4_done と `phase` の**両方**を見る — phase が空・空白のみだと deny。値の語彙は上の1行のとおり）
3. Step E（変更前記録 — **スクショだけでなくテキスト読取を必ず含める** → ②③④なら J: **前回ログの after_state と今回の before_state を比較し、外部変更/リセットがあればユーザーに報告** → 不可逆操作があるなら docs/steps/cp.md を Read して CP 宣言）を終えたら:
   ```bash
   touch memory/.workflow/e_done
   ```
4. Step F で不可逆な一括送出（スカウト/投稿/配信/入稿）を計画に含めたら宣言し、Step H で pre-send-verifier 監査とユーザー承認が揃ったら解錠する（監査・承認の手順は docs/steps/review.md）:
   ```bash
   touch memory/.workflow/bulk_send      # F: 計画に一括送出を含めたとき
   touch memory/.workflow/psv_done       # H: 監査 + 承認が揃ったとき
   ```
5. Step G は**凍結資産があればそれで実行**する（フェーズ④。shortcut_memo は各ステップ**実行前にランドマーク照合**、不一致は手順8の③へ、ランドマーク無しの旧 memo は②扱い — 正本 docs/steps/freeze.md「④再生の機械検証」。`knowledge/sites/<site>/snippets/*.js` / `scripts/<タスク名>.js`。無ければ Step I の後に凍結を提案 — 作り方と dry-run→承認→適用の順序は `${CLAUDE_PLUGIN_ROOT}/docs/steps/freeze.md`）
6. Step I（CP証跡照合 → outcome-verifier の要否判断（**不可逆操作があったタスクのみ**。読み取りだけなら起動しない） → ログ記録 docs/steps/logging.md。CP照合は docs/steps/cp.md）。検証を受領したら:
   ```bash
   echo "<VERIFIED n/m と1行要約>" > memory/.workflow/ov_done
   ```
   **1件も送出せずに終わった場合**（DRY-RUN のみ・対象0件・途中中止）は検証対象が無いので `echo "NO_SEND: <理由>" > memory/.workflow/ov_done` でよい。送っていないのに VERIFIED と書くことは禁止
7. Step K — **先に** `memory/session-log.md`（正本はここ。`knowledge/logs/session-log.md` ではない — logs/ はタスク単位ログ専用）に学びを記録してから:
   ```bash
   touch memory/.workflow/k_done
   ```
8. 実行中にナレッジと実ページの構造差異を検出したらフェーズ③（steps-reference を全文 Read し「フェーズ判定（B-4）と③構造変更」に従う）:
   ```bash
   rm -f memory/.workflow/e_done && echo "3" > memory/.workflow/phase
   ```
9. money_alert が立ったら復帰手順に従う（docs/steps/money-recovery.md。承認なしの解除は禁止）
