---
name: commit
description: 現在の変更をコミットする。git status/diff を確認しCLAUDE.md の規約に従ってコミットメッセージを作成する。"コミットして" などの指示で自動トリガー。
allowed-tools: Bash
---

現在の変更をコミットする。

## 手順

1. `git status` で変更を確認
2. `git diff` で差分の中身を確認
3. 変更内容からコミットメッセージの prefix（feat / fix / docs / refactor 等）を判断
4. `git add -A` でステージング
5. CLAUDE.md の規約に従ってコミットメッセージを作成
6. `git commit`
7. `git log --oneline -1` で結果を確認
