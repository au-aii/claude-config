# Getting Started（Plugin方式）

claude-config の `dev` plugin を Claude Code の Plugin 機構で導入する方法。背景と判断理由は [ADR-0001](adr/0001-plugin-based-distribution.md) を参照。

## 前提

- `claude --version` で Claude Code CLI がインストール済みであること

## Step 1 — マーケットプレイスを追加する

GitHub から直接追加する:

```
/plugin marketplace add au-aii/claude-config
```

このリポジトリをクローン済みなら、リポジトリルートをパス指定しても追加できる:

```
/plugin marketplace add /path/to/claude-config
```

`claude-config-marketplace` として登録される。

## Step 2 — plugin をインストールする

```
/plugin install dev@claude-config-marketplace
/reload-plugins
```

## Step 3 — 導入内容を確認する

```
claude plugin details dev@claude-config-marketplace
```

`dev` plugin の agents / commands / skills が表示されれば成功。

## よくあるトラブル

### `/plugin marketplace add` でエラーになる

`claude plugin validate .`（リポジトリルート）で JSON 構文エラーの詳細を確認する。

### steering skill でテンプレートが読み込めない

`${CLAUDE_PLUGIN_ROOT}` の展開に失敗している可能性がある。`echo $CLAUDE_PLUGIN_ROOT` で実際の展開結果を確認する。
