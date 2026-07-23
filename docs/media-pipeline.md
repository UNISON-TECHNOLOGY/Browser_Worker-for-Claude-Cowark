# メディア制作パイプライン — 正本

画像・動画系の内蔵部品の全体地図（2026-07-23 Cowork 実機検証済み）。各手順書はここを参照する（複製しない）。

## 部品一覧

| 部品 | 実体 | 用途 |
|---|---|---|
| 画像生成 | /画像生成（delve-imagegen） | Gemini/ChatGPT の UI 操作で生成。グリーンバック指定可 |
| 動画生成 | /画像生成（delve-imagegen §2b） | **Gemini 経由で実機検証済み（2026-07-23）**。生成AI動画→取り込みは画像と同じルート（専用DLフォルダ / blob fetch） |
| 素材調達 | /素材探し（delve-assets） | ストックサイトからライセンス証跡つき取り込み |
| 切り抜き | `templates/chromakey.py` | GB生成画像 → 透過PNG（緑優勢度→連続アルファ+スピル抑制） |
| バナー合成 | `templates/banner-compose.py` | 16:9整形+グラデ+コピー焼き込み（copywriting→ad-compliance 済み文言） |
| ガイドアニメ | `templates/guide-anim.py` | スクショ+ステップJSON → 注釈アニメ mp4/GIF |
| ブラウザ録画 | gif_creator 系ツール | タブ内操作の GIF 記録（最大50フレーム・Downloads 保存→専用DLフォルダ原則） |
| 動画変換・透過動画 | ffmpeg（下記レシピ） | WebM 圧縮 / **アルファ付き WebM**（LP埋め込み用） |
| 組版・共有 | /キャンバ・DesignSync | Canva 流し込み / claude.ai/design 同期 |

## ffmpeg レシピ（実測値つき）

ffmpeg は Cowork サンドボックス標準搭載。ローカル Windows に無い場合はフレーム残置+コマンド提示（guide-anim.py の挙動）。

```bash
# mp4 → WebM (VP9)。実測: 88KB → 67KB。さらに詰めるなら AV1（libaom-av1）も搭載済み
ffmpeg -i in.mp4 -c:v libvpx-vp9 -b:v 0 -crf 40 out.webm

# 透過PNGフレーク列 → アルファ付き WebM（VP9 は透明度を保持。実測: 人物浮遊ループ 13KB）
# 必須: -pix_fmt yuva420p と -auto-alt-ref 0（これが無いとアルファが落ちる）
ffmpeg -framerate 24 -i f%04d.png -c:v libvpx-vp9 -pix_fmt yuva420p -b:v 0 -crf 40 -auto-alt-ref 0 out.webm
```

浮遊ループのフレームは透過PNGを sin オフセットで数十枚描画すれば足りる（Pillow で `img.paste(fg, (0, int(8*sin(2πt))), fg)` の型）。

## 定番ライン

1. **バナー量産**: 生成（GB不要）→ banner-compose（コピー案リスト×画像ループ）→ /定常タスク 化
2. **LPの動く人物/オブジェクト**（2026-07-23 動画生成起点でもフルライン実証済み: Gemini動画→背景除去→WebM）: GB指定生成 → chromakey → 浮遊フレーム → アルファWebM → モックアップに `<video autoplay loop muted playsinline>` で任意背景の上に重ねる（GIFより滑らかで軽い。delve-improve / delve-adlp の演出部品）
3. **操作教材**: gif_creator で実録画 → 専用DLフォルダ回収 → guide-anim / ffmpeg で注釈焼き込み → ガイド/レポートに添付

## 共通ルール

- 公開向けコピーは ad-compliance-jp を通す / 人物素材はモデルリリース（/素材探し）または生成でも実在人物風は禁止
- 取り込み・生成物はすべて `knowledge/assets/` + 出典台帳（sources.md）に記録
- Downloads 本体は接続しない（専用DLフォルダ原則）
- **前提: フル解像度素材の加工には専用DLフォルダ接続が必須**（README「メディア制作を使う場合」の3手順）。未接続で加工依頼が来たら、Downloads→手動アップロードで代替せず（**レンダリング失敗の実測あり 2026-07-23**）、先にセットアップを依頼して止まる。blob fetch が使える場面（URL露出）のみ例外
