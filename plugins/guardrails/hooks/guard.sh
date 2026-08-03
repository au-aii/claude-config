#!/usr/bin/env bash
# 自動生成: このファイルは claude-dotfiles から生成された配布物です。直接編集せず、正本(https://github.com/au-aii/claude-dotfiles)を編集して再生成してください。
# Claude Code PreToolUse guard (Bash matcher)
#
# 「致命的＝戻せない / 外部を汚す」操作だけを block する二次防御。
# 一次防御は permission mode と人間レビュー。誤検知で日常操作を止めない方針。
#
# stdin: Claude Code が渡す JSON（.tool_input.command に実行予定コマンド）
# exit 0 = 許可 / exit 2 = block（stderr のメッセージが Claude に返る）
#
# 既知の限界:
#   - 判定対象の repo は「実際に操作される作業ディレクトリ」(eff_cwd)。input.cwd を既定とし、
#     コマンドが `cd <path> &&|;` で始まる場合はその移動先を採用する（cross-repo/worktree 対策）。
#     ただし複数 cd・サブシェル・`git -C <path>`/`gh -R`/`--git-dir` は追従せず input.cwd 基準になる。
#   - 深い絶対パス（~/foo, $HOME/foo, ホームディレクトリ配下の実パス等）の rm 誤削除は止めない。
#   - テスト用に BRANCH_OVERRIDE 環境変数で現在ブランチ判定を差し替えられる。
#   - セッション×repo ごとにブランチをロックし、別セッションのブランチ切替による誤 commit を block する（4 参照）。
#   - レビュー証跡ゲート（`gh pr create` の block）は撤去した（5 参照。#171・ADR-0023）。
#   - block 発火を1行 JSON の計測ログに残す（$HOME/.claude/state/guard-block.log、CLAUDE_GUARD_LOG で差替可）。
#     発火数を後で集計し #56/#61 をデータで判断するため。挙動は不変・書込失敗はフェイルセーフ（#82）。
#   - `--body`/`-m` 等、既知の「値として一度だけ消費する」フラグ直後のヒアドキュメント本文だけ
#     を危険判定の走査対象から除外する（cmd_scan。allowlist 方式。詳細は cmd_scan 定義部の
#     コメント参照）。PR/Issue 本文・commit メッセージの定番イディオムに git 語彙が説明文として
#     書かれているだけで、実行されないテキストを実コマンドと誤認していた3パターンを修正済み
#     （Issue #61）: (a) --body 本文中の git 語彙を連鎖コマンドと誤認、(b) `checkout main -- <file>`
#     （ファイル復元）を main への切替と誤認、(c) `push --delete <branch>`（他ブランチ削除）を
#     main への push と誤認。除外条件は当初「cat 宛なら安全」「変数代入でなければ安全」という
#     denylist だったが、3回のレビューでいずれもバイパス（ファイル書き出し→実行、裸の展開、
#     eval/bash -c、配列代入等）が見つかったため、既知の安全なフラグだけを許可する allowlist に
#     設計を反転した。既知の限界: 難読化（base64 等）は引き続き検出できない。
#
# 新しい誤検知/バイパスへの対応方針の判定手順（Issue #61 の4ラウンドに及ぶレビューを経て確立。
# 「難読化かどうか」は判定軸にならない――今回見つかったバイパス（eval・bash -c・配列代入等）は
# いずれも Claude 自身が普通に書きうる書き方で、難読化の有無では一切区別できなかった）:
#   1. この危険操作は、文字列マッチに依らない別の層（native git hook・permissions.deny・OS 層等）
#      で既に構造的にブロックされているか？
#      - Yes（例: main への force push は hooks/git/pre-push が実際の ref を見て、コマンドの書き方
#        に一切依存せず block する）→ guard.sh 側は best-effort 扱いでよい。見つかったバイパスは
#        「既知の限界」としてこのヘッダーに1行足して記録し、それ以上レビューを重ねて追撃しない
#      - No（例: git clean -fdx・rm -rf はここが唯一の防波堤）→ 実際に直す。true positive/false
#        negative を実機で潰すところまで厳密にやる
#   2. 直す場合、修正が「既存の正規表現の境界を1箇所調整する」で済むか、それとも「新しい状態機械/
#      パーサ相当のロジックを追加する」規模になるか？
#      - 後者に踏み込む場合は、着手前に一度ユーザーに確認する（守備範囲を恒久的に広げる設計判断
#        であり、1レビューサイクルの中で自己完結して決めてよい話ではないため）

# jq 不在時はフェイルオープンするが、ガードが無効である旨を必ず可視化する。
if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' "⚠️  guard.sh: jq が見つかりません。Bash ガードが無効です。" >&2
  exit 0
fi

# stdin は一度しか読めないので、全体を変数に取ってから各フィールドを抽出する。
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)

# 実際に操作される作業ディレクトリ(eff_cwd)を推定する。既定はシェルの cwd（input.cwd）。
# コマンドが `cd <path> && …` で始まり、<path> が実在する git repo のときだけ移動先を採用する。
# cross-repo / worktree 運用（シェルは repoA、コマンドは `cd repoB && git ...`）で
# ブランチ判定を「実際に操作される repo」に対して行うため（1/4 の cross-repo 盲点対策）。
# 安全側の設計（すり抜け防止 > 追従性）:
#   - 区切りは `&&` 限定。cd 成功時のみ後続が走る＝後続が走るなら cd 成功＝path が実 cwd。
#     `;` / `||` / 区切り無しは cd 失敗時に元 cwd で後続が走り得るため採用せず input.cwd で判定する。
#   - 後続に別の cd が連鎖する多段 cd は曖昧なので採用しない（input.cwd で判定）。
#   - <path> が実在する git repo でなければ採用しない（存在しない path 経由のすり抜けを防ぐ）。
hook_cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$hook_cwd" ] && hook_cwd=$(pwd)
cd_target=""
# sed はデフォルトで行単位に `^`/`$` を評価するため、1行目に限定しないと $cmd が複数行
# （ヒアドキュメント等）のとき本文中の別の行（例: PR 本文の説明文にある `cd <path> && ...`）を
# 「コマンドの先頭 cd」と誤認する（Issue #61 の調査で発覚。eff_cwd が無関係なリポジトリに
# すり替わり、ブランチ判定がそちらを基準に行われてしまう）。
extracted=$(printf '%s' "$cmd" | sed -nE "1s/^[[:space:]]*cd[[:space:]]+(--[[:space:]]+)?('[^']+'|\"[^\"]+\"|[^[:space:];&|]+)[[:space:]]*&&.*/\2/p")
if [ -n "$extracted" ] && ! printf '%s' "${cmd#*&&}" | grep -Eq '(^|&&|;|\|)[[:space:]]*cd[[:space:]]'; then
  extracted=${extracted#\'}; extracted=${extracted%\'}
  extracted=${extracted#\"}; extracted=${extracted%\"}
  case "$extracted" in
    "~")   extracted="$HOME" ;;
    "~/"*) extracted="$HOME/${extracted#\~/}" ;;
  esac
  # 相対パスは input.cwd(実 cwd)基準で解決する（guard.sh プロセスの cwd 基準にしない）。
  # 相対 cd の解決を実際の bash 実行と一致させ、プロセス cwd 依存の盲点を塞ぐ。
  case "$extracted" in
    /*) ;;
    *)  extracted="$hook_cwd/$extracted" ;;
  esac
  if git -C "$extracted" rev-parse --git-dir >/dev/null 2>&1; then
    cd_target="$extracted"
  fi
fi
eff_cwd="${cd_target:-$hook_cwd}"

branch="${BRANCH_OVERRIDE:-$(git -C "$eff_cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")}"

block() {
  # 計測(#82): 発火を追記ログに残し、後で #56(D の要否)/#61(誤検知) をデータで判断できるようにする。
  # block の挙動(stderr → exit 2)は不変。ログ処理の失敗は握りつぶす（計測が安全機構の動作を左右しない＝
  # フェイルセーフ）。jq は block() 到達時点で必ず存在する（冒頭で不在ならフェイルオープン済）。
  local logfile="${CLAUDE_GUARD_LOG:-$HOME/.claude/state/guard-block.log}"
  {
    mkdir -p "$(dirname "$logfile")" 2>/dev/null &&
      jq -cn --arg ts "$(date +%Y-%m-%dT%H:%M:%S%z)" \
        --arg branch "$branch" --arg cwd "$eff_cwd" \
        --arg reason "$1" --arg cmd "$cmd" \
        '{ts:$ts,branch:$branch,cwd:$cwd,reason:$reason,cmd:$cmd}' >>"$logfile"
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

has_git_subcmd() {
  # git とサブコマンドの間にオプション（-q 等）が挟まっても拾う。
  # cmd ではなく cmd_scan（ヒアドキュメント本文除去済み）を走査する。
  printf '%s' "$cmd_scan" | grep -Eq "(^|[^[:alnum:]_])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+$1([[:space:];&|]|\$)"
}

# 1x) commit/push の危険判定ヘルパー。`git push <remote> --delete <branch>`（または `-d`、
#     コロン構文 `git push <remote> :<branch>`）はリモート追跡ブランチの削除であって「main へ
#     commit を押し込む」操作ではないため、削除対象が main/master 自体でない限り危険側から
#     除外する（Issue #61: リモートブランチ削除の誤 block）。
#     main/master の有無は push 呼び出し区間ごとに判定する（cmd_scan 全体で見ると、たとえば
#     `git switch main && git push origin --delete old-branch` のように削除対象と無関係な
#     箇所の "main" を拾って誤って危険判定してしまうため。3b の clean_segs と同じ考え方）。
#     既知の限界: 削除対象の判定は素朴なテキスト判定。難読化した削除対象（base64 等）は検出
#     できない（本ファイル全体の既知の限界と同種。難読化耐性は目標にしていない）。
has_dangerous_commit_or_push() {
  has_git_subcmd 'commit' && return 0
  has_git_subcmd 'push' || return 1
  push_segs=$(printf '%s' "$cmd_scan" | grep -oE '(^|[^[:alnum:]_])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+push[^;&|]*')
  dangerous=0
  while IFS= read -r seg; do
    [ -z "$seg" ] && continue
    if printf '%s' "$seg" | grep -Eq -- '(--delete|[[:space:]]-d([[:space:]]|$)|[[:space:]]:[^[:space:]])'; then
      printf '%s' "$seg" | grep -Eq '(^|[^[:alnum:]_-])(main|master)([^[:alnum:]_-]|$)' && dangerous=1
    else
      dangerous=1
    fi
  done <<EOF
$push_segs
EOF
  [ "$dangerous" = 1 ]
}

# 1) main/master への直接 commit / push
if has_dangerous_commit_or_push; then
  case "$branch" in
    main|master)
      block "main/master への直接 commit/push は禁止。ブランチを切ってください: git checkout -b <branch>（Issue駆動なら gh issue develop <n> --checkout）"
      ;;
  esac
fi

# 1b) feature ブランチ上でも「main/master へ切り替えてから commit/push」の連鎖は止める。
#     （ブランチ判定がコマンド実行前の値になる穴を塞ぐ）
#     tail を `[[:space:]]*(&&|;|\||$)` にして「main/master の直後がコマンド区切り」に限定
#     している。`git checkout main -- <file>`（main からのファイル復元。HEAD は動かない）を
#     「main へ切替」と誤認していた分を除外する（Issue #61）。
if printf '%s' "$cmd_scan" | grep -Eq 'git[[:space:]]+(checkout|switch)([[:space:]]+-[^[:space:]]+)*[[:space:]]+(main|master)[[:space:]]*(&&|;|\||$)' \
   && has_dangerous_commit_or_push; then
  block "main/master へ切り替えてから commit/push する連鎖を検出。ブランチを分けてください。"
fi

# 2) force push（履歴破壊）は、ここ（Bash 文字列の正規表現）では判定しない。
#    シェルの字句解析を正規表現で再実装する形になり、クォート・エスケープ・$'...' 等で
#    必ずすり抜けが残る（Issue #49 で 3 種のバイパスを実証）。airtight にはできない。
#
#    履歴破壊の本命ガードは git ネイティブ層 hooks/git/pre-push（ADR-0005 / #13）。
#    pre-push は git が解決した remote ref を構造化データで受け取り、origin の main/master への
#    push（force かどうかに関係なく）を block する。コマンドの書き方に一切依存しないので確実。
#    feature ブランチへの force push は rebase 後などの正当な運用として通す（#49 の方針）。
#    → force の判定はここではなく pre-push に一本化した。

# 3) 危険な rm -rf（ルート / ホーム / ワイルドカード / カレント直）のみ。
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

# 3b) git clean の実削除（dry-run 以外）。
#     rm と違い「範囲を限定すれば安全」が成立しないので、3) のような対象の絞り込みをしない:
#       - 消す対象は定義上 git が追跡していないファイル＝ git からは原理的に復元できない
#       - 削除対象がコマンドに書かれず計算される。`rm -rf ./build` は何が死ぬか読めるが
#         `git clean -fdx` は読めない。cwd/パスの誤解決がそのまま全損に化ける
#     `-n`/`--dry-run` は読み取りのみなので通す。requireForce=false 環境では `-f` 無しでも
#     消えるため、-f の有無ではなく dry-run の有無で判定する。
#     worktree/ブランチの掃除は git worktree remove / git branch -d の担当でここでは止めない
#     （git clean はブランチを1本も消さない。「整理して」で撃たれる誤用こそが事故の実例）。
#     検知に has_git_subcmd を使わない: あれは `-C <path>` のように引数を取る global option を
#     想定しておらず `git -C /x clean -fdx` を取り逃がす。ヘルパー側を直すと commit/push ガードにも
#     波及し、あちらは eff_cwd のブランチで判定するため「別 repo を -C で操作」した時に誤 block する
#     （ヘッダーの既知の限界を参照）。clean は repo・ブランチに関係なく一律 block なのでこの副作用が
#     無く、ここだけ引数つき global option を許容する検知にする。
#     dry-run 判定は $cmd 全体ではなく「マッチした clean 呼び出し区間」に対して行う。$cmd 全体に対し
#     grep すると `git log -n 5 && git clean -fdx` のような、無関係な -n 系トークンを含む複合コマンド
#     で dry-run と誤判定し実削除がすり抜ける（「まず履歴を見てから片付ける」という自然な言い回しで
#     踏む。意図的な回避技法である必要すらない）。
#     クォートは軽く剥がしてから判定する（`git "clean" -fdx` 等の単純な回避を塞ぐ）。ただし $IFS 置換・
#     バックスラッシュ改行・スペースを含むパスを `-C` に渡す形は正規表現でシェルを再実装しても根絶
#     できない（2) の force-push 検知が同じ理由で native hook に判定を一本化しているのと同種の限界）。
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

# 4) セッション×repo 単位のブランチロック（並行セッションのブランチ切替による誤 commit を防ぐ）
#    - git switch/checkout（意図的なブランチ移動）→ このセッションのロックを解除し、移動先を受け入れる
#    - git commit → 現在ブランチとロックを照合。ロック無し/一致=通す(＋記録)、不一致=block
#    session_id が無い／git 外なら作動しない（フェイルオープン）。
#    限界: `git checkout <file>`（ファイル復元）もロック解除に含む（switch 主体運用のため許容）。
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
if [ -n "$session_id" ] && has_git_subcmd '(commit|checkout|switch)'; then
  repo=$(git -C "$eff_cwd" rev-parse --show-toplevel 2>/dev/null || echo "")
  cur="${BRANCH_OVERRIDE:-$(git -C "$eff_cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")}"
  if [ -n "$repo" ] && [ -n "$cur" ]; then
    lock_dir="$HOME/.claude/state/branch-guard"
    mkdir -p "$lock_dir" 2>/dev/null
    key=$(printf '%s' "${session_id}:${repo}" | shasum 2>/dev/null | awk '{print $1}')
    lock_file="${lock_dir}/${key}"

    # 意図的なブランチ移動はロックを解除（次の commit で移動先を受け入れる）。
    # 複合コマンド（例: `git switch b && git commit`）は elif で commit 側を skip する。
    # このhookはコマンド実行"前"に発火するため、$cur は複合コマンド内の switch がまだ
    # 反映されていない「実行前」のブランチであり、ここで書き込むと次の単独 commit を誤検知させる。
    if has_git_subcmd '(checkout|switch)'; then
      rm -f "$lock_file" 2>/dev/null
    # commit 時に現ブランチとロックを照合
    elif has_git_subcmd 'commit'; then
      if [ -f "$lock_file" ]; then
        locked=$(cat "$lock_file" 2>/dev/null)
        if [ -n "$locked" ] && [ "$locked" != "$cur" ]; then
          block "ブランチ不一致: このセッションは直近 '${locked}' で作業していたが現在は '${cur}'。別セッションが裏でブランチを切替えた可能性があります。意図通りなら 'git switch ${cur}' で移動し直してから再実行してください。(repo: ${repo})"
        fi
      fi
      printf '%s' "$cur" > "$lock_file" 2>/dev/null
    fi
  fi
fi

# 5) レビュー証跡ゲートは撤去した（#171・ADR-0023）。
#    レビュー完走マーカーの無い `gh pr create` を block していたが、実測で block 82件中42件(51%)を
#    占める最大要因である一方、マーカー自体が偽造検知不能で「うっかりレビューを飛ばす」しか
#    防げていなかった。原則6（レビュー先行）は維持し、強制手段だけを運用へ戻す。

exit 0
