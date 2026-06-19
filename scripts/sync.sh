#!/usr/bin/env bash
# claude-config の commands/agents を ~/.claude/ にシンボリックリンクで同期する。
# git pull (merge/rebase 両方) 後に自動実行される。手動実行も可。
#
# 優先順位: 個人設定（claude-dotfiles 等）> このリポジトリ（claude-config）
# - リンク先が claude-config 以外のファイルは上書きしない
# - 通常ファイル（手動作成）も上書きしない
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="$REPO_ROOT/.claude"
TARGET_ROOT="$HOME/.claude"

sync_dir() {
  local src_dir="$CLAUDE_DIR/$1"
  local dst_dir="$TARGET_ROOT/$1"

  [[ -d "$src_dir" ]] || return 0
  mkdir -p "$dst_dir"

  local linked=0 updated=0 skipped=0
  for src in "$src_dir"/*.md; do
    [[ -e "$src" ]] || continue  # glob がマッチしない場合をスキップ
    local dst="$dst_dir/$(basename "$src")"

    if [[ -L "$dst" ]]; then
      # 既存シンボリックリンクの場合
      local existing
      existing="$(readlink "$dst")"
      if [[ "$existing" != "$CLAUDE_DIR"* ]]; then
        # 他リポジトリ（claude-dotfiles 等）を指している → スキップ
        skipped=$((skipped + 1))
        continue
      fi
      # すでに claude-config を指している → 更新
      ln -sf "$src" "$dst"
      updated=$((updated + 1))
    elif [[ -e "$dst" ]]; then
      # 通常ファイル（手動作成）→ 上書きしない
      skipped=$((skipped + 1))
    else
      # 未存在 → 新規リンク
      ln -sf "$src" "$dst"
      linked=$((linked + 1))
    fi
  done

  echo "  $1: 新規 ${linked} / 更新 ${updated} / スキップ ${skipped}（他設定優先）"
}

echo "[claude-config] ~/.claude/ を同期中..."
sync_dir "commands"
sync_dir "agents"
echo "[claude-config] 完了"
