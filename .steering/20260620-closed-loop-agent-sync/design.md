# 設計書（訂正版）

## アーキテクチャ概要

研究用エージェントの正本を `claude-dotfiles`（private）に置き、
`claude-config`（public）からは削除する。

```
claude-dotfiles/agents/executor.md    ──┐
claude-dotfiles/agents/sceptic.md     ──┼─ install.sh ──→ ~/.claude/agents/
claude-dotfiles/agents/evaluator.md   ──┘
claude-dotfiles/commands/closed-loop.md ── install.sh ──→ ~/.claude/commands/

claude-config/.claude/agents/executor.md    ← 削除済み（誤配置だった）
claude-config/.claude/agents/sceptic.md     ← 削除済み
claude-config/.claude/agents/evaluator.md   ← 削除済み
claude-config/.claude/commands/closed-loop.md ← 削除済み
```

## 誤配置が起きた原因

1. `sync.sh` が重複チェックをしていなかった
2. ワークスペースルールの確認が不十分なまま「claude-config を正本にする」と決定
3. その誤判断を .steering ドキュメントに記録してしまった

## 再発防止策

`scripts/sync.sh` に `check_duplicates()` を追加。
claude-config と claude-dotfiles の両方に同名ファイルがある場合、
sync.sh がエラー終了して誤配置を検出する。

## ディレクトリ構造（変更後）

```
~/.claude/
├── agents/
│   ├── executor.md    → /Users/sunsun/Developer/claude-dotfiles/agents/executor.md
│   ├── sceptic.md     → /Users/sunsun/Developer/claude-dotfiles/agents/sceptic.md
│   ├── evaluator.md   → /Users/sunsun/Developer/claude-dotfiles/agents/evaluator.md
│   └── ...
└── commands/
    ├── closed-loop.md → /Users/sunsun/Developer/claude-dotfiles/commands/closed-loop.md
    └── ...

claude-config/.claude/agents/   ← executor / sceptic / evaluator なし
claude-config/.claude/commands/ ← closed-loop なし
```

## 実装順序

1. `claude-config` から4ファイルを `git rm`（feat/closed-loop-agents ブランチ）
2. `scripts/sync.sh` に重複チェック追加
3. .steering ドキュメントを訂正
4. PR → main マージ
5. `bash ~/Developer/claude-dotfiles/install.sh` で symlink を dotfiles に切り替え
