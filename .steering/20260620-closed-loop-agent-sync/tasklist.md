# タスクリスト（訂正版）

> 当初の計画（claude-config を正本にする）は誤りだったため全面書き直し。
> 正本は claude-dotfiles。

## Phase 1: claude-config から誤配置ファイルを削除（feat/closed-loop-agents）

- [x] `.claude/agents/executor.md` を git rm
- [x] `.claude/agents/sceptic.md` を git rm
- [x] `.claude/agents/evaluator.md` を git rm
- [x] `.claude/commands/closed-loop.md` を git rm
- [x] `scripts/sync.sh` に重複チェック（`check_duplicates`）を追加
- [x] .steering ドキュメントを訂正（requirements / design / tasklist）
- [ ] コミット・PR 作成 → main マージ

## Phase 2: ~/.claude/ のシンボリックリンクを dotfiles に切り替え

- [ ] `bash ~/Developer/claude-dotfiles/install.sh` を実行
- [ ] `ls -la ~/.claude/agents/ | grep -E "executor|sceptic|evaluator"` で dotfiles を指すことを確認
- [ ] `ls -la ~/.claude/commands/ | grep closed-loop` で dotfiles を指すことを確認

## Phase 3（将来・別 PR）: research- プレフィックスへのリネーム

- [ ] `claude-dotfiles/agents/executor.md` → `research-executor.md`（frontmatter name も変更）
- [ ] `claude-dotfiles/agents/sceptic.md` → `research-sceptic.md`
- [ ] `claude-dotfiles/agents/evaluator.md` → `research-evaluator.md`
- [ ] `claude-dotfiles/commands/closed-loop.md` 内のエージェント名参照を更新
