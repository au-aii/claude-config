# 要求内容（訂正版）

## 概要

closed-loop エージェントチーム（executor / sceptic / evaluator + closed-loop コマンド）の
正本を `claude-dotfiles`（個人・private）に置き、`claude-config`（チーム・public）から削除する。

## 背景と訂正の経緯

当初の要件定義（初版）は以下の誤った判断を行った：

> 正本は `claude-config`（公開リポジトリ）にする

これはワークスペースルール（`~/Developer/CLAUDE.md`）に違反していた：

| リポジトリ        | 置くべきもの                           |
| ----------------- | -------------------------------------- |
| `claude-dotfiles` | **研究エージェント**・個人コマンド     |
| `claude-config`   | チーム共有の開発エージェント・コマンド |

executor / sceptic / evaluator / closed-loop は**研究用ツール**であり、
`claude-dotfiles` が正本。`claude-config` への配置は誤りだった。

## 実装対象

### 1. claude-config から4ファイルを削除

- `.claude/agents/executor.md`
- `.claude/agents/sceptic.md`
- `.claude/agents/evaluator.md`
- `.claude/commands/closed-loop.md`

### 2. sync.sh に重複チェックを追加

claude-config と claude-dotfiles の両方に同名ファイルが存在する場合、
sync.sh がエラーで停止するガードを追加する。

### 3. dotfiles を正本として ~/.claude/ のリンクを修正

dotfiles には既に4ファイルが存在する。
`bash ~/Developer/claude-dotfiles/install.sh` を再実行してリンクを更新。

## 受け入れ条件

- [ ] `claude-config/.claude/agents/` に executor / sceptic / evaluator が存在しない
- [ ] `claude-config/.claude/commands/` に closed-loop が存在しない
- [ ] `~/.claude/agents/executor.md` が `claude-dotfiles` を指すシンボリックリンク
- [ ] `~/.claude/agents/sceptic.md` が `claude-dotfiles` を指すシンボリックリンク
- [ ] `~/.claude/agents/evaluator.md` が `claude-dotfiles` を指すシンボリックリンク
- [ ] `~/.claude/commands/closed-loop.md` が `claude-dotfiles` を指すシンボリックリンク
- [ ] `bash scripts/sync.sh` が重複ファイルなしで正常終了する

## スコープ外（Phase 2）

- `research-` プレフィックスへのリネーム（副作用が大きいため分離）
- dotfiles の他ファイル整理
