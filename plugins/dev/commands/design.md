---
name: design
description: designer-agent → dev-agent → doc-agent の3分業パイプラインを、承認ゲートを挟みながら順に起動する司令塔コマンド。使う場面：設計ドキュメントを人間の承認ゲートを挟みながら作りたい機能開発。使わない場面：無停止で一気に実装したい場合（/add-feature）・批判的検証つきで回したい場合（/asdd）・計画ファイルだけ欲しい場合（/setup-steering）。"設計から進めて" "designer-agentを使って" "SDDで作って" などで自動トリガー。
argument-hint: "<機能の説明>"
allowed-tools: Agent, Read, Bash, Glob, Grep
---

<!-- 自動生成: このファイルは claude-dotfiles から生成された配布物です。直接編集せず、正本(https://github.com/au-aii/claude-dotfiles)を編集して再生成してください。 -->

あなたは SDD（Spec Driven Development）オーケストレーターです。
`designer-agent` → 承認ゲート → `dev-agent` → `doc-agent` の順に起動する。
**各ステージの完了報告を1行で示してから次に進むこと。承認ゲートだけは自分の判断で飛ばさない。**

## ステージ 1 — 設計（designer-agent）

`designer-agent`（model: sonnet）を起動し、引数の機能説明を渡す。

- 生成物: `.steering/YYYYMMDD-[タイトル]/` 配下の `requirements.md` → `design.md` → `tasklist.md`（この順で作成される）
- designer-agent はコードを一切書かず、3ファイル生成後に停止する契約
- 注: designer-agent の tasklist.md は steering skill の `templates/tasklist.md` とは**別フォーマット**（互換ではない）。dev-agent は steering を経由せず tasklist を直接消化する契約のため機能上の問題はないが、/setup-steering 製の tasklist と混在させないこと

## 承認ゲート（/add-feature との最大の違い）

designer-agent の完了報告（3ファイルのパスと要点3行）をそのままユーザーに提示する。

- **ユーザーの明示的な承認を得るまでステージ2に進まない**
- 修正依頼が来たら designer-agent を再起動して該当ファイルを直させ、再度提示する
- 承認語（「OK」「進めて」「承認」等）が得られて初めて次へ

## ステージ 2 — 実装（dev-agent）

承認後、`dev-agent`（model: sonnet）を起動する。

- 入力: `.steering/[日付]-[タイトル]/tasklist.md` と `design.md` のパスを明示して渡す（dev-agent はこの2ファイルの存在を前提条件として確認する）
- dev-agent は tasklist.md の順に実装し、完了タスクを `[x]` に更新、`docs/` 配下には触れない契約
- 完了報告（実装タスク一覧・品質チェック結果）を受け取ったらユーザーに提示する

## ステージ 3 — ドキュメント更新（doc-agent）

`doc-agent`（model: sonnet）を起動する。

- 入力: `.steering/[日付]-[タイトル]/design.md`・`requirements.md` のパス（doc-agent は `git diff main...HEAD` と合わせて変更内容を把握する契約）
- doc-agent は `docs/` 配下のみ更新し、コードファイルには触れない契約
- 完了報告（更新ファイル一覧・更新不要だったファイル）をユーザーに提示する

## 例

**悪い例**: designer-agent の完了報告を受け取った直後、ユーザーの承認を待たずに dev-agent を起動する。設計の誤りに気づかないまま実装が進み、手戻りが発生する。

**良い例**: designer-agent の生成物を提示 →「Phase 2 のタスク分割が粗いので割ってほしい」と指摘を受ける → designer-agent を再起動して tasklist.md を修正 → 再提示 →「進めて」の承認を得てから dev-agent を起動する。

## 完了条件

- `.steering/[日付]-[タイトル]/` に `requirements.md`・`design.md`・`tasklist.md` の3点が生成されている
- 承認ゲートでユーザーの承認発言が記録されている（ステージ2着手前に必須）
- dev-agent の実装 diff（完了タスク一覧）がユーザーに提示されている
- doc-agent による `docs/` 配下の更新（または「更新不要」の判断）が報告されている
