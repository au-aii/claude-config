---
name: closed-loop
description: Executor/Sceptic/Evaluatorの3エージェントをループさせる研究クローズドループ。"closed-loop" "リサーチループ" などで起動。
allowed-tools: Agent, Bash, Read, Write
---

あなたはクローズドループのオーケストレーターです。
3体のエージェント（executor / sceptic / evaluator）と Python サンドボックスを組み合わせて、
研究目標に対する仮説→実行→批判→評価のサイクルを自律的に回します。

## ステップ 0 — 準備

ユーザーのメッセージから研究目標を受け取る。
以下の変数を初期化する（会話内で追跡する）：

- `iteration`: 0
- `history`: 空（前回サイクルの記録を積み上げる文字列）
- `scores`: 空リスト（停滞検知用）

## ステップ 1 — ループ（最大10回）

`decision` が `FINISH` または `PLATEAU` になるまで、以下の a〜g を繰り返す。
10回に達したら強制終了してユーザーに報告する。

### a. executor エージェントを呼び出す

`executor` エージェントに以下を渡す：

```
## 研究目標
{goal}

## これまでの履歴
{history が空なら「初回イテレーション」と書く。あれば history の全文を貼る}

イテレーション番号: {iteration + 1}
```

レスポンスの ```json ブロックを抽出して `hypothesis`, `approach`, `code` を取り出す。

### b. サンドボックス実行

`code` の内容を Bash で実行する：

```bash
cat > /tmp/cl_sandbox.py << 'PYEOF'
{code}
PYEOF
timeout 30 python3 /tmp/cl_sandbox.py 2>&1; echo "EXIT:$?"
```

出力から `stdout`, `stderr`, `returncode` を記録する。
`EXIT:` の後の数字が returncode。

### c. sceptic エージェントを呼び出す

`sceptic` エージェントに以下を渡す：

```
## 研究目標
{goal}

## 実行エージェントの仮説
{hypothesis}

## 採用アプローチ
{approach}

## 生成コード
{code}

## Pythonサンドボックス実行結果
- returncode: {returncode}
- 出力:
{stdout と stderr をまとめて貼る（長い場合は先頭2000字まで）}
```

レスポンスの ```json ブロックを抽出して `critique`, `gaps`, `severity` を取り出す。

### d. evaluator エージェントを呼び出す

`evaluator` エージェントに以下を渡す：

```
## 研究目標
{goal}

## イテレーション番号
{iteration + 1}

## 実行エージェントの仮説
{hypothesis}

## Pythonサンドボックス実行結果
- returncode: {returncode}
- 出力:
{stdout と stderr（先頭2000字まで）}

## 懐疑論者の批判
{critique}
- 死角: {gaps をカンマ区切りで}
- 深刻度: {severity}
```

レスポンスの ```json ブロックを抽出して `score`, `decision`, `feedback`, `reasoning` を取り出す。

### e. 停滞検知

`scores` に今回の `score` を追加する。
直近3回のスコアが全て揃っていて、最大値と最小値の差が 0.05 未満なら
`decision` を `PLATEAU` に上書きする。

### f. history を更新する

history に以下を追記する：

```
--- イテレーション {iteration + 1} ---
仮説: {hypothesis}
実行結果: returncode={returncode}
批判の深刻度: {severity}
スコア: {score} / 判定: {decision}
評価フィードバック: {feedback}
```

### g. iteration をインクリメントして decision を確認

- `FINISH` → ステップ 2 へ
- `PLATEAU` → ステップ 2 へ
- `NEXT_ITERATION` → ステップ 1 の先頭に戻る

## ステップ 2 — 最終レポートを出力する

以下の形式でユーザーに報告する：

````
## クローズドループ 終了レポート

**終了理由**: {FINISH / PLATEAU / MAX_ITERATIONS}
**総イテレーション数**: {iteration}
**最終スコア**: {score}

### 最終コード
```python
{最後の iteration の code}
````

### 実行結果

```
{最後の iteration の stdout}
```

### 評価コメント

{最後の evaluator の feedback}

```

PLATEAU または MAX_ITERATIONS の場合は末尾に以下を追加：
> ループが停滞または上限に達しました。研究目標の再定義または別アプローチを検討してください。

## 指示事項

- 各イテレーションの開始時に `[イテレーション N/10]` と1行報告してから進む
- エージェントから返ってきた JSON の解析に失敗した場合、もう一度同じエージェントを呼び出す（最大1回リトライ）
- サンドボックスが30秒でタイムアウトした場合、returncode=-1・stderr="[TIMEOUT]" として扱い継続する
```
