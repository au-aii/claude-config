---
name: commit-push
description: 現在のブランチにコミットしてリモートへプッシュする。main/master への直接プッシュは禁止。"プッシュして" などの指示で自動トリガー。
allowed-tools: Bash
---

現在のブランチに対して、CLAUDE.md の規約に従ってコミットを作成し、リモートへプッシュする。

## 手順

1. `git branch --show-current` で現在のブランチを確認。main / master の場合は CLAUDE.md の制限に従い終了する。
2. `git status` / `git diff` / `git diff --cached` / `git log --oneline -5` で差分を確認。変更がなければ報告して終了。
3. `/commit` と同じ手順でコミットメッセージを作成して `git commit` する。
4. `git push -u origin <current-branch>` でリモートへプッシュ。
5. `git status` / `git log --oneline -1` で結果を確認。
