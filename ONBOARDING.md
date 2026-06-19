# ONBOARDING — claude-config

Claude Code を使ってチームで爆速開発するためのテンプレート。
このドキュメントを読めば **15分以内に開発を始められる**。

---

## 前提

| ツール                                                                                                                  | 確認方法                           |
| ----------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| Git                                                                                                                     | `git --version`                    |
| Docker Desktop                                                                                                          | 起動していることを確認             |
| VS Code + [Dev Containers 拡張](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) | 拡張一覧で確認                     |
| Claude Code                                                                                                             | `claude --version`（なければ後述） |

---

## Step 1 — リポジトリをクローンして自分のプロジェクトにする

```bash
git clone https://github.com/au-aii/claude-config <プロジェクト名>
cd <プロジェクト名>
rm -rf .git && git init && git add . && git commit -m "initial: from claude-config template"
```

---

## Step 2 — Dev Container を起動する

VS Code でフォルダを開き、右下の通知 or コマンドパレット（`Cmd+Shift+P`）から：

```
Reopen in Container
```

コンテナが起動すると `bootstrap.sh` が自動で走り、Claude Code CLI と Playwright が設定される。

> **MCP を使う場合のみ** — コンテナ起動前にターミナルで環境変数を export しておく：
>
> ```bash
> export UPSTASH_REDIS_REST_URL="https://..."
> export UPSTASH_REDIS_REST_TOKEN="..."
> ```
>
> 使わない場合はそのまま進めて問題ない。

---

## Step 3 — Claude Code にログインする

コンテナ内のターミナルで：

```bash
claude
```

初回起動時にブラウザが開くのでログイン・認証する（Anthropic アカウントが必要）。

---

## Step 4 — プロジェクトの設計を固める（初回のみ）

Claude Code のチャットで以下を実行する。**1ファイルごとに確認しながら進める**：

```
/setup-project
```

`docs/` 配下に6つの永続ドキュメントが対話的に作成される。

| ファイル                         | 内容             |
| -------------------------------- | ---------------- |
| `docs/product-requirements.md`   | 何を作るか       |
| `docs/functional-design.md`      | どう動くか       |
| `docs/architecture.md`           | 技術スタック     |
| `docs/repository-structure.md`   | フォルダ構成     |
| `docs/development-guidelines.md` | コーディング規約 |
| `docs/glossary.md`               | 用語定義         |

---

## Step 5 — 実装を始める

### 機能を追加するとき

```
/add-feature <Issue番号> <機能名>
```

Issue からブランチを作成し、要件・設計・タスクリストを `.steering/YYYYMMDD-<title>/` に自動生成してから実装まで自動で進める。

### 実装が終わったら PR を出してマージするとき

```
/ship
```

PR作成 → 自動レビュー（`reviewer-agent`）→ 指摘修正ループ → マージまでを一気通貫で実行する。最大3回まで自動修正を試みる。

### 作業ドキュメントだけ先に作りたいとき

```
/setup-steering <開発タイトル>
```

### ドキュメントをレビューしてほしいとき

```
/review-docs <ファイルパス>
```

---

## エージェントの使い分け

明示的に呼ばなくても Claude が自動で使い分けるが、指定することもできる：

| エージェント     | 用途                 |
| ---------------- | -------------------- |
| `designer-agent` | 設計ドキュメント作成 |
| `dev-agent`      | コード実装           |
| `doc-agent`      | docs/ の更新         |
| `reviewer-agent` | PR レビュー          |

---

## よくあるトラブル

### `claude` コマンドが見つからない

```bash
npm install -g @anthropic-ai/claude-code
```

### Playwright が動かない

```bash
npx playwright install chromium
```

### Context7 MCP のエラーが出る

`UPSTASH_REDIS_REST_URL` / `UPSTASH_REDIS_REST_TOKEN` が未設定。
使わないなら `.mcp.json` の `context7` ブロックを削除して問題ない。

---

## ディレクトリ構成（把握しておくと困らない）

```
.
├── .claude/
│   ├── agents/     # 役割別エージェント定義
│   ├── commands/   # /コマンド 定義
│   └── skills/     # 設計知識ライブラリ
├── .devcontainer/  # Dev Container 設定
├── .steering/      # 作業ごとの一時ドキュメント（YYYYMMDD-title/）
├── docs/           # プロジェクト永続ドキュメント
├── .mcp.json       # MCP サーバー設定
├── CLAUDE.md       # Claude へのプロジェクト指示
└── prompt.md       # よく使うコマンド一覧
```

---

詳細は [`README.md`](README.md) と [`CLAUDE.md`](CLAUDE.md) を参照。
