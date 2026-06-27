# Tasklist — SDD ワークフロー Step0

## フェーズ1: ドキュメント作成（このPR）

- [x] `docs/adr/0001-sdd-workflow-operations.md` を MADR 形式で作成
- [x] `.steering/20260627-sdd-workflow-step0/requirements.md` を作成
- [x] `.steering/20260627-sdd-workflow-step0/design.md` を作成
- [x] `.steering/20260627-sdd-workflow-step0/tasklist.md` を作成
- [x] git status で設定ファイル変更ゼロを確認
- [x] PR 作成（Closes #17, refs #16）

## フェーズ2: 実装（別PR）

- [ ] 検証エージェント呼び出し経路を `asdd` スキル / ドキュメントに反映
      （implementation-validator → code-reviewer → [doc-reviewer] → reviewer-agent の順序）
- [ ] spec / .steering 所有権ルールを CLAUDE.md または README に追記
- [ ] 受け入れ条件のチェックボックスを埋める

## 受け入れ条件（フェーズ2完了時に確認）

- [ ] 検証エージェントの呼び出し場面が重複なく定義されている
- [ ] spec / .steering の所有権ルールが公式ドキュメントに記載されている
- [ ] agents / commands / skills / settings / CLAUDE.md 以外のファイルのみが変更されている

## 実装後の振り返り

（フェーズ2完了後に記録）
