---
name: setup-steering
description: "作業用の requirements / design / tasklist を作成する。/add-feature の計画部分（requirements / design / tasklist 作成）だけを単体で実行したい場合に使う。"
---

<!-- 自動生成: このファイルは claude-dotfiles から生成された配布物です。直接編集せず、正本(https://github.com/au-aii/claude-dotfiles)を編集して再生成してください。 -->

# ステアリングファイルのセットアップ

**引数:** 開発タイトル (例: `/setup-steering ユーザープロフィール編集`)

---

## 手順

1. 現在の日付を `YYYYMMDD` 形式で取得し、ステアリングディレクトリパスを決定する。
   - パス: `.steering/[日付]-[開発タイトル]/`

2. ステアリングディレクトリを作成し、以下の3ファイルを用意する。
   - `.steering/[日付]-[開発タイトル]/requirements.md`
   - `.steering/[日付]-[開発タイトル]/design.md`
   - `.steering/[日付]-[開発タイトル]/tasklist.md`

3. `Skill('steering')` を**計画モード（モード1）**で実行し、3ファイルの内容を生成する。
   - `docs/` 内の永続ドキュメントを参照してプロジェクトの方針を反映すること。

4. 作成完了後、生成した3ファイルのパスをユーザーに報告する。

## 完了条件

- `.steering/[日付]-[開発タイトル]/requirements.md` が作成されている
- `.steering/[日付]-[開発タイトル]/design.md` が作成されている
- `.steering/[日付]-[開発タイトル]/tasklist.md` が作成されている
