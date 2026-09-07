#!/usr/bin/env bash
# 自動生成: 非公開の正本から生成された配布物です。直接編集しても次回の生成で上書きされます。修正は Issue でお知らせください。
# Claude Code ConfigChange hook — 設定ファイル変更の監査ログ。
#
# settings.json 等の変更を検知して記録する「事後検知」の保険。ブロックはしない。
# 理由: 公式ドキュメントに ConfigChange が「書き込み前/後どちらで発火するか」
# 「Claude 自身の変更と人間が外部エディタで行った変更を区別できるか」の記載が無く、
# 誤って人間の正当な編集まで block してしまうリスクを避けるため、監査ログ専任とした。
# 実効的な防止(block)は hooks/guard-edit.sh(PreToolUse, Edit|Write matcher)側が担う。
# (背景: .steering/20260718-claude-code-security-baseline/design.md の2026-07-22追記、issue #70 フェーズ3b)
#
# stdin: Claude Code が渡す JSON。ConfigChange 固有フィールドは公式未文書化のため、
#        フィールド名を推測せず生の入力をそのまま記録する。
# 常に exit 0(非block)。

input=$(cat)
logfile="${CLAUDE_CONFIGCHANGE_LOG:-$HOME/.claude/state/config-change.log}"

{
  mkdir -p "$(dirname "$logfile")" 2>/dev/null
  if command -v jq >/dev/null 2>&1; then
    jq -cn --arg ts "$(date +%Y-%m-%dT%H:%M:%S%z)" --arg input "$input" \
      '{ts:$ts,input:$input}' >>"$logfile" 2>/dev/null
  else
    # jq 非搭載時は $input を1行のログ行に埋め込むため、改行を除去してから書く
    # (改行を残すと1イベントが複数のログ行に見え、ログ行境界を偽装されうる)。
    input_oneline=$(printf '%s' "$input" | tr '\n' ' ')
    printf '%s %s\n' "$(date +%Y-%m-%dT%H:%M:%S%z)" "$input_oneline" >>"$logfile"
  fi
} 2>/dev/null || true

exit 0
