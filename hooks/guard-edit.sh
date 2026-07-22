#!/usr/bin/env bash
# 自動生成: このファイルは claude-dotfiles から生成された配布物です。直接編集せず、正本(https://github.com/au-aii/claude-dotfiles)を編集して再生成してください。
# Claude Code PreToolUse guard(Edit|Write matcher)
#
# settings.json / settings.local.json への Edit/Write ツール経由の書き込みを block する。
# sandbox は Bash ツール経由の書き込みしか守らず、Edit/Write ツールは sandbox を経由しないため、
# このフックが settings.json 自己改変(sandbox/permissions/hooks の無効化等)に対する唯一の防御層になる。
# (背景: .steering/20260718-claude-code-security-baseline/design.md の2026-07-22追記、issue #70 フェーズ3b)
#
# stdin: Claude Code が渡す JSON（.tool_input.file_path に対象パス、.cwd に実行時cwd）
# exit 0 = 許可 / exit 2 = block（stderr のメッセージが Claude に返る）
#
# 既知の限界:
#   - Bash ツール経由の書き込み(echo/sed 等でのリダイレクト)はこのフックの対象外(matcher が Edit|Write のため)。
#     その経路は sandbox 有効時のみ OS レベルで保護される。sandbox はこのリポジトリでは常時無効に
#     したため(ADR-0011)、現状 Bash 経由の書き込みは素通りする。
#   - 保護対象ファイルがまだ存在しない場合(通常は起こらないが、新規作成攻撃)は inode 比較ができず
#     文字列比較にフォールバックするため、その一瞬だけ大文字小文字違いでのすり抜けが理論上残る。
#   - プロジェクト単位の `<project>/.claude/settings.json` は保護対象に含めていない。セッションの
#     権限を左右するので理屈の上では保護対象だが、`.claude/` を成果物として編集するリポジトリ
#     (claude-config 等)での正当な編集まで止めてしまうため、対象範囲の判断は保留にしている(#78)。

if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' "⚠️  guard-edit.sh: jq が見つかりません。設定ファイル保護が無効です。" >&2
  exit 0
fi

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$file_path" ] && exit 0

hook_cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$hook_cwd" ] && hook_cwd=$(pwd)

case "$file_path" in
  /*) ;;
  *) file_path="$hook_cwd/$file_path" ;;
esac

# inode比較(-ef)で判定する。文字列比較(realpath等)と違い、symlink・大文字小文字を
# 区別しないファイルシステム(macOS既定のAPFS)・`..`を含むパスのいずれも
# OSのstat()に委ねて正しく同一性判定できる。外部インタプリタ(python3等)にも依存しない。
#
# 保護対象パスは環境非依存に導出する(他マシン・他ユーザーへ配布できるようにするため。#78):
#   1. `$HOME/.claude/` … Claude Code が実際に読む user レベルの正規の場所。dotfiles を別の
#      ディレクトリに clone していても、symlink されていれば inode 比較で実体に一致する
#   2. このスクリプト自身の1つ上 … このフックが同梱されている repo の settings.json。symlink を
#      張る前(install 前)や、repo 内の実体を直接編集しにくる経路を塞ぐ。`$0` から導出するので
#      clone 先のパスがどこでも効く
repo_root="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)"
protected_files=(
  "$HOME/.claude/settings.json"
  "$HOME/.claude/settings.local.json"
)
if [ -n "$repo_root" ]; then
  protected_files+=(
    "$repo_root/settings.json"
    "$repo_root/settings.local.json"
  )
fi

for pf in "${protected_files[@]}"; do
  if [ -e "$pf" ]; then
    matched=0
    [ "$file_path" -ef "$pf" ] && matched=1
  else
    # 保護対象が未作成なら inode 比較できないため文字列比較にフォールバック。
    matched=0
    [ "$file_path" = "$pf" ] && matched=1
  fi
  if [ "$matched" = 1 ]; then
    printf '%s\n' "❌ settings.json/settings.local.json への Edit/Write は禁止。sandbox/permissions/hooks の自己改変を防ぐため、変更は人間が直接エディタで行ってください。(issue #70 フェーズ3b)" >&2
    exit 2
  fi
done

exit 0
