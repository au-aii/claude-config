# claude-config

Claude Code を使ったプロジェクト開発のためのテンプレートリポジトリ。

新規プロジェクトにクローンして使う。エージェント・スキル・スラッシュコマンド・ドキュメント構造が最初から揃った状態で開発を始められる。

---

## 設計思想

### ドキュメントを2層に分ける

| 層 | 場所 | 性質 |
|---|---|---|
| 永続ドキュメント | `docs/` | 「何を作るか・どう作るか」を定義。基本設計が変わるまで更新しない |
| 作業ドキュメント | `.steering/YYYYMMDD-title/` | 「今回何をするか」を定義。作業ごとに新規作成、完了後は履歴として保持 |

### AI エージェントを役割別に分ける

プロジェクトの局面に応じて専門エージェントを呼び分ける。

- **Designer Agent** — UI/UX 設計・ワイヤフレーム
- **Dev Agent** — 実装・コードレビュー
- **Doc Agent** — ドキュメント生成・整備
- **Doc Reviewer** — ドキュメント品質チェック
- **Implementation Validator** — 実装の妥当性検証
- **Reviewer Agent** — コードレビュー・フィードバック

### スキルで知識を構造化する

繰り返し使う設計知識をスキルファイルに分離し、CLAUDE.md を肥大化させない。

- `architecture-design` — 技術仕様・スタック選定
- `development-guidelines` — コーディング規約・Git 規約
- `functional-design` — 機能設計・データモデル
- `glossary-creation` — ユビキタス言語定義
- `prd-writing` — プロダクト要求定義
- `repository-structure` — ディレクトリ設計
- `steering` — 作業単位ドキュメントの管理

---

## 構成

```
claude-config/
  .claude/
    agents/          # 役割別エージェント定義
    commands/        # スラッシュコマンド（/add-feature 等）
    skills/          # 再利用可能な設計知識
  .devcontainer/     # Dev Container 設定
  .steering/         # 作業単位ドキュメント置き場（初期は空）
  docs/
    ideas/           # ブレスト・壁打ちメモ
  CLAUDE.md          # プロジェクト運用ルール
  .mcp.json          # MCP サーバー設定（Context7 / Playwright / Chrome DevTools）
  prompt.md          # よく使うコマンドのカタログ
```

---

## セットアップ

```bash
# クローンして新規プロジェクトとして初期化
git clone https://github.com/au-aii/claude-config my-project
cd my-project
rm -rf .git && git init

# Dev Container を起動（VS Code で「Reopen in Container」）
# bootstrap.sh が自動実行され MCP 関連がセットアップされる
```

### プロジェクト固有の設定

このテンプレートは **言語非依存** にしてある。プロジェクトを始めるタイミングで、必要に応じて以下を追加する：

- 言語ランタイム — `.devcontainer/devcontainer.json` の `features` に Node / Python / Rust 等を追加
- パッケージ管理 — `package.json` / `pyproject.toml` / `Cargo.toml` などをプロジェクトに合わせて作成
- リンター / フォーマッター — ESLint, Prettier, Ruff, rustfmt など必要なものだけ
- Git hooks — Husky, pre-commit, lefthook など好みで
- `.mcp.json` — 不要な MCP サーバーを削除、必要なものを追加
- `LICENSE.txt` — プロジェクトのライセンス

---

## 開発フロー

```
1. アイデアを docs/ideas/ に記録
         ↓
2. docs/ の永続ドキュメントを整備（/setup-prd など）
         ↓
3. .steering/YYYYMMDD-title/ に作業ドキュメントを作成
         ↓
4. tasklist.md に従って実装
         ↓
5. プロジェクトで設定したチェックを実行
```

### スラッシュコマンド一覧

| コマンド | 用途 |
|---|---|
| `/add-feature` | MVP 機能を実装する |
| `/review-docs` | docs/ の品質レビュー |
| `/setup-project` | 作業単位ドキュメントを一括作成 |
| `/setup-prd` | PRD を作成 |
| `/setup-functional-design` | 機能設計書を作成 |
| `/setup-architecture` | 技術仕様書を作成 |
| `/setup-repository-structure` | リポジトリ構造定義書を作成 |
| `/setup-development-guidelines` | 開発ガイドラインを作成 |
| `/setup-glossary` | ユビキタス言語定義を作成 |

---

## MCP 構成

| サーバー | 用途 |
|---|---|
| `context7` | ライブラリの最新ドキュメントを参照（Upstash Redis 必要）|
| `playwright` | ブラウザ操作・E2E テスト支援 |
| `chrome-devtools` | Chrome DevTools プロトコル連携 |

`.mcp.json` 内で `${VAR_NAME}` 構文を使用しており、Claude Code 起動時にシェルの環境変数で自動置換される。
Context7 を使う場合は以下を `.env` または OS 側で設定する：

```bash
export UPSTASH_REDIS_REST_URL="https://..."
export UPSTASH_REDIS_REST_TOKEN="..."
```

---

## 前提条件

- Git
- Docker（Dev Container 用）
- VS Code + Dev Containers 拡張
