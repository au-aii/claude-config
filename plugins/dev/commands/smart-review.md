---
name: smart-review
description: 拡張コードレビュー。PR差分・ローカル差分を多観点で並列レビューし、セキュリティ問題が検出された場合は自動で security-review をカスケード実行する。使う場面：セキュリティ懸念を含みうる差分・多観点の並列レビューが必要な大きめの PR。使わない場面：通常の差分レビュー（/code-review で十分）・セキュリティ専用レビュー（/security-review 単体）。"スマートレビュー" "smart-review" などで自動トリガー。
argument-hint: "[pr-number]"
allowed-tools: Agent, Bash(gh pr diff:*), Bash(gh pr view:*), Bash(gh pr list:*), Bash(gh pr comment:*), Bash(gh issue view:*), Bash(gh search:*), Bash(git diff:*), Bash(git log:*), Bash(git blame:*), Bash(git show:*), Read, Grep, Glob, Skill
---

<!-- 自動生成: このファイルは claude-dotfiles から生成された配布物です。直接編集せず、正本(https://github.com/au-aii/claude-dotfiles)を編集して再生成してください。 -->

拡張コードレビューを実行する。以下の手順に従え。

## エージェント起動テンプレート（共通）

以降の Step に登場する「Haiku agent」「Sonnet agent」は、すべて Agent ツールで次の形式で起動する：

- `subagent_type: "general-purpose"`
- `model`: Step の指定に従う（プリチェック・CLAUDE.md収集・差分サマリ・信頼度スコアリング = haiku／観点レビュー = sonnet）
- プロンプトには必ず含める:
  1. 対象差分の取得コマンド（例: `git diff HEAD` または `gh pr diff $ARGUMENTS`）
  2. 担当観点（Step 4 の観点表を参照）
  3. 出力形式（issue リスト＋根拠＋ファイル:行）

以降の Step 記述はこのテンプレートを前提とする。観点ごとに全文プロンプトを書く必要はない。

## Step 0: スコープ決定

- `$ARGUMENTS` が空 → `git diff HEAD` でローカルモード
- `$ARGUMENTS` が数字 → PR番号として扱い `gh pr view $ARGUMENTS` で取得

## Step 1: プリチェック（Haiku agent、上記テンプレート適用）

以下のいずれかに該当する場合は終了する:

- PRモード: closed / draft の PR
- 差分が空
- 明らかに自動生成・単純すぎる変更（lock ファイル更新のみ等）

## Step 2: CLAUDE.md 収集（Haiku agent、上記テンプレート適用）

ルートと diff 対象ディレクトリの CLAUDE.md ファイルパスを収集する。

## Step 3: 差分サマリ（Haiku agent、上記テンプレート適用）

PR または git diff から変更内容のサマリを生成する。

## Step 4: 並列レビュー

以下の9つの Sonnet agent（上記テンプレート適用）を**同時に**起動する。各 agent は issue のリストと、各 issue に対する0〜100の信頼度スコアの根拠を返す。

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

## Step 5: 信頼度スコアリング（各 issue に対して並列 Haiku agent、上記テンプレート適用）

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

- `gh pr comment` で以下の形式で投稿する（1回のみ）
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

## 例

**悪い例**: 9観点の Agent 結果をそのまま並記して統合レポートに貼り付ける。同じ根本原因の指摘が複数件重複して並ぶ。

**良い例**: Agent B と Agent G が同じ関数の同じ null チェック漏れを別角度から指摘 → 1件に統合し、信頼度が最も高いスコアで重症度順に並べる。

## 完了条件

- Step 7 の統合レポートが出力されている
- PR モードの場合は `gh pr comment` によるコメント投稿が1回だけ行われている
- Step 6 で security-review カスケードが発火した場合、その結果が Step 7 のレポートに含まれている
- 80点未満の issue がレポートに含まれていない
