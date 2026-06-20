# タスクリスト

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール

- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

---

## フェーズ1: claude-dotfiles の重複除去

- [ ] `chore/remove-obsidian-agents-duplicate` ブランチへ移動
  - [ ] `git -C ~/Developer/claude-dotfiles checkout chore/remove-obsidian-agents-duplicate`
- [ ] 重複4ファイルを削除
  - [ ] `git -C ~/Developer/claude-dotfiles rm agents/executor.md`
  - [ ] `git -C ~/Developer/claude-dotfiles rm agents/sceptic.md`
  - [ ] `git -C ~/Developer/claude-dotfiles rm agents/evaluator.md`
  - [ ] `git -C ~/Developer/claude-dotfiles rm commands/closed-loop.md`
- [ ] コミット・プッシュ
  - [ ] `git commit -m "chore(agents): closed-loopエージェントをclaude-configへ移管"`
  - [ ] `git push`

## フェーズ2: claude-config の main マージ

- [ ] `feat/closed-loop-agents` ブランチの PR を作成
  - [ ] `gh pr create -R au-aii/claude-config --base main --head feat/closed-loop-agents`
- [ ] PR をマージ
  - [ ] `gh pr merge --squash` または GitHub UI でマージ
- [ ] main ブランチを最新化
  - [ ] `git -C ~/Developer/claude-config checkout main && git pull`

## フェーズ3: ~/.claude/ への同期

- [ ] sync.sh を手動実行
  - [ ] `bash ~/Developer/claude-config/scripts/sync.sh`
- [ ] シンボリックリンクを確認
  - [ ] `ls -la ~/.claude/agents/ | grep -E "executor|sceptic|evaluator"`
  - [ ] `ls -la ~/.claude/commands/ | grep closed-loop`
  - [ ] 全て `claude-config` を指していることを確認

## フェーズ4: 動作確認

- [ ] Claude Code セッションを再起動（または新しいセッションを開く）
- [ ] システムリマインダーに executor / sceptic / evaluator が表示されることを確認
- [ ] `/closed-loop` スキルが認識されることを確認
- [ ] テスト実行
  - [ ] `/closed-loop フィボナッチ数列の最適なPython実装を3手法で比較し、n=30のベンチマーク結果を示せ`
  - [ ] Executor が JSON でコードを返すことを確認
  - [ ] Bash サンドボックスでコードが実行されることを確認
  - [ ] Sceptic・Evaluator が動作することを確認

---

## 実装後の振り返り

### 実装完了日

{YYYY-MM-DD}

### 計画と実績の差分

## **計画と異なった点**:

## **新たに必要になったタスク**:

### 学んだこと

-

### 次回への改善提案

-
