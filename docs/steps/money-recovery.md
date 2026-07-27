# Money Watch 停止からの復帰（money_alert が立ったときに読む）

> `docs/steps-reference.md` から分離（2026-07-27）。**必要なときだけ読む**（内容の移動のみ）。

## Money Watch 停止からの復帰

タスク中に money_alert（金銭・契約系画面の検知）が立ったら: strategy-advisor に状況を渡して助言（STOP/RESPOND/MONITOR）を得る →
操作内容をユーザーに提示して明示承認 → 承認を得た場合のみ `rm memory/.workflow/money_alert` し、承認の事実を session-log に1行記録して再開。

停止中も**画面を読むこと自体は許可されている**（read_page / get_page_text / computer の screenshot・scroll）。
状況を読めないと復帰手順そのものが実行できないため、意図的にそう設計してある。止まるのは変更操作だけ。
ただし **`browser_batch` は読み取りのみでも停止中は deny される**（既知の不整合 — 同じ読み取りが
包み方で通ったり止まったりする）。停止中は batch を使わず、read_page 等を単体で呼ぶこと。

検知は2段階。**【弱】（`Money Watch・注意`）は停止していない** — 注意喚起だけなので、
操作対象が金銭・契約に触れないことを自分で確かめたうえで、そのまま進んでよい。
strategy-advisor もユーザー承認も不要（それが要るのは money_alert が立つ【強】検知のとき）。

**前セッションからの持ち越し**: money_alert はタスクをまたいで残る（/タスク開始 でも消さない）。
セッション開始時に「残留フラグ」の通知が出たら、まずユーザーに「前回の金銭停止が残っています」と
1行で伝え、指示を仰ぐこと。**自分の判断で rm しない。**
