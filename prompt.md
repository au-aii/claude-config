# Prompt Catalog

<!-- 自動生成: このファイルは claude-dotfiles の plugins/dev から生成されています。直接編集せず、正本のコマンド/スキルの frontmatter を編集して再生成してください（Issue #53）。 -->

dev plugin が提供するコマンドとスキルの一覧です。運用ルールと手順は [README.md](README.md) / [CLAUDE.md](CLAUDE.md) を参照してください。

## Commands

- `/add-feature` 新機能を既存パターンに従って、完全に無停止で実装する
- `/asdd` Agent Spec Driven Development。
- `/design` designer-agent → dev-agent → doc-agent の3分業パイプラインを、承認ゲートを挟みながら順に起動する司令塔コマンド。
- `/review-docs` ドキュメントの詳細レビューをサブエージェントで実行
- `/setup-project` 初回セットアップ: PRD のみ対話式で作成し、残り5つの永続ドキュメントは承認後に自動生成する
- `/setup-steering` 作業用の requirements / design / tasklist を作成する。
- `/ship` 現在のブランチをレビュー先行で出荷する。
- `/smart-review` 拡張コードレビュー。

## Skills

永続ドキュメント（PRD・機能設計・アーキテクチャ・リポジトリ構造・開発ガイドライン・用語集）は `/setup-project` がまとめて生成します。各ドキュメントの書き方はこのスキルを参照してください。

- [architecture-design](plugins/dev/skills/architecture-design/SKILL.md) アーキテクチャ設計書を作成するための詳細ガイドとテンプレート。
- [development-guidelines](plugins/dev/skills/development-guidelines/SKILL.md) チーム全体で統一された開発プロセスとコーディング規約を確立するための包括的なガイドとテンプレート。
- [functional-design](plugins/dev/skills/functional-design/SKILL.md) 機能設計書を作成するための詳細ガイドとテンプレート。
- [glossary-creation](plugins/dev/skills/glossary-creation/SKILL.md) 用語集を作成するための詳細ガイドとテンプレート。
- [prd-writing](plugins/dev/skills/prd-writing/SKILL.md) プロダクト要求定義書(PRD)を作成するための詳細ガイドとテンプレート。
- [repository-structure](plugins/dev/skills/repository-structure/SKILL.md) リポジトリ構造定義書を作成するための詳細ガイドとテンプレート。
- [steering](plugins/dev/skills/steering/SKILL.md) 作業指示毎の作業計画、タスクリストをドキュメントに記録するためのスキル。
