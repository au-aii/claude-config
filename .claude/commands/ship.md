---
name: ship
description: 現在のブランチをPR作成→自動レビュー→修正ループ→マージまで一気通貫で実行する。"シップして" "PRを出して" などの指示で自動トリガー。
allowed-tools: Bash, Read, Glob, Grep, Agent
---

# Ship (PR作成〜マージの完全自動実行)

**重要:** このワークフローは、ユーザーの介入なしに、PR作成からマージまで完全に自動で実行されます。各ステップは完了後、ただちに次のステップへ移行してください。

**引数:** なし（オプション: PR タイトルと本文を省略した場合は自動生成）

---

## ステップ1: 事前確認

1. 現在のブランチを確認し、`main` / `master` の場合は中断する。

   ```bash
   git branch --show-current
   ```

2. 未コミットの変更がある場合は `/commit` と同じ手順でコミットする。

   ```bash
   git status
   ```

3. リモートへプッシュされていない場合はプッシュする。
   ```bash
   git push -u origin <current-branch>
   ```

## ステップ2: PR作成

1. `git log main...HEAD --oneline` と `git diff main...HEAD --stat` で変更内容を把握する。

2. 変更内容から PR タイトルと本文を自動生成し、`gh pr create` で PR を作成する。
   - タイトル: 変更の要点を70文字以内で（日本語可）
   - 本文フォーマット:

     ```
     ## 概要
     - [変更点を箇条書き]

     ## 変更の背景
     [なぜこの変更が必要か]

     ## テスト観点
     - [確認すべき点を箇条書き]

     🤖 Generated with Claude Code
     ```

3. 作成した PR の番号と URL を記録する。

## ステップ3: 自動レビュー

`Agent` ツールで `reviewer-agent` を起動し、PR のレビューと GitHub へのコメント投稿を実行する。

- `subagent_type`: "reviewer-agent"
- `description`: "PR auto review"
- `prompt`: "現在の PR をレビューし、結果を GitHub PR コメントに投稿してください。"

## ステップ4: レビュー結果の判定

1. 投稿された PR コメントを取得する。

   ```bash
   gh pr view --comments
   ```

2. 総合判断を読み取る:
   - **✅ LGTM** → ステップ5（マージ）へ進む
   - **❌ 要修正** → ステップ4a（修正ループ）へ進む

### ステップ4a: 修正ループ（最大3回）

**修正試行回数を管理する。3回を超えたらユーザーに判断を仰ぐ。**

1. レビューコメントの指摘事項を全て読み取る。
2. 指摘された問題を修正する（コード変更・テスト追加など）。
3. 修正をコミットしてプッシュする。

   ```bash
   git add -A
   git commit -m "fix: レビュー指摘対応 - [修正内容の要約]

   Co-Authored-By: Claude <noreply@anthropic.com>"
   git push
   ```

4. ステップ3（自動レビュー）に戻る。

**3回修正してもまだ ❌ 要修正の場合:**

- 残っている指摘事項と修正できなかった理由をユーザーに報告し、手動対応を依頼する。

## ステップ5: マージ

1. マージ前に最終確認としてテストを実行する（定義がある場合のみ）。
   - `package.json` があれば `npm test` など

2. `gh pr merge` でマージする。

   ```bash
   gh pr merge --squash --delete-branch
   ```
   - デフォルトは squash merge + ブランチ削除
   - ユーザーが引数で別のマージ戦略を指定した場合はそれに従う

3. マージ完了後、`main` に戻る。
   ```bash
   git checkout main
   git pull
   ```

## 完了条件

- PR が作成されている
- レビューで LGTM を取得している
- PR が main にマージされている
- 作業ブランチが削除されている

## 中断条件（ユーザーに報告して停止）

- `main` / `master` ブランチで実行された
- 修正を3回試みても ❌ 要修正が解消されない
- マージコンフリクトが発生した
