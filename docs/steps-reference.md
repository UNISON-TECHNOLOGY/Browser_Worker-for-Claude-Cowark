# Delvework ステップ正本（A〜K リファレンス）

> ブラウザ変更操作タスクの手順の正本。/タスク開始（procedures/delve-start.md）はフラグ操作の最短経路のみを書き、
> 方法論の本体はここに一元化する（各手順書はここへのポインタのみ。複製は乖離事故のもと）。
>
> **読むのはフェーズ①初回・②再訪問・③構造変更のとき**。**④最適化では読まない** —
> 成功ログ + shortcut_memo（+ 凍結資産）が実在するフェーズだけは、delve-start の手順表と下の節ファイルで骨格が足りる（2026-09-10。②は成功ログが無い＝初めて実行するフェーズなので省略しない）。
>
> **詳細節は必要なときだけ読む**（全部読まない。フェーズを問わず「読むとき」に当たったら読む。④は delve-start 手順の同じ表から辿る）:
>
> | 読むとき | ファイル |
> |---|---|
> | 不可逆操作（送信・投稿・公開・削除・保存）を含む — Step E に入る前 | [steps/cp.md](steps/cp.md) — CP証跡定義（E-3）・レギュレーション検証（F-4）・CP照合（I-1.5）・最短ルート記録（I-5） |
> | 生成物の承認・不可逆送出・ビジュアル成果物の引き渡しがある（Step H） | [steps/review.md](steps/review.md) — 承認の取り方・pre-send-verifier 監査・design-critic のフラグ運用 |
> | ナレッジを書く・読む（D / I） | [steps/knowledge.md](steps/knowledge.md) — 構造・種別・`requires:`・鮮度 |
> | 手順を凍結する（読み取り②/変更④） | [steps/freeze.md](steps/freeze.md) — 凍結の2段条件 |
> | 複数ページ/複数候補を読む・N件提示する | [steps/speed.md](steps/speed.md) — 一括JS/batch・提示のバッチ化・UI→JS切替・待機 |
> | 不可逆な一括送出をN件行う（F/H/I） | [steps/bulk-send.md](steps/bulk-send.md) — dry-run既定・枠管理・二重シグナル・回路ブレーカ |
> | タスクログを記録する（Step I） | [steps/logging.md](steps/logging.md) — 必須スキーマ |
> | money_alert が立った | [steps/money-recovery.md](steps/money-recovery.md) — 復帰手順 |
> | 規則の背景・実例を確かめたい | [rationale.md](rationale.md) — 必読でない |

## ステップ一覧

| Step | Code | 名称 | 要点 |
|------|------|------|------|
| A | Order | タスク指令 | パラメータ確定・破壊的操作の有無を判定 |
| B | Recon | 外部探索 | ナレッジ・過去ログを読み、フェーズ判定（B-4） |
| C | Probe | 内部探索 | ブラウザでページ構造を取得、ナレッジと照合 |
| D | Map | マッピング | 構造をナレッジに記録（steps/knowledge.md） |
| E | Observe | モニタリング | 変更前状態の記録（テキスト読取を必ず含める）+ 不可逆操作があるなら CP証跡定義（steps/cp.md E-3） |
| J | Report | 差分比較 | フェーズ②③④のみ、E直後。前回 after_state と今回 before_state を比較し、外部変更/リセットを検出したらユーザーに報告 |
| F | Plan | プランニング | 実行計画 + レギュレーション検証（steps/cp.md F-4）。**計画に不可逆な一括送出（スカウト/投稿/配信/入稿）が含まれるなら `touch memory/.workflow/bulk_send` を宣言**（以後 psv_done まで変更操作が hook でブロックされる） |
| G | Act | アクション | 実行。生成物があれば H に遷移。**読み取りは常に1コール集約（steps/speed.md）**。**フェーズ②で読み取り凍結／④で変更も凍結スクリプト経由に移す（下記 G'）** — 1操作ごとの LLM 往復が消え、ローカル環境ではこれが主経路 |
| H | Review | レビュー | 生成物・破壊的操作のユーザー承認。**N件は1回で一覧提示し承認は個別**。不可逆送出は pre-send-verifier 監査（VERDICT）→ 承認 → `psv_done`。ユーザーに渡すビジュアル成果物は design-critic の PASS が先（Critic Gate）。**手順・フラグ運用の正本は steps/review.md**（該当があるときだけ読む） |
| I | Verify | チェック | CP証跡照合（steps/cp.md I-1.5）+ ログ記録（steps/logging.md）+ ナレッジ更新。**不可逆操作があったタスクに限り**（件数は問わない）**outcome-verifier**（送信後検証）に after_state と CP 証跡を渡して独立検証させ、判定要約を `memory/.workflow/ov_done` に書き込む（OV Gate hook: bulk_send 宣言タスクは ov_done なしで k_done 不可）。**読み取りだけのタスク（巡回・状況確認・調査）では起動しない** — 照合する CP 証跡が無く渡す材料がない。締めは main ループが行う。効果測定（返信率・エンゲージ集計）は別用途で、件数や期間があるときだけ |
| K | Offer | オファー | 完了報告 → session-log 更新 → k_done |

## 認証フィールドの取り扱い（全ステップ共通・自己規律）

→ **[credential.md](steps/credential.md)** に分離（全フェーズ必読。実効ポインタは delve-start 手順0.5）。

## フェーズ判定（B-4）と③構造変更

| # | フェーズ | 条件 |
|---|---------|------|
| ① | 初回 (First Delve) | サイトナレッジなし。**探索は「一番難しい業務ページ」（複雑なフォーム・動的画面）から行う** — 綺麗なトップページでの成功は当てにならず、本番業務の画面で崩れる（外部実務知見） |
| ② | 再訪問 (Return) | ナレッジあり、成功ログなし |
| ③ | 構造変更 (Remap) | **探索中に構造差異検出**（ナレッジの ref/導線が実ページと不一致） |
| ④ | 最適化 (Optimize) | 成功ログ + shortcut_memo あり |

**フェーズ③発動時（実行中いつでも）**: ナレッジと実ページの構造差異を検出したら、古い ref で操作を続けず
`rm -f memory/.workflow/e_done` して Step E（変更前記録）からやり直し、`echo "3" > memory/.workflow/phase` に更新、
D（マッピング）で差異箇所のナレッジを修正してから再開する。（④で始めたタスクが③に落ちたときの全文 Read は delve-start 手順8 が実効正本）

フェーズ④は過去ログの `shortcut_memo` をレシピとして使う。レシピのステップが失敗・不一致になったら残りを破棄し、**自動でフェーズ③（Remap）へ**（下記「フェーズ④の機械検証」と同一挙動。②で続行しない）。

### フェーズ④の機械検証

→ **[freeze.md](steps/freeze.md)「④再生の機械検証」** に移設（④で読む。実効ポインタは delve-start 手順5）。

## G'. 手順の凍結

→ **[freeze.md](steps/freeze.md)** に分離（必要なときだけ読む）。

## E-3 / F-4 / I-1.5 / I-5

→ **[cp.md](steps/cp.md)** に分離（不可逆操作を含むときだけ読む）。

## H. レビュー・承認・監査

→ **[review.md](steps/review.md)** に分離（承認・送出・ビジュアル引き渡しがあるときだけ読む）。

## D-2. ナレッジ構造記録 / I-3. タスク実行ログ記録

→ **[knowledge.md](steps/knowledge.md)** / **[logging.md](steps/logging.md)** に分離（必要なときだけ読む）。

## K. 完了（順序厳守）

1. 完了報告（成功/失敗、Before→After、フェーズ、次回の最適化候補）
2. **先に** `memory/session-log.md` を更新
3. `touch memory/.workflow/k_done`（Log Gate = 運用ルール: session-log を更新するまで k_done を作らない。hook の技術的強制はない — 順序は自己規律で守る）

## エラー処理

スクリーンショットを撮り、状況をユーザーに報告して指示を仰ぐ。**自動リカバリーは行わない**。エラー内容はログに記録する。

## Money Watch 停止からの復帰

→ **[money-recovery.md](steps/money-recovery.md)** に分離（必要なときだけ読む）。
