---
name: ship
description: 現在のブランチをレビュー先行で出荷する。push→レビュー→修正ループ(cleanまで)→PR作成→マージを一気通貫で実行。"シップして" "PRを出して" などの指示で自動トリガー。
allowed-tools: Bash, Read, Glob, Grep, Agent
---

<!-- 自動生成: このファイルは claude-dotfiles から生成された配布物です。直接編集せず、正本(https://github.com/au-aii/claude-dotfiles)を編集して再生成してください。 -->

# Ship（レビュー先行の出荷: push → レビュー → PR作成 → マージ）

**重要:** レビューが clean（reviewer-agent が ✅ LGTM）になるまで PR を作成しない。**これはこのコマンド自身が守る規律であり、`hooks/guard.sh` の有無に依存しない。** config 経由で dev plugin だけを導入した環境（guard.sh は配布対象外）では、機械的な強制は無く、このコマンド定義に従ってレビューを先に完走させること自体がレビュー先行を支える（手順遵守に依存する運用規律）。dotfiles ネイティブ環境では加えて guard.sh が証跡マーカーの無い `gh pr create` を物理ブロックし、規律を機械的にも強制する（このワークフローに従えば自然に通過する）。各ステップは完了後、ただちに次のステップへ移行すること。

**引数:** なし（オプション: PR タイトルと本文を省略した場合は自動生成）

---

## ステップ1: 事前確認

1. 現在のブランチを確認し、`main` / `master` の場合は中断する。

   ```bash
   git branch --show-current
   ```

2. 未コミットの変更がある場合は `/commit` と同じ手順でコミットする。
   **`git add -A` は使わない。この作業で変更した対象ファイルだけを `git add <path>` する**（並行セッションや人間の未コミット変更を巻き込まない）。

3. リモートへプッシュされていない場合はプッシュする。

   ```bash
   git push -u origin <current-branch>
   ```

## ステップ2: レビュー（PR 作成前）

`Agent` ツールで `reviewer-agent` を起動し、**ブランチ差分**をレビューする。

- `subagent_type`: "reviewer-agent"
- `description`: "branch diff review"
- `prompt`: "PR はまだ存在しない。origin/main...HEAD の差分をレビューし、結果を返答で報告してください。GitHub への投稿はしないこと。"

## ステップ3: レビュー結果の判定と修正ループ（最大3回）

**修正試行回数を管理する。3回を超えたらユーザーに判断を仰ぐ。**

- **✅ LGTM** → ステップ4（証跡マーカー作成）へ進む
- **❌ 要修正** → 以下を実行してステップ2へ戻る:
  1. 指摘された問題を修正する（コード変更・テスト追加など）
  2. **対象ファイルだけ** `git add <path>` する
  3. `git branch --show-current` で現在ブランチを確認してからコミット・プッシュする

     ```bash
     git commit -m "fix: レビュー指摘対応 - [修正内容の要約]

     Co-Authored-By: Claude <noreply@anthropic.com>"
     git push
     ```

**3回修正してもまだ ❌ 要修正の場合:** 残っている指摘事項と修正できなかった理由をユーザーに報告し、手動対応を依頼して停止する。

## ステップ4: レビュー証跡マーカーの作成（dotfiles ネイティブ環境の物理強制層）

レビューが clean（✅ LGTM）になった直後に作成する。`hooks/guard.sh` を導入した dotfiles ネイティブ環境では、これが無いと guard.sh が PR 作成をブロックする。

```bash
marker_dir="$(git rev-parse --absolute-git-dir)/claude"
mkdir -p "$marker_dir"
printf 'branch=%s\nsha=%s\n' "$(git branch --show-current)" "$(git rev-parse HEAD)" > "$marker_dir/review-passed"
```

**config 経由で dev plugin だけを導入した環境には guard.sh が無いため、このマーカーは作られても参照されない（実行しても無害）。その環境ではステップ3の ✅ LGTM ゲートが唯一の担保であり、レビューを飛ばして PR を作らないこと自体がこのコマンドの責務。**

**禁止: レビューを完走せずにマーカーだけ作成すること（証跡の偽造）。** マーカーは branch と HEAD sha に束縛されるため、作成後にコミットを積むと無効になる（再レビューが必要）。

## ステップ5: PR作成

1. `git log origin/main...HEAD --oneline` と `git diff origin/main...HEAD --stat` で変更内容を把握する。

2. 変更内容から PR タイトルと本文を自動生成し、`gh pr create` で PR を作成する。
   - タイトル: 変更の要点を70文字以内で（日本語可）
   - 本文フォーマット:

     ```
     ## 概要
     - [変更点を箇条書き]

     ## 変更の背景
     [なぜこの変更が必要か]

     ## テスト観点
     - [確認すべき点と実施済み検証を箇条書き]

     ## レビュー
     - reviewer-agent によるレビューを完走済み（✅ LGTM、修正 N 回）

     🤖 Generated with Claude Code
     ```

3. 作成した PR の番号と URL を記録する。

## ステップ6: マージ

1. マージ前に最終確認としてテストを実行する（定義がある場合のみ）。
   - `package.json` があれば `npm test` など

2. `gh pr merge` でマージする。

   ```bash
   gh pr merge --squash --delete-branch
   ```

   - デフォルトは squash merge + ブランチ削除
   - ユーザーが引数で別のマージ戦略を指定した場合はそれに従う

3. マージ成功後、証跡マーカーを削除し `main` に戻る。

   ```bash
   rm -f "$(git rev-parse --absolute-git-dir)/claude/review-passed"
   git checkout main
   git pull
   ```

## 完了条件

- レビューで ✅ LGTM を取得している（PR 作成より**前**）
- PR が作成されている
- PR が main にマージされている
- 作業ブランチが削除されている（ステップ6の後片付け＝証跡マーカー削除・main 復帰も完了）

## 中断条件（ユーザーに報告して停止）

- `main` / `master` ブランチで実行された
- 修正を3回試みても ❌ 要修正が解消されない
- マージコンフリクトが発生した
- `gh pr create` や `gh pr merge` が権限・ガードによりブロックされた（自己判断で回避しない）
