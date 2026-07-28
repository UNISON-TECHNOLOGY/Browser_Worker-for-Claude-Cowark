# 台帳チェックリスト（追加時 / 配布時）

`docs/command-registry.md` から分離（2026-07-28。150行上限のため。内容の移動のみ）。
コマンド・媒体・部品・リファレンスを追加するとき、および配布するときに読む。

## 追加時のチェックリスト

- [ ] 新しい媒体 → 原則 **/ワーク追加**（ワークスペース側に動的生成。プラグインは変更しない）。プラグイン標準パックに昇格させる場合のみ `commands/<日本語名>.md` + `procedures/delve-<name>.md` を追加
- [ ] 新しいSNS標準媒体 → `procedures/delve-sns-<name>.md` 追加とセットで **4点配線**: ①delve-sns の振り分け表 ②delve-sns §0 の媒体名リスト ③delve-setup 質問1の選択肢 ④command-registry の内部手順一覧（2026-07-24 Threads 追加時に④が漏れた教訓）
- [ ] 新しい能力 → `docs/parts/<name>.md`（部品）+ parts/index.md に行追加。**コマンドは増やさない**
- [ ] 新しい執筆リファレンス（references/）→ session-rules(3) と **該当サブエージェント（deliverable-writer / design-artisan / design-critic / pre-send-verifier）の参照表にも配線**（エージェントは自分でルールを読まないため、定義ファイルに書かないと届かない）
- [ ] command-registry の該当台帳に1行追加（カテゴリー + Pack）。定常実行するものはループ台帳にも追加
- [ ] README の同梱物の件数を更新（コマンド数・手順書数・エージェント数。README の「既知の限界」は escalations.md へのポインタなので同期不要）
- [ ] 両 version ファイルを bump（`scripts/bump-version.sh <ver>`）

## 配布時チェックリスト（Cowork 配布の実態に合わせた品質ゲート）

Cowork の配布は marketplace 同期＝**このリポジトリがそのまま配布物**（削除ビルドは存在しない）。/検証・TESTING・scripts/・.github/ は**品質保証機能として同梱する**（利用者が「プラグインを検証して」でいつでもセルフテストでき、CI が push ごとに回帰を担保する設計）。配布＝以下がすべて緑であること:

- [ ] `python scripts/lint.py` → `lint: OK`（双方向突合・行数上限）
- [ ] `bash scripts/test-hooks.sh` → `ALL PASS`（防御系回帰）
- [ ] CI（GitHub Actions）最新 run が success
- [ ] Cowork 実機での直近の `/検証 full` 結果が TESTING.md 末尾に記録され、FAIL 0（未解消 FAIL があれば配布延期）
- [ ] `.claude-plugin/` の version が配布告知と一致（bump 忘れは更新反映されない）
- [ ] `docs/escalations.md` の上申事項が最新（README はここへのポインタなので README 側の文面同期は不要）
