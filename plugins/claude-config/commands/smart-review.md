---
name: smart-review
description: 拡張コードレビュー。PR差分・ローカル差分を多観点で並列レビューし、セキュリティ問題が検出された場合は自動で security-review をカスケード実行する。"スマートレビュー" "smart-review" などで自動トリガー。
argument-hint: "[pr-number]"
allowed-tools: Agent, Bash(gh pr diff:*), Bash(gh pr view:*), Bash(gh pr list:*), Bash(gh pr comment:*), Bash(gh issue view:*), Bash(gh search:*), Bash(git diff:*), Bash(git log:*), Bash(git blame:*), Bash(git show:*), Read, Grep, Glob, Skill
---

拡張コードレビューを実行する。以下の手順に従え。

## Step 0: スコープ決定

- `$ARGUMENTS` が空 → `git diff HEAD` でローカルモード
- `$ARGUMENTS` が数字 → PR番号として扱い `gh pr view $ARGUMENTS` で取得

## Step 1: プリチェック（Haiku agent を使う）

以下のいずれかに該当する場合は終了する:

- PRモード: closed / draft の PR
- 差分が空
- 明らかに自動生成・単純すぎる変更（lock ファイル更新のみ等）

## Step 2: CLAUDE.md 収集（Haiku agent を使う）

ルートと diff 対象ディレクトリの CLAUDE.md ファイルパスを収集する。

## Step 3: 差分サマリ（Haiku agent を使う）

PR または git diff から変更内容のサマリを生成する。

## Step 4: 並列レビュー

以下の9つの Sonnet agent を**同時に**起動する。各 agent は issue のリストと、各 issue に対する0〜100の信頼度スコアの根拠を返す。

**標準観点:**

- Agent A — CLAUDE.md 規約準拠チェック
- Agent B — バグ・ロジック（浅いスキャン、変更箇所のみ）
- Agent C — git blame / git log を読んで履歴文脈でのバグ検出
- Agent D — 過去 PR のコメントを読んで同様の指摘がないか確認（PRモードのみ）

**追加観点:**

- Agent E — セキュリティ（SQLインジェクション / XSS / 認証バイパス / 機密情報のハードコード / 権限昇格）
- Agent F — 破壊的変更（API互換性・スキーマ変更・型シグネチャ変更・下流への影響）
- Agent G — エラーハンドリング漏れ（silent failure・空の catch・不適切な fallback）
- Agent H — 依存関係リスク（新しいライブラリの追加・既知 CVE・バージョン固定の欠如）
- Agent I — ログ・観測可能性（重要ポイントのログ欠落・機密情報のログへの漏れ）

## Step 5: 信頼度スコアリング（各 issue に対して並列 Haiku agent）

各 issue を以下のスケールで再評価する:

- 0: 誤検知。精査に耐えない
- 25: 可能性あり。誤検知かもしれない
- 50: 中程度。実際に発生するが重要度は低い
- 75: 高信頼。実際に起きうる重大な問題
- 100: 確実。頻繁に発生し直接影響がある

**80点未満の issue はすべて除外する。**

## Step 6: セキュリティカスケード判定

Step 5 終了後、**Agent E（セキュリティ）の issue が1件以上残っている**（80点以上）場合:

```
「セキュリティ問題が検出されました。詳細審査のため security-review を実行します。」
```

と通知してから `Skill(security-review)` を実行する。

Agent E の残存 issue が0件の場合はカスケードしない。

## Step 7: 結果出力

**PRモード:**

- `gh pr comment` で以下の形式で投稿する
- セキュリティカスケードがあった場合はその結果も含める

**ローカルモード:**

- コンソールに出力する

**出力フォーマット:**

```
### Smart Review

N件の問題を検出しました。

**[カテゴリ名]** 問題の説明
ファイル:行
信頼度: XX%

---
（セキュリティカスケードが走った場合、security-review の結果をここに続ける）
```

問題が0件の場合は「問題は検出されませんでした。」とだけ出力する。
