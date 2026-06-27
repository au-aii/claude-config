# Design — SDD ワークフロー Step0

## 実装アプローチ

ADR 0001 の決定を受け、2つの穴を「定義の明文化」で塞ぐ。
コードや設定ファイルは変更せず、ドキュメントで経路と配置を一意化する。

## 穴A: 検証エージェント入口の統合（設計）

### 現状の4エージェント

| エージェント               | 役割                                                 |
| -------------------------- | ---------------------------------------------------- |
| `implementation-validator` | 実装コードがスペックと整合しているか検証             |
| `code-reviewer`            | コードの正しさ・セキュリティ・パフォーマンスを確認   |
| `doc-reviewer`             | ドキュメント品質をレビュー                           |
| `reviewer-agent`           | PR のコードレビューを実行し GitHub PR コメントに投稿 |

### 整理後の呼び出し経路（一意化）

```
asdd Stage4（検証）
├─ 実装直後（PR 前）
│   ├─ スペック整合性  → implementation-validator
│   └─ コード品質     → code-reviewer（/code-review）
├─ ドキュメント変更後
│   └─ ドキュメント品質 → doc-reviewer（/review-docs）
└─ PR 作成後
    └─ PR コメント投稿  → reviewer-agent（/ship 内部で呼ばれる）
```

**判断の木:**

1. 実装コードを書いた → `implementation-validator` → `code-reviewer`
2. docs/ を更新した → `doc-reviewer`
3. PR を作った / レビューコメントが必要 → `reviewer-agent`

重複なし・順序明確・スキップ条件なし（小変更エスケープハッチ時は全省略可）。

## 穴B: spec/.steering 配置の一意化（設計）

### 所有権ルール（確定）

| ファイル種別                                                                   | 配置場所                       | 所有権                 |
| ------------------------------------------------------------------------------ | ------------------------------ | ---------------------- |
| 永続ドキュメント（product-requirements / functional-design / architecture 等） | `docs/`                        | そのリポジトリの正本   |
| ADR（アーキテクチャ決定記録）                                                  | `docs/adr/`                    | そのリポジトリの正本   |
| 作業単位ドキュメント                                                           | `.steering/YYYYMMDD-タイトル/` | そのリポジトリの正本   |
| グローバル共有スキル                                                           | `claude-config` リポジトリ     | チーム共有テンプレート |
| 個人設定                                                                       | `claude-dotfiles` リポジトリ   | 個人の正本             |

**ルール:**

- 同じファイルを2箇所に置かない（単一の正本）
- リポジトリ間コピーは禁止。参照は Issue / PR リンクで行う
- `.steering/` は作業完了後も削除せず履歴として保持

## 変更するコンポーネント

### 新規作成

- `docs/adr/0001-sdd-workflow-operations.md` — 本決定の ADR
- `.steering/20260627-sdd-workflow-step0/requirements.md`（本ファイルの親）
- `.steering/20260627-sdd-workflow-step0/design.md`（本ファイル）
- `.steering/20260627-sdd-workflow-step0/tasklist.md`

### 変更しない

- `agents/`, `commands/`, `skills/`, `settings.json`, `CLAUDE.md`
- `.steering/20260620-closed-loop-agent-sync/`（既存）

## 影響範囲

- 破壊的変更なし
- 既存のワークフローは変更されない
- Step1 以降で本 design.md の「整理後の呼び出し経路」をスキルへ反映する
