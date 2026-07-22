# claude-config

Claude Code の開発ワークフロー（SDD: PRD〜steering〜実装〜レビュー）を配布する **`dev` plugin** と、汎用ユーティリティの **`common` plugin** の公開マーケットプレイス。

> **`plugins/` と `core/` 配下は生成物です。** その正本は private リポジトリ `claude-dotfiles` の `plugins/`・`core/` にあり、publish パイプラインで **一方向に生成**された配布物です（各ファイル先頭に自動生成ヘッダーがあります）。**`plugins/`・`core/` を直接編集しないでください**（編集は正本側で行い再生成します）。
>
> それ以外のファイル（この README・ONBOARDING・prompt.md・`docs/`・`scripts/`・Dev Container 設定・`.mcp.json` など）は**本 repo が正本**であり、直接編集してかまいません。経緯は Issue #19 を参照。

## core/principles.md（行動原則）

`core/principles.md` は、ツール非依存の行動原則の正本（[claude-dotfiles/core/principles.md](https://github.com/au-aii/claude-dotfiles/blob/main/core/principles.md)）から生成された配布物。plugin ではないため `/plugin install` の対象外——導入する場合は clone したこのリポジトリを参照する形で、自分の `CLAUDE.md` に以下のように import する:

```markdown
@core/principles.md
```

（相対パスはこのリポジトリを clone したディレクトリ基準。詳細は `core/principles.md` 冒頭のコメントを参照）

## 何が入っているか

`dev` plugin（`plugins/dev/`）が提供するもの:

- **エージェント** — Designer / Dev / Doc / Reviewer など局面別に呼び分け
- **スキル** — 設計知識（アーキテクチャ設計・機能設計・PRD・用語集・リポジトリ構造・開発ガイドライン・steering）を分離して CLAUDE.md を肥大化させない
- **コマンド** — `/goal`・`/add-feature`・`/asdd`・`/design`・`/review-docs`・`/setup-project`・`/setup-steering`・`/ship`・`/smart-review`（一覧は [`prompt.md`](prompt.md)）

`common` plugin（`plugins/common/`）が提供するもの:

- **コマンド** — `/commit`・`/commit-push`・`/critic`・`/grill-me`・`/task-start`（git 運用・審問・作業開始の汎用ユーティリティ）
- **エージェント** — architect / code-reviewer / debugger / project-manager

## インストール

Claude Code の Plugin 機構で導入する:

```
/plugin marketplace add au-aii/claude-config
/plugin install dev@claude-config-marketplace
/plugin install common@claude-config-marketplace
```

ローカルにクローン済みなら、リポジトリルートをパス指定しても追加できる:

```
/plugin marketplace add /path/to/claude-config
/plugin install dev@claude-config-marketplace
/plugin install common@claude-config-marketplace
```

詳細手順は [`docs/plugin-getting-started.md`](docs/plugin-getting-started.md)、採用理由は [ADR-0001](docs/adr/0001-plugin-based-distribution.md) を参照。プロジェクトのテンプレートとして丸ごと使う手順は [ONBOARDING.md](ONBOARDING.md)。

### コマンドが見つからない・使えないとき

「マーケットプレイス登録」と「プラグイン有効化」は別レイヤー。片方が欠けても症状は同じ（コマンドが見つからない）ため、両方を確認する:

```bash
# 1. マーケットプレイスが登録されているか
cat ~/.claude/plugins/known_marketplaces.json | grep claude-config-marketplace

# 2. プラグインが有効化されているか
cat ~/.claude/settings.json | grep -A3 enabledPlugins
```

`dev@claude-config-marketplace` / `common@claude-config-marketplace` が両方 `true` になっていなければ、上記「インストール」の手順を再実行する。

過去に `dev`/`common` 分割前の旧構成（プラグイン名 `claude-config`）を導入していた場合、リネームは自動移行されず `~/.claude/plugins/cache/` に孤立キャッシュとして残ることがある。その場合は一度 `/plugin marketplace remove claude-config-marketplace` してから「インストール」の手順を再実行する。

## 開発フロー

1. `docs/ideas/` にアイデアをメモ
2. `/setup-project` で `docs/` の永続ドキュメントを整備
3. `/add-feature <Issue番号> <機能名>` でブランチ・ステアリング生成〜実装まで自動実行
4. `/ship` で PR 作成〜レビュー〜修正〜マージまで一気通貫で実行

## 設計思想: ドキュメントを2層に分ける

| 層       | 場所                        | 性質                                               |
| -------- | --------------------------- | -------------------------------------------------- |
| 永続     | `docs/`                     | プロジェクトの基本設計。方針が変わるまで更新しない |
| 作業単位 | `.steering/YYYYMMDD-title/` | 今回の作業の要求・設計・タスク。作業ごとに新規作成 |

## MCP

`.mcp.json` で `context7` / `playwright` / `chrome-devtools` を有効化している。
`${VAR}` 構文を使っているので、起動前にシェルで環境変数を export しておく:

```bash
export UPSTASH_REDIS_REST_URL="https://..."
export UPSTASH_REDIS_REST_TOKEN="..."
```

## 前提

Git / Docker / VS Code + Dev Containers 拡張
