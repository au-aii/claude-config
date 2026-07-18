---
name: task-start
description: 作業開始のワンコマンド。Issue 作成(または既存 Issue 指定)→ Issue 連動ブランチ作成 → worktree 分離 → ベースライン記録を一括実行する。「作業を始めたい」「タスク開始」などの指示で自動トリガー。
allowed-tools: Bash
---

<!-- 自動生成: このファイルは claude-dotfiles から生成された配布物です。直接編集せず、正本(https://github.com/au-aii/claude-dotfiles)を編集して再生成してください。 -->

# Task Start（作業開始: Issue → ブランチ → worktree → ベースライン）

「1作業 = 1worktree = 1ブランチ」と Issue 駆動（CLAUDE.md）の開始手順を決定的に実行する。
素の `git` + `gh` のみで構成する（EnterWorktree 等ハーネス固有機能に依存しない）。

**引数:** `<作業の題名>` または `<既存 Issue 番号>`（`42` / `#42` の形式）

## 前提チェック（満たさなければ中断して報告）

1. `git rev-parse --show-toplevel` — git repo 内であること。repo 外なら対象 repo をユーザーに確認する
2. `git remote get-url origin` — origin があること（無ければ Issue 連携は不可。worktree 分離のみ提案する）
3. `gh auth status` — GitHub CLI が認証済みであること

## 手順

1. **Issue の確定**
   - 引数が番号 → `gh issue view <n>` で存在確認し、その Issue を使う
   - 引数が題名 → 新規作成し、**出力 URL の末尾から番号を取得する**（後続手順はすべて `$n` に依存する）:

     ```bash
     url="$(gh issue create --title '<題名>' --body "$(cat <<'EOF'
     <背景・要件・検証観点の要約>
     EOF
     )")"
     n="${url##*/}"
     ```

     - 題名・本文はユーザーの自由入力。引用符・`$`・バッククォートでシェルが壊れないよう、本文は上記の quoted heredoc、題名はシングルクォートで渡す
2. **Issue 連動ブランチの作成（checkout しない）**
   - `gh issue develop <n> --list` で既存の連動ブランチを確認。あればそれを使う（新規作成しない）。複数あれば先頭を使い、どれを選んだか報告に含める
   - 無ければ作成する:

     ```bash
     base="$(git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|^origin/||')"
     gh issue develop <n> --name "<prefix>/<n>-<slug>" --base "$base"
     ```

     - prefix は内容で判断（feat / fix / chore / docs）。slug は英小文字ケバブ 30 字以内
     - `origin/HEAD` が未設定で symbolic-ref が失敗したら `git remote set-head origin -a` してから再試行

   - **`--checkout` は使わない。共有 working tree のブランチを切り替えない**（並行セッションのブランチ切替波及を防ぐ。cf. CLAUDE.md マルチセッション git 運用）
3. **worktree 分離**
   - 既に同ブランチの worktree があれば（`git worktree list`）新規作成せずそのパスを報告して使う
   - 無ければ作成する。リモートにのみ存在するブランチは DWIM に頼らず追跡元を明示する（複数リモート環境でも決定的）:

     ```bash
     git fetch origin "<branch>"
     path="$HOME/Developer/.worktrees/<repo名>/<n>-<slug>"
     if git show-ref --verify -q "refs/heads/<branch>"; then
       git worktree add "$path" "<branch>"
     else
       git worktree add -b "<branch>" "$path" "origin/<branch>"
     fi
     ```

   - 置き場所は `~/Developer/.worktrees/` 固定（scratchpad/tmp は再起動で消え、未コミット変更を失うため使わない）
4. **ベースラインを Issue コメントに記録**（どのセッション・どの人間からでも作業場所を発見可能にする）

   ```bash
   sha="$(git -C "$path" rev-parse HEAD)"
   gh issue comment "$n" --body "作業開始: branch=<branch> / base=${sha} / worktree=${path/#$HOME/~}"
   ```

   - **実パス（ホームディレクトリ配下の絶対パス）を Issue に書かない**。`${path/#$HOME/~}` で `~` 表記に置換する（public repo での実パス漏洩防止。cf. Workspace ルールの機密スキャン）
   - 前の手順と別々の Bash 実行になる場合、`$path`・`$n` は引き継がれない前提で同一ブロック内で再定義する

5. **報告**: Issue 番号・ブランチ・worktree パス・「以降の編集はすべて worktree 側で行う」を提示して終了する。実装まで続けて指示されている場合も、編集は必ず worktree 側で行う

## 完了後の合流（このコマンドのスコープ外）

- worktree 内で `/ship`（レビュー → PR 作成 → マージ）
- マージ後の掃除: `git worktree remove <path>`（ブランチ削除は /ship が行う）

## 禁止事項

- 共有 working tree での checkout・ブランチ切替（`gh issue develop --checkout` を含む）
- レビュー証跡マーカーの事前作成（/ship のレビュー完走後にのみ作成される）
- `git add -A`（worktree 内でも、この作業で変更した対象ファイルだけを add する）
