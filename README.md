# claude-config

Claude Code を使ったプロジェクト開発のためのテンプレート。

## 設計思想

### ドキュメントを2層に分ける

| 層       | 場所                        | 性質                                               |
| -------- | --------------------------- | -------------------------------------------------- |
| 永続     | `docs/`                     | プロジェクトの基本設計。方針が変わるまで更新しない |
| 作業単位 | `.steering/YYYYMMDD-title/` | 今回の作業の要求・設計・タスク。作業ごとに新規作成 |

### 役割で分ける

- **エージェント** (`.claude/agents/`) — Designer / Dev / Doc / Reviewer など局面別に呼び分け
- **スキル** (`.claude/skills/`) — 設計知識を分離して CLAUDE.md を肥大化させない
- **コマンド** (`.claude/commands/`) — `/setup-prd` 等で頻出操作を呼び出す（一覧は [`prompt.md`](prompt.md)）

## セットアップ

```bash
git clone https://github.com/au-aii/claude-config my-project
cd my-project && rm -rf .git && git init
```

VS Code で「Reopen in Container」すると `bootstrap.sh` が走り MCP 関連がセットアップされる。

### スキルをグローバルに共有する（オプション）

`.claude/commands/` のスキルをすべてのプロジェクトで使えるようにするには、`~/.claude/commands/` にシンボリックリンクを作成する。

```bash
mkdir -p ~/.claude/commands
for f in /path/to/claude-config/.claude/commands/*.md; do
  ln -sf "$f" ~/.claude/commands/
done
```

以降は `claude-config` リポジトリ側を更新するだけで全プロジェクトに自動反映される。新しいスキルを追加した際は同じコマンドを再実行する。

このテンプレートは **言語非依存**。使う言語のランタイム・パッケージ管理・リンターはクローン後にプロジェクトに合わせて追加する。

## 開発フロー

1. `docs/ideas/` にアイデアをメモ
2. `/setup-*` で `docs/` の永続ドキュメントを整備
3. `/add-feature <Issue番号> <機能名>` でブランチ・ステアリング生成〜実装まで自動実行
4. `/ship` でPR作成〜自動レビュー〜修正〜マージまで一気通貫で実行

## MCP

`.mcp.json` で `context7` / `playwright` / `chrome-devtools` を有効化している。
`${VAR}` 構文を使っているので、起動前にシェルで環境変数を export しておく：

```bash
export UPSTASH_REDIS_REST_URL="https://..."
export UPSTASH_REDIS_REST_TOKEN="..."
```

## 前提

Git / Docker / VS Code + Dev Containers 拡張
