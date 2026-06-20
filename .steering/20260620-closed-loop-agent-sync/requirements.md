# 要求内容

## 概要

closed-loop エージェントチーム（executor / sceptic / evaluator + closed-loop スキル）を
`claude-config` を唯一の正本として `~/.claude/` へ正しく同期し、
Claude Code のどのセッションからでも `/closed-loop` が使える状態にする。

## 背景

今回の実装セッションで以下の問題が生じた：

1. **APIキー問題**: 最初に Python + Anthropic SDK で実装 → `ANTHROPIC_API_KEY` が必要になった
2. **再実装**: Claude Code のエージェントチーム形式（`.md` ファイル）に作り直した
3. **重複**: `claude-dotfiles/agents/` と `claude-config/.claude/agents/` の両方に入った
4. **未同期**: `~/.claude/agents/` に executor / sceptic / evaluator / closed-loop が存在しない
   → 現状、`/closed-loop` は動かない

正本は `claude-config`（公開リポジトリ）であり、
`claude-dotfiles`（非公開）の重複は除去すべき。

## 実装対象の機能

### 1. 重複ファイルの除去（claude-dotfiles）

`claude-dotfiles` に誤って追加した以下のファイルを削除する：

- `agents/executor.md`
- `agents/sceptic.md`
- `agents/evaluator.md`
- `commands/closed-loop.md`

### 2. claude-config の `feat/closed-loop-agents` ブランチを main にマージ

4ファイルを正式に main ブランチに取り込む：

- `.claude/agents/executor.md`
- `.claude/agents/sceptic.md`
- `.claude/agents/evaluator.md`
- `.claude/commands/closed-loop.md`

### 3. sync.sh を実行して ~/.claude/ を更新

`scripts/sync.sh` を手動実行し、上記4ファイルを `~/.claude/agents/` / `~/.claude/commands/` にシンボリックリンクする。

### 4. 動作確認

Claude Code セッションで `/closed-loop` が起動し、3エージェントがループを回せることを確認する。

## 受け入れ条件

### 重複除去

- [ ] `claude-dotfiles/agents/` に executor / sceptic / evaluator が存在しない
- [ ] `claude-dotfiles/commands/` に closed-loop が存在しない
- [ ] claude-dotfiles のブランチへコミット・プッシュ済み

### 同期

- [ ] `~/.claude/agents/executor.md` が `claude-config` を指すシンボリックリンクである
- [ ] `~/.claude/agents/sceptic.md` が `claude-config` を指すシンボリックリンクである
- [ ] `~/.claude/agents/evaluator.md` が `claude-config` を指すシンボリックリンクである
- [ ] `~/.claude/commands/closed-loop.md` が `claude-config` を指すシンボリックリンクである

### 動作確認

- [ ] Claude Code のシステムリマインダーに executor / sceptic / evaluator がエージェントとして表示される
- [ ] `/closed-loop` スキルが認識される

## 成功指標

- `ls -la ~/.claude/agents/ | grep executor` で claude-config へのリンクが確認できる
- `/closed-loop` を呼び出すと executor エージェントが起動する

## スコープ外

- Obsidian vault の未コミット変更（別タスク）
- closed-loop エージェント自体の品質改善・バグ修正
- claude-dotfiles の他のファイル整理

## 参照

- `claude-config/.claude/agents/executor.md` / `sceptic.md` / `evaluator.md`
- `claude-config/.claude/commands/closed-loop.md`
- `claude-config/scripts/sync.sh`
- `claude-dotfiles/install.sh`
