# claude-config — AI コーディングエージェント用ガードレール

AI エージェント（Claude Code など）に**取り返しのつかない操作をさせない**ための hook 一式。

エージェントは指示を読み飛ばす。「main に直接 commit しないで」と書いても、長いセッションの終盤では守られない。**確実に止めるには機械的な強制が要る** — これはそのための最小の実装です。

## 何を止めるか

| hook                    | 止めるもの                                                                                                                                                                                                                                      |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `guard.sh`              | **main / master への直接 commit・push**／ルート・ホーム・ワイルドカードを対象にした **`rm -rf`**／未追跡ファイルを実削除する **`git clean`**／並行セッションでの**ブランチ取り違え**（作業中と違うブランチへの commit）／サンドボックスの無効化 |
| `guard-edit.sh`         | エージェント自身による **`settings.json` の書き換え**（権限の自己緩和）                                                                                                                                                                         |
| `guard-configchange.sh` | 設定変更の**監査ログ**（ブロックはしない）                                                                                                                                                                                                      |

止めるだけでなく、**エラーメッセージに正しい手順を書いています**。ブロックされたエージェントはその場で正しいやり方を学びます。

`rm -rf ./node_modules` のような日常的な操作は通します。止めるのは復旧できないものだけです。

## 導入

### Plugin として入れる（推奨）

```
/plugin marketplace add au-aii/claude-config
/plugin install guardrails@claude-config-marketplace
```

`hooks.json` が `${CLAUDE_PLUGIN_ROOT}` で配線されるので、パスの書き換えは要りません。

### 手動で入れる

`hooks/` を任意の場所に置き、`hooks/settings-recommended.json` の内容を自分の `settings.json` にマージします。この JSON には hook の配線に加えて、認証情報・環境変数ファイルの読み取りを拒否する `permissions.deny` も入っています。

## テスト

配布する3つの hook には、正本リポジトリでセルフテストが **113件**付いています（`guard` 93 / `guard-edit` 13 / `guard-configchange` 7）。テスト本体は非公開ですが、挙動に疑問があれば Issue で聞いてください。

## `core/principles.md`

ツール非依存の行動原則。plugin ではないので `/plugin install` の対象外です。使う場合は clone して自分の `CLAUDE.md` から import します：

```markdown
@core/principles.md
```

## ワークフロー系は配っていません

SDD（仕様駆動開発）のワークフロー、コードレビュー、commit・PR 作成は、**既に良いものが公開されている**のでここでは配っていません。探している場合はこちらへ。

| 欲しいもの                       | どこにあるか                                                                                                                                                                   |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 計画 → 実装 → 検証の skill 一式  | `superpowers`（Anthropic 公式マーケットプレイス収録）<br>`/plugin marketplace add anthropics/claude-plugins-official`<br>`/plugin install superpowers@claude-plugins-official` |
| 仕様駆動開発のツールキット       | [github/spec-kit](https://github.com/github/spec-kit)（125k★・GitHub 公式）。Claude Code 対応（skills モードで `.claude/skills` に配置）。Python 3.11+ と uv が要り、**プロジェクトごと**に `specify init` する                         |
| コードレビュー / commit・PR 作成 | Anthropic 公式マーケットプレイスの `code-review` / `commit-commands`                                                                                                           |

ここが配るのは、**公式マーケットプレイス273件を全部見て、出来合いのものが見つからなかったガードレールだけ**です。

## このリポジトリについて

`core/`・`hooks/`・`plugins/` は private リポジトリ `claude-dotfiles` から**一方向に生成された配布物**です（各ファイル先頭に自動生成ヘッダーがあります）。**直接編集しても次回の生成で上書きされます。** 修正は Issue でお知らせください。

## ライセンス

MIT。`LICENSE.txt` を参照。
