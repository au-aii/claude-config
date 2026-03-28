# mcp-config テンプレート

このリポジトリは、プロジェクト立ち上げ時の設定と運用ルールを再利用するためのテンプレートです。

## 実行コマンド参照

実際に入力するコマンドプロンプトは [prompt.md](prompt.md) を参照してください。
詳細ルールは [CLAUDE.md](CLAUDE.md) と [README.md](README.md) を正本とします。

## プロジェクト開始方法

このリポジトリ自体をそのまま開発には使いません。
テンプレートとしてクローンし、新規プロジェクトとして初期化して利用します。

初回セットアップは **Dev Container を起動するだけでOK** です。
`.devcontainer/devcontainer.json` の `postCreateCommand` により、
`./.devcontainer/bootstrap.sh` が自動実行されます。

1. テンプレートをクローンする

```bash
git clone <this-repo-url> my-project
cd my-project
```

2. テンプレートの Git 履歴を切り離して新規プロジェクトとして初期化する

```bash
# macOS / Linux
rm -rf .git

# Windows (PowerShell)
# Remove-Item -Recurse -Force .git

git init
# VS Code で「Reopen in Container」を実行
# 初回は bootstrap が自動実行される
```

補足（必要な場合のみ）:
- 自動実行後に再セットアップしたい場合は `./.devcontainer/bootstrap.sh` を手動実行してください。

3. 最初はメモを優先し、内容が固まってからプロジェクト固有設定を更新する

最初の段階では要件が未確定なことが多いため、この時点では深追いしません。
`docs/ideas/` へのメモや要求整理を進め、プロジェクトの方向性が固まってきたタイミングで次を編集してください。

- `package.json`
- `.devcontainer/devcontainer.json`
- `mcp_config.json` の環境変数参照（特に Context7 用の値）
- ライセンス表記と README

## 前提条件

- Git が利用可能であること
- Dev Container を利用できること（Docker / Dev Containers 拡張）
- `.devcontainer/bootstrap.sh` が実行できること（Dev Container 起動時に自動実行）
- 必要な環境変数を OS またはシェル側で設定できること

補足:
- `mcp_config.json` の `UPSTASH_REDIS_REST_URL` / `UPSTASH_REDIS_REST_TOKEN` が未設定の場合、Context7 は利用できません。
- `PLAYWRIGHT_SKIP_INSTALL=1 ./.devcontainer/bootstrap.sh` で Playwright の初期化のみスキップできます。

## CLAUDE.md の位置づけ

`CLAUDE.md` は、このテンプレートの運用ポリシーを定義する基準ドキュメントです。

- 目的: ドキュメント構造、作業手順、更新ルールを統一する
- 対象: 開発者と AI エージェントの両方
- 性質: プロジェクト全体に適用する「ルールブック」

特に、次の原則を README からも参照できるようにします。

- 永続的ドキュメントは `docs/` 配下で管理する
- 作業単位のドキュメントは `.steering/[YYYYMMDD]-[title]/` で管理する
- 設計方針が変わる場合のみ永続ドキュメントを更新する

## ドキュメント運用モデル

- 永続的ドキュメント: `docs/` 配下に配置し、プロジェクトの基本設計を保持する
- 作業単位ドキュメント: `.steering/` 配下に作業ごとに作成し、変更の意図と履歴を管理する
- アイデアメモ: `docs/ideas/` に自由形式で記録する

## 標準フロー

1. アイデアを `docs/ideas/` に記録する
2. `docs/` の永続ドキュメントを整備する
3. `.steering/` に作業単位ディレクトリを作成する
4. 要求・設計・タスクを明確化して実装する
5. 実装後に lint、型チェック、テストを実行する

## テンプレート適用時のカスタマイズ

- `package.json`
- `.devcontainer/devcontainer.json`
- `.husky/` 配下のフック設定（例: `.husky/pre-commit`）
- フォーマッター設定（`.prettierignore`, `.prettierrc`, `eslint.config.js`）
- `LICENSE.txt` はプロジェクトのライセンスポリシーに合わせて適切なものを選択してください。

## Husky 運用メモ

Husky を有効にするには、設定ファイルを置くだけでなく初期化が必要です。

- Git リポジトリとして初期化されていること
- Husky が依存関係としてインストールされていること
- フック有効化の初期化処理が完了していること

推奨:
- フック内容はチームで合意する
- 重い処理は CI に寄せる
- セットアップ手順を README に明記する