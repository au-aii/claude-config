# 設計書

## アーキテクチャ概要

エージェント定義の正本を `claude-config` に一元化し、`sync.sh` 経由で `~/.claude/` にシンボリックリンクする。

```
claude-config/.claude/agents/executor.md   ──┐
claude-config/.claude/agents/sceptic.md    ──┼─ sync.sh ──→ ~/.claude/agents/  (Claude Code が読む)
claude-config/.claude/agents/evaluator.md  ──┘
claude-config/.claude/commands/closed-loop.md ── sync.sh ──→ ~/.claude/commands/

claude-dotfiles/agents/executor.md   ← 削除（重複）
claude-dotfiles/agents/sceptic.md    ← 削除（重複）
claude-dotfiles/agents/evaluator.md  ← 削除（重複）
claude-dotfiles/commands/closed-loop.md ← 削除（重複）
```

## 優先順位のルール（sync.sh の設計）

`sync.sh` はリンク先が `claude-config` 以外のファイルはスキップする（上書きしない）。
`claude-dotfiles/install.sh` は上書きする。

よって正しい実行順序：

1. `claude-dotfiles` から重複ファイルを削除・コミット
2. `sync.sh` を実行 → 空きスロットに claude-config のリンクが作られる

## コンポーネント設計

### 1. claude-dotfiles（重複除去）

**責務**: executor / sceptic / evaluator / closed-loop を削除し、claude-config を正本として明示する

**実装の要点**:

- `git rm` でファイルを削除してコミット
- `chore/remove-obsidian-agents-duplicate` ブランチで作業（すでに存在）
- PR を出してマージ、または main へ直接コミット（軽微な削除のため許容）

### 2. claude-config（正本）

**責務**: `feat/closed-loop-agents` ブランチを main にマージして4ファイルを確定する

**実装の要点**:

- PR 作成 → マージ（または squash merge）
- main ブランチへのマージ後、git hook（post-merge）が `sync.sh` を自動実行する

### 3. sync.sh（自動リンク）

**責務**: `.claude/agents/*.md` と `.claude/commands/*.md` を `~/.claude/` にシンボリックリンクする

**実装の要点**:

- `scripts/sync.sh` はすでに実装済み
- git pull / merge 後に自動実行される（`.githooks/post-merge` 経由）
- 手動実行も可能: `bash scripts/sync.sh`

## データフロー

### 正常フロー

```
1. claude-dotfiles の重複4ファイルを git rm → commit → push
2. claude-config の feat ブランチを main にマージ
3. post-merge hook が sync.sh を自動実行
   または手動で bash scripts/sync.sh を実行
4. ~/.claude/agents/ に executor/sceptic/evaluator のシンボリックリンクが作成される
5. ~/.claude/commands/ に closed-loop のシンボリックリンクが作成される
6. Claude Code セッションで /closed-loop が使用可能になる
```

## ディレクトリ構造（変更後）

```
~/.claude/
├── agents/
│   ├── executor.md    → /Users/sunsun/Developer/claude-config/.claude/agents/executor.md
│   ├── sceptic.md     → /Users/sunsun/Developer/claude-config/.claude/agents/sceptic.md
│   ├── evaluator.md   → /Users/sunsun/Developer/claude-config/.claude/agents/evaluator.md
│   └── ...（既存）
└── commands/
    ├── closed-loop.md → /Users/sunsun/Developer/claude-config/.claude/commands/closed-loop.md
    └── ...（既存）

claude-dotfiles/agents/
├── academic-writer.md  ← 残す
├── architect.md        ← 残す
├── coach.md            ← 残す
...（executor/sceptic/evaluator は削除）

claude-dotfiles/commands/
├── asdd.md             ← 残す
...（closed-loop は削除）
```

## 実装の順序

1. claude-dotfiles から4ファイルを `git rm` して commit・push
2. claude-config の `feat/closed-loop-agents` ブランチを main にマージ（PR 経由）
3. `bash ~/Developer/claude-config/scripts/sync.sh` を実行
4. `ls -la ~/.claude/agents/ | grep -E "executor|sceptic|evaluator"` で確認
5. Claude Code セッションで動作確認

## セキュリティ考慮事項

- sync.sh はシンボリックリンクのみ作成。ファイル内容を変更しない
- 既存の他リポジトリへのリンクは上書きしない（claude-dotfiles 優先のルールを維持）
