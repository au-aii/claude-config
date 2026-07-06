# Getting Started（Plugin方式）

claude-config を Claude Code の公式 Plugin 機構で導入する方法。従来の clone-and-detach / symlink 方式（[README](../README.md)参照）と並行運用中。背景と判断理由は [ADR-0001](adr/0001-plugin-based-distribution.md) を参照。

## 前提

- `claude --version` で Claude Code CLI がインストール済みであること
- GitHub へのpushは不要。ローカルパスから直接導入できる

## Step 1 — マーケットプレイスを追加する

```bash
/plugin marketplace add /path/to/claude-config/plugins
```

`claude-config-marketplace` として登録される。

## Step 2 — plugin をインストールする

```bash
/plugin install claude-config@claude-config-marketplace
/reload-plugins
```

## Step 3 — 導入内容を確認する

```bash
claude plugin details claude-config@claude-config-marketplace
```

Skills(commands+skills統合) 19・Agents 10・Hooks 2・MCP servers 3 が表示されれば成功。

## Step 4 — MCP の環境変数を設定する（`context7` を使う場合のみ）

```bash
export UPSTASH_REDIS_REST_URL="https://..."
export UPSTASH_REDIS_REST_TOKEN="..."
```

使わない場合はそのままで問題ない（定義は読み込まれるが接続時にのみエラーになる）。

## 注意（移行期間中の重複について）

`scripts/sync.sh`（`.githooks/post-merge`経由）で `~/.claude/{agents,commands}/` にすでに symlink している場合、plugin版と重複してロードされる可能性がある。両方式を同時に使うと同名の agent/command が二重に表示されることがあるため、**どちらか一方の運用に統一すること**を推奨する。

## よくあるトラブル

### `/plugin marketplace add` でエラーになる

`claude plugin validate ./plugins` でJSON構文エラーの詳細を確認する。

### steering skill でテンプレートが読み込めない

`${CLAUDE_PLUGIN_ROOT}` の展開に失敗している可能性がある。`echo $CLAUDE_PLUGIN_ROOT` で実際の展開結果を確認する。

### Context7 MCP のエラーが出る

`UPSTASH_REDIS_REST_URL` / `UPSTASH_REDIS_REST_TOKEN` が未設定。使わないなら無視して問題ない。
