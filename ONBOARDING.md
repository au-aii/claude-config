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

## Step 3.5 — GitHub CLI にログインする

`/add-feature` や `/ship` で `gh` コマンドを使うため、認証が必要：

```bash
gh auth login
```

ブラウザが開くので GitHub アカウントで認証する。

次に、このプロジェクトの GitHub リポジトリを作成してリモートを設定する：

```bash
gh repo create <プロジェクト名> --private --source=. --push
```

> すでにリモートがある場合はスキップ。

---

## Step 3.6 — 通知を設定する

### Mac（デフォルトで有効）

このテンプレートの `.claude/settings.json` には Mac 通知がすでに組み込まれている。
Claude 停止時に macOS 標準通知（`osascript`）が自動で表示される。**追加設定は不要**。

通知をカスタマイズしたい場合は `~/.claude/settings.json`（グローバル設定）の `Stop` フックを編集する：

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude が停止しました\" with title \"Claude Code\"'"
          }
        ]
      }
    ]
  }
}
```

入力待ち（`Notification` イベント）にも通知を出したい場合：

```json
{
  "hooks": {
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"入力を待っています\" with title \"Claude Code\"'"
          }
        ]
      }
    ]
  }
}
```

### Windows（WSL2 + Windows のみ）

処理完了時・入力待ち時に Windows トースト通知を受け取れるようにする。

```bash
# スクリプトをコピーして実行権限を付与
mkdir -p ~/.claude/scripts
cp scripts/stop.sh scripts/notification.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/stop.sh ~/.claude/scripts/notification.sh
```

次に `~/.claude/settings.json` の `hooks` に以下を追加する（既存の設定とマージすること）：

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [{ "type": "command", "command": "~/.claude/scripts/stop.sh" }]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "~/.claude/scripts/notification.sh" }
        ]
      }
    ]
  }
}
```

設定後は Claude Code を再起動するか `/hooks` を開くと有効になる。

---

## Step 3.7 — マウスクリックを有効にする（オプション）

ターミナル上でクリックによるカーソル移動・マウスホイールスクロールが使えるようになる（v2.1.88 以降）。

**Mac（zsh）:**

```bash
echo 'export CLAUDE_CODE_NO_FLICKER=1' >> ~/.zshrc
source ~/.zshrc
```

**Mac（bash）/ Linux / WSL2:**

```bash
echo 'export CLAUDE_CODE_NO_FLICKER=1' >> ~/.bashrc
source ~/.bashrc
```

設定後は新しいターミナルセッションで Claude Code を起動すると有効になる。

---

## Step 3.8 — コマンド・エージェントをグローバルに共有する（推奨）

`git pull` のたびに commands / agents を `~/.claude/` へ自動同期する仕組みを有効にする。**初回1回だけ**実行する：

```bash
# git hooks パスをこのリポジトリの .githooks/ に向ける
git config core.hooksPath .githooks

# 現在の内容を即時反映
bash scripts/sync.sh
```

これ以降は `git pull` するだけで `~/.claude/commands/` と `~/.claude/agents/` が自動更新される（merge / rebase どちらの pull にも対応）。

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
