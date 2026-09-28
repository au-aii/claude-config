# 自動生成: 非公開の正本から生成された配布物です。直接編集しても次回の生成で上書きされます。修正は Issue でお知らせください。
#!/usr/bin/env bash
# Claude Code PreToolUse guard (Bash matcher)
#
# 危険な rm と実削除を伴う git clean を block する。sandbox 無効化要求も拒否する。
#
# stdin: Claude Code が渡す JSON（.tool_input.command に実行予定コマンド）
# exit 0 = 許可 / exit 2 = block（stderr のメッセージが Claude に返る）
#
# 危険判定は Bash コマンド文字列のパターン照合であり、難読化された削除操作は検出できない。
# block 発火を1行 JSON の計測ログに残す（CLAUDE_GUARD_LOG で差替可）。書込失敗はフェイルセーフ。
#

# jq 不在時はフェイルオープンするが、ガードが無効である旨を必ず可視化する。
if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' "⚠️  guard.sh: jq が見つかりません。Bash ガードが無効です。" >&2
  exit 0
fi

# stdin は一度しか読めないので、全体を変数に取ってから各フィールドを抽出する。
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)

hook_cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$hook_cwd" ] && hook_cwd=$(pwd)

block() {
  # 計測(#82): 発火を追記ログに残し、後で #56(D の要否)/#61(誤検知) をデータで判断できるようにする。
  # src には発火した guard.sh 自身のパス($0)を入れる。install.sh の配線と配布 plugin の
  # hooks.json が同時に有効なマシンでは、どちらが止めたかログからしか区別できないため(#196)。
  # block の挙動(stderr → exit 2)は不変。ログ処理の失敗は握りつぶす（計測が安全機構の動作を左右しない＝
  # フェイルセーフ）。jq は block() 到達時点で必ず存在する（冒頭で不在ならフェイルオープン済）。
  local logfile="${CLAUDE_GUARD_LOG:-$HOME/.claude/state/guard-block.log}"
  {
    mkdir -p "$(dirname "$logfile")" 2>/dev/null &&
      jq -cn --arg ts "$(date +%Y-%m-%dT%H:%M:%S%z)" \
        --arg cwd "$hook_cwd" \
        --arg reason "$1" --arg cmd "$cmd" --arg src "$0" \
        '{ts:$ts,cwd:$cwd,reason:$reason,cmd:$cmd,src:$src}' >>"$logfile"
  } 2>/dev/null || true
  printf '%s\n' "❌ $1" >&2
  exit 2
}

# 0) サンドボックス無効化(dangerouslyDisableSandbox)は常に禁止。
#    安全機構を外して通すのは本末転倒。AI に絶対に外させない一次ガード。
if [ "$(printf '%s' "$input" | jq -r '.tool_input.dangerouslyDisableSandbox // empty' 2>/dev/null)" = "true" ]; then
  block "サンドボックス無効化(dangerouslyDisableSandbox)は禁止。安全機構は外さず、原因を報告して人間に委ねること。"
fi

# コマンドが空なら以降のコマンド系チェックは不要
[ -z "$cmd" ] && exit 0

# 危険判定の走査対象（cmd_scan）: `--body "$(cat <<EOF ... EOF)"` 等、既知の「本文を値として
# 渡すだけの特定フラグ」直後にあるヒアドキュメント本文だけを除去した版（PR/Issue 本文・commit
# メッセージの定番イディオムに git 語彙が説明文として書かれているだけで、実行されないテキスト
# を「実行される git コマンド」と誤認して block していた。Issue #61）。
#   「cat 宛なら安全」（1回目）「変数代入でなければ安全」（2回目）という denylist 的な判定は、
#   3回のレビューでいずれも実機バイパスが見つかった（`cat <<EOF > script.sh && bash script.sh`・
#   裸の `$(cat <<EOF...)`・`eval "$(cat <<EOF...)"`・`bash -c "$(cat <<EOF...)"`・配列代入
#   `arr+=("$(cat <<EOF...)")`・`printf -v X "%s" "$(cat <<EOF...)"` 等、直接/間接に実行しうる
#   経路は bash の構文だけ列挙しても後から後から出てくる）。「危険な消費者を列挙して除外する」
#   denylist は原理的に終わらないいたちごっこになると判明したため、方針を反転し、
#   「安全と確認済みの消費者だけを allowlist で許可する」方式にした:
#   直前が `--body`/`-b`/`--title`/`-t`/`-m`/`-F`/`--file`（本文/コミットメッセージを値として
#   一度だけ消費し、それ自体を再実行しないと分かっているフラグ）のいずれかで終わっている場合
#   だけ除去する。新しい安全な消費先を追加したくなったら、この allowlist に明示的に足すこと
#   （denylist に戻さない）。
cmd_scan=$(printf '%s\n' "$cmd" | awk '
  BEGIN { in_body = 0; delim = ""; strip_tabs = 0 }
  {
    line = $0
    if (in_body) {
      check = line
      # `<<-` のときだけ終端行の先頭タブを許容する（bash の実際の仕様と一致させる。
      # 無条件に剥がすと、素の `<<EOF` でタブ字下げの行を誤って終端と判定してしまう）。
      if (strip_tabs) { gsub(/^\t+/, "", check) }
      if (check == delim) { in_body = 0 }
      next
    }
    if (match(line, "\042[\044]\\(cat[ \t]+<<(-)?[ \t]*[\047\042]?[A-Za-z_][A-Za-z0-9_]*[\047\042]?")) {
      prefix = substr(line, 1, RSTART - 1)
      if (prefix ~ /(^|[ \t])(--body|-b|--title|-t|-m|-F|--file)[ \t]+$/) {
        seg = substr(line, RSTART, RLENGTH)
        d = seg
        strip_tabs = (seg ~ /<<-/) ? 1 : 0
        sub("^.*<<-?[ \t]*", "", d)
        gsub("[\047\042]", "", d)
        delim = d
        in_body = 1
      }
    }
    print line
  }
')

# 1) 危険な rm -rf（ルート / ホーム / ワイルドカード / カレント直）のみ。
#    rm -rf ./path や node_modules、深いパス（~/foo, $HOME/foo）は通す。
#    cmd ではなく cmd_scan（allowlist 済みフラグ直後の cat ヒアドキュメント本文を除去済み）から
#    判定する。3b(git clean) と揃え、`--body`/`-m` の本文に説明として "rm -rf ~/..." と書いた
#    だけの PR/Issue 本文・コミットメッセージを実コマンドと誤読して block する穴を塞ぐ（Issue #99。
#    #61 で 3b・レビューゲート等を cmd_scan に向けたときの取りこぼし）。
if printf '%s' "$cmd_scan" | grep -Eq '(^|[^[:alnum:]_])rm[[:space:]]+(-[[:alnum:]]*[rR][[:alnum:]]*[fF]|-[[:alnum:]]*[fF][[:alnum:]]*[rR]|-[rR][[:space:]]+-[fF]|-[fF][[:space:]]+-[rR])'; then
  # ホーム系: ~ / $HOME / ${HOME}（単体または末尾スラッシュ）。深いパスは除外。
  if printf '%s' "$cmd_scan" | grep -Eq "[[:space:]\"']+(~|\\\$HOME|\\\$\\{HOME\\})/?([[:space:]\"';&|]|\$)" \
     || printf '%s' "$cmd_scan" | grep -Eq "[[:space:]\"']+(/|\\*|/\\*|\\.|\\./)([[:space:]\"';&|]|\$)"; then
    block "危険な rm -rf（ルート/ホーム/ワイルドカード対象）を検出。範囲を限定するか、人間に確認してください。"
  fi
fi

# 2) git clean の実削除（dry-run 以外）。
#     rm と違い「範囲を限定すれば安全」が成立しないので、1) のような対象の絞り込みをしない:
#       - 消す対象は定義上 git が追跡していないファイル＝ git からは原理的に復元できない
#       - 削除対象がコマンドに書かれず計算される。`rm -rf ./build` は何が死ぬか読めるが
#         `git clean -fdx` は読めない。cwd/パスの誤解決がそのまま全損に化ける
#     `-n`/`--dry-run` は読み取りのみなので通す。requireForce=false 環境では `-f` 無しでも
#     消えるため、-f の有無ではなく dry-run の有無で判定する。
#     worktree/ブランチの掃除は git worktree remove / git branch -d の担当でここでは止めない
#     （git clean はブランチを1本も消さない。「整理して」で撃たれる誤用こそが事故の実例）。
#     repo・ブランチに関係なく一律判定する。`-C <path>` などの git global option にも対応する。
#     dry-run 判定は $cmd 全体ではなく「マッチした clean 呼び出し区間」に対して行う。$cmd 全体に対し
#     grep すると `git log -n 5 && git clean -fdx` のような、無関係な -n 系トークンを含む複合コマンド
#     で dry-run と誤判定し実削除がすり抜ける（「まず履歴を見てから片付ける」という自然な言い回しで
#     踏む。意図的な回避技法である必要すらない）。
#     クォートは軽く剥がしてから判定する（`git "clean" -fdx` 等の単純な回避を塞ぐ）。ただし $IFS 置換・
#     バックスラッシュ改行・スペースを含むパスを `-C` に渡す形は正規表現でシェルを再実装しても根絶
#     できない。
#     クォート除去は隣接トークンを結合しうるトレードオフを許容している（例: `echo "git" clean -fdx`
#     という無害なコマンドが誤って block される）。over-block 方向にのみ作用し data loss には繋がら
#     ないため許容する。なお本ガードはコマンド文字列の部分一致で判定するため、`git clean -fdx` という
#     フレーズを含むだけのコミットメッセージ等でも発火する（既知の限界。2026-07-31 に実際に踏んだ:
#     Issue 本文の block ログ内訳表に当該フレーズが説明文として含まれ、`cat > file <<EOF` 経由だった
#     ため --body の allowlist から外れて block された。#171 の起票時）。
#     cmd ではなく cmd_scan（cat ヒアドキュメント本文除去済み、Issue #61）から作る。
cmd_nq=$(printf '%s' "$cmd_scan" | tr -d '"'\''')
if printf '%s' "$cmd_nq" | grep -Eq '(^|[^[:alnum:]_])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-][^[:space:]]*)?)*[[:space:]]+clean([[:space:];&|]|$)'; then
  clean_segs=$(printf '%s' "$cmd_nq" | grep -oE 'git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-][^[:space:]]*)?)*[[:space:]]+clean[^;&|]*')
  is_dry_run=1
  while IFS= read -r seg; do
    # dry-run: --dry-run、または短オプション群に n を含むもの（-n / -nfd / -fdn）。
    # 長オプション（--quiet 等）は `-` の次が英数字でないため誤マッチしない。
    if ! printf '%s' "$seg" | grep -Eq '(^|[[:space:]])(--dry-run|-[[:alnum:]]*n[[:alnum:]]*)([[:space:]]|$)'; then
      is_dry_run=0
    fi
  done <<EOF
$clean_segs
EOF
  if [ "$is_dry_run" != 1 ]; then
    block "git clean（実削除）は禁止。消えるのは git が追跡していないファイルで、git では復元できません。確認は git clean -n（dry-run）で行い、実削除は人間が実行してください。worktree/ブランチの掃除なら git worktree remove / git branch -d を使ってください。"
  fi
fi

exit 0
