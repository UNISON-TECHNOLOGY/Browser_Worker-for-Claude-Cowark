# プラットフォーム上申事項（プラグインでは根治不可の課題台帳）

2026-07-24 の実運用検証（v0.94.0 全項目ラン + 実弾E2E）で確定した、Cowork / Claude in Chrome 本体側でしか根治できない課題。プラグイン側の緩和策とセットで記録する。issue 起票時は「本体修正」「ドキュメント修正」「上申」の3束で管理。

| # | 重大度 | 課題 | プラグイン側の緩和（実装済み） | 上申内容 |
|---|---|---|---|---|
| E1 | **最重要（セキュリティ）** | Credential Guard の ref すり抜け: hooks はツール引数の文字列しか見えず、`ref_150` 等の参照IDの解決先が type=password かを判定できない（2026-07-24 実測: Wikipedia 実 password 欄に入力が素通り） | steps-reference「認証フィールドの取り扱い」の自己規律 + V5 に ref 回帰テスト + キーワード検知（従来） | **Claude in Chrome 拡張側で、入力系操作の ref 解決先要素の type=password / autocomplete（current-password / one-time-code 等）を検査してブロックする機構** |
| E2 | 致命（無人運用） | ローカルスケジュールのプログラマティック登録不可: 「このコンピュータで実行」スケジュールはデスクトップアプリのUI操作でのみ作成でき、AI/プラグインから登録できない（create_trigger はクラウド発火で実PC Chrome に不達） | delve-task / unattended-ops で「ブラウザ操作タスクは create_trigger 禁止・ローカル登録」の規約化 + 登録手順の案内 + 無人運用前チェック | **ローカル（デバイス指定）スケジュールをプログラマティックに登録するAPI/ツール** |
| E3 | 高（資産継続性） | クラウド/ローカルのワークスペース分断: クラウドセッションの作業場はコンテナ内のみで、ローカルセッションは別ファイルシステム。資産（knowledge/tasks/memory/コマンド）が引き継がれない | unattended-ops §クラウド→ローカル移行（zip 書き出し→接続フォルダ→展開。56ファイルで実証） | **ワークスペース資産のクラウド/ローカル同期機構** |
| E4 | **最重要（セキュリティ）** | **ローカル Cowork で plugin hooks が未配線**: デスクトップのローカルセッションでは PreToolUse/PostToolUse がツール呼び出しに配線されず、matcher 完全一致のツール（mcp__claude-in-chrome__navigate）でも不発（2026-07-24 v1.0.0 で Opus/Sonnet 両ラン実測）。全ゲートがフェイルオープンになる。付随: ローカルのツール名も cloud と異なる（Bash→mcp__workspace__bash / 送付→mcp__cowork__present_files） | README 既知の限界に開示 + 「ゲート前提の運用（一括送出・金銭近傍・無人）は cloud で」の運用規約 + matcher にローカルツール名を先回り登録（配線され次第有効） / **v1.11.0: session-rules の hook 非依存到達経路（delve-start 手順0.5 が自力 Read）・Money Watch の自己規律化・delve-verify のローカル分岐（deny 系は SKIP + LV1〜LV3 の自己規律検証）を実装。hooks 配線問題自体は未解決のまま** | **ローカルセッションでも plugin hooks を配線する（少なくとも PreToolUse）。併せてツール名の cloud/ローカル差の解消 or 対応表の公開** |
| E5 | 中（文脈喪失時の自己復帰） | **SessionStart フックが compaction 時に発火するか未実測**: auto-compact / 手動 `/compact` で文脈が切り詰められたあと SessionStart が再発火するかが確認できていない。発火しない場合、残留フラグ（money_alert / critic_pending / bulk_send 等）の再通知が働かず、**deny されるまで自分が停止状態にあることを知らないまま進む**（deny 自体は残るため fail-closed は維持され、実害は「無駄な1コール + 原因不明感」に限定される。2026-07-28 のコンテキスト管理監査で確定した未解決課題 — 実機検証が必要） | 全ゲートの deny 文言に `/状態確認`（delve-status）への導線を追加（文脈喪失後でも deny 1回で状態一覧に自走できる）+ deny 減衰カウンタをセッション開始時にクリア | **compaction 前後でのフック発火仕様の明文化（SessionStart が compaction 時に発火するか／`source` で区別できるか）。発火しないなら、compaction 直後に注入できるフックイベントの提供** |

## E4 の代替手段（調査済み・現時点では未導入）

2026-07-27 に Claude in Chrome 拡張 v1.0.81 の実体を調査したところ、**Chrome のエンタープライズポリシーに対応**していた（`managed_schema.json`: `blockedUrlPatterns` / `forceLoginOrgUUID`）。

```
HKLM\SOFTWARE\Policies\Google\Chrome\3rdparty\extensions\
    fcoeoabgfenejglbffodgkkbkcdhcgfn\policy\blockedUrlPatterns
      "1" = "*/billing*"      ← ホスト名+パスで照合・'*' ワイルドカード可
```

**ブラウザ本体が強制するため hooks の生死に関係なく効き、サンドボックス内の AI からは
レジストリに到達できないので意図的な迂回にも耐える**（現行設計で唯一の層）。

**それでも現時点では導入しない。** 理由:

- 粒度が URL 単位のみ。該当ドメインで拡張が丸ごと無効になり、読み取りまで止まる（「請求ページは見せるが操作させない」ができない）
- 適用は人手のレジストリ操作（HKLM は管理者権限）。一時開放にも Chrome 再起動が要る
- **設定者と運用者が同一人物のうちは、自分で自分を縛る鍵にしかならず手間に見合わない**。「うっかり・手順飛ばし」への防御は hooks で足りている

**再検討の条件**: このプラグインを複数人・組織に配布し、ポリシー設定者（管理者）と運用者が分かれたとき。そのときは `knowledge/config/url-denylist.txt` の金銭・広告出稿系パターンをポリシー側にも二重化する。

更新規則: 上申が本体側で解決されたら該当行に解決バージョンを記録し、プラグイン側の緩和策を撤去できるか検討する。新たな「プラグインでは根治不可」が確定したら行を追加する。
