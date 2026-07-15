# claude-config

Claude Code の開発ワークフロー（SDD: PRD〜steering〜実装〜レビュー）を配布する **`dev` plugin** の公開マーケットプレイス。

> **`plugins/dev/` 配下は生成物です。** その正本は private リポジトリ `claude-dotfiles` の `plugins/dev/` にあり、publish パイプラインで **一方向に生成**された配布物です（各ファイル先頭に自動生成ヘッダーがあります）。**`plugins/dev/` を直接編集しないでください**（編集は正本側で行い再生成します）。
>
> それ以外のファイル（この README・ONBOARDING・prompt.md・`docs/`・`scripts/`・Dev Container 設定・`.mcp.json` など）は**本 repo が正本**であり、直接編集してかまいません。経緯は Issue #19 を参照。

## 何が入っているか

`dev` plugin（`plugins/dev/`）が提供するもの:

- **エージェント** — Designer / Dev / Doc / Reviewer など局面別に呼び分け
- **スキル** — 設計知識（アーキテクチャ設計・機能設計・PRD・用語集・リポジトリ構造・開発ガイドライン・steering）を分離して CLAUDE.md を肥大化させない
- **コマンド** — `/add-feature`・`/asdd`・`/design`・`/setup-project`・`/setup-steering`・`/ship`・`/smart-review`・`/review-docs`（一覧は [`prompt.md`](prompt.md)）

## インストール

Claude Code の Plugin 機構で導入する:

```
/plugin marketplace add au-aii/claude-config
/plugin install dev@claude-config-marketplace
```

ローカルにクローン済みなら、リポジトリルートをパス指定しても追加できる:

```
/plugin marketplace add /path/to/claude-config
/plugin install dev@claude-config-marketplace
```

詳細手順は [`docs/plugin-getting-started.md`](docs/plugin-getting-started.md)、採用理由は [ADR-0001](docs/adr/0001-plugin-based-distribution.md) を参照。プロジェクトのテンプレートとして丸ごと使う手順は [ONBOARDING.md](ONBOARDING.md)。

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
