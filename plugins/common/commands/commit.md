---
name: commit
description: 現在の変更をコミットする。git status/diff を確認しCLAUDE.md の規約に従ってコミットメッセージを作成する。"コミットして" などの指示で自動トリガー。
allowed-tools: Bash
---

<!-- 自動生成: このファイルは claude-dotfiles から生成された配布物です。直接編集せず、正本(https://github.com/au-aii/claude-dotfiles)を編集して再生成してください。 -->

現在の変更をコミットする。

## 手順

1. `git status` で変更を確認
2. `git diff` で差分の中身を確認
3. 変更内容からコミットメッセージの prefix（feat / fix / docs / refactor 等）を判断
4. 対象ファイルのみ `git add <path>` でステージングする（`git add -A` は使わない。他セッション・人間の未コミット変更を巻き込まないため。CLAUDE.md マルチセッション git 運用に準拠）
5. CLAUDE.md の規約に従ってコミットメッセージを作成
6. `git commit`
7. `git log --oneline -1` で結果を確認

## 完了条件

- `git commit` が成功し、`git log --oneline -1` の結果を提示した
- ステージしたのは対象ファイルのみ（無関係な未コミット変更を巻き込んでいない）
