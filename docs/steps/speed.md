# 読み取りと提示の速度規範（正本）

> 複数ページ・複数候補を扱うときに読む。**速くするのは読み取りと提示であって、承認と送出ではない**（承認の粒度・ゲート・監査は一切緩めない）。
> 凍結の条件は [freeze.md](freeze.md)。ここの規範は**フェーズ①②でも適用される** — 凍結前でも1コール集約はできる。

## 1. 読み取りは1コールに集約する

- **複数ページ/複数候補を扱うときは、読み取りを `javascript_tool` の1コールに集約する。1件ずつの read_page 往復をデフォルトにしない**
- 実行可能なら `browser_batch` で束ねる（navigate + 抽出のような固定列を1呼び出しに）
- 同じページで複数観点（速度・品質・リンク健全性・ライセンス等）を測るなら、観点ごとにコールを分けず**1コールで全観点を1つのオブジェクトで返す**
- 返った JSON は表にして提示 = そのまま dry-run 出力・Step H の監査入力になる

一覧 → JSON 一括抽出の型（N回の read_page が1回になる。判定・整形は返った JSON 側で行う）:

```js
[...document.querySelectorAll('.list .item')].map(e => ({
  id: e.dataset.id, name: e.querySelector('.name')?.textContent.trim(),
  attrs: [...e.querySelectorAll('.tag')].map(t => t.textContent.trim()),
  url: e.querySelector('a')?.href,
}))
```

## 2. `browser_batch` の制約（守らないと逆に遅い）

入れ子不可 / ホワイトリスト外の子で呼び出し全体が拒否 / **最初のエラーで停止（後続は未実行）**。
**変更系の子はゲート対象のまま**（batch に束ねても b4_done / e_done / psv_done は必要）。実測仕様は [../rationale.md](../rationale.md)。

## 3. 承認提示のバッチ化

**N件の下書き・候補を1回で一覧提示 → 承認は個別に取る。** 減らすのは提示の往復だけで、承認の粒度は変えない。
対話中も unattended-ops.md の承認キューの型（承認ID付きで `knowledge/approvals/pending.md` に記録 → 一括提示 → 個別に承認）を使う。
