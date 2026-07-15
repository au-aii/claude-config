# Prompt Catalog

このファイルは「短い実行コマンド集」です。
運用ルールと手順は以下を参照してください。

- 全体運用: [README.md](README.md)
- ルール基準: [CLAUDE.md](CLAUDE.md)
- スキル詳細: [plugins/dev/skills](plugins/dev/skills)

> ここに載るコマンドは `plugins/dev/commands/` が正本です。コマンドを増減したらこの一覧も更新してください。

## Frequently Used

- `/add-feature` 新機能を既存パターンに従って、完全に無停止で実装する
- `/ship` push→レビュー→修正ループ→PR作成→マージをレビュー先行で一気通貫に実行する
- `/setup-project` 初回セットアップ。PRD のみ対話式で作成し、残りの永続ドキュメントは承認後に自動生成する
- `/setup-steering` 作業用の requirements / design / tasklist を作成する（`/add-feature` の計画部分だけを単体実行したいとき）
- `/review-docs` docs 配下の品質レビューをサブエージェントで実行する

## Design / Review

- `/asdd` 大きいタスクを「計画→批判的検証→実装→検証」の4ステージで実行する（影響範囲が不明・複数ファイルに跨る変更）
- `/design` designer→dev→doc の3分業パイプラインを、人間の承認ゲートを挟みながら順に起動する
- `/smart-review` 差分を多観点で並列レビューし、セキュリティ問題を検出したら security-review を自動カスケードする

## Document Setup

永続ドキュメント（PRD・機能設計・アーキテクチャ・リポジトリ構造・開発ガイドライン・用語集）は
`/setup-project` が対話式でまとめて生成します。各ドキュメントの書き方は下の Skill を参照してください。

## Skill Backlinks

- [architecture-design](plugins/dev/skills/architecture-design/SKILL.md)
- [development-guidelines](plugins/dev/skills/development-guidelines/SKILL.md)
- [functional-design](plugins/dev/skills/functional-design/SKILL.md)
- [glossary-creation](plugins/dev/skills/glossary-creation/SKILL.md)
- [prd-writing](plugins/dev/skills/prd-writing/SKILL.md)
- [repository-structure](plugins/dev/skills/repository-structure/SKILL.md)
- [steering](plugins/dev/skills/steering/SKILL.md)
