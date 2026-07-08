# ADR-0001: Plugin配布方式の導入（既存方式と併用）

- Status: Accepted（2026-07-08 カットオーバー実施により過渡期は終了。下記追記参照）
- Date: 2026-07-06

> **カットオーバー追記（2026-07-08, Issue #19）**: 本 ADR が「Consequences」で先送りとした正式カットオーバーを実施した。claude-config は private 正本 `claude-dotfiles` からの**一方向生成物**へ転換し、二重管理していた `.claude/{agents,commands,skills}` と `plugins/claude-config/`、および旧同期機構（`scripts/sync.sh`・`.githooks/{post-merge,post-rewrite}`）を削除。plugin は正本から生成される `dev`（`plugins/dev/`）に一本化し、marketplace 定義はリポジトリルート `.claude-plugin/marketplace.json`（`source: ./plugins/dev`）へ移設した。以下本文中の「`.claude/` は当面無改変」「二重管理を許容」等は当時の過渡期の判断であり、現在は解消済み。

## Context

claude-configはこれまで2通りの方法で配布してきた:

1. **clone-and-detach**（主要）: `git clone ... && rm -rf .git && git init` でプロジェクトへまるごと複製
2. **symlink共有**（オプション）: `.githooks/post-merge`・`post-rewrite` が `scripts/sync.sh` を呼び、`.claude/commands/*.md`・`.claude/agents/*.md` を `~/.claude/{commands,agents}/` へ同期

一方、Claude Code は公式のPlugin機構（`marketplace.json` + `plugin.json`）を提供しており、`/plugin marketplace add <path>` → `/plugin install <name>@<marketplace>` でGitHubへのpush無しにローカル即時導入・検証ができることを確認した。agents/commands/skills/hooks/MCPをひとまとめに配布でき、settings.json手動編集・symlink手管理から解放されるのが利点。

調査で以下を確認済み:

- `marketplace.json` は `<マーケットプレイスルート>/.claude-plugin/marketplace.json`。必須は `name`/`owner`/`plugins`配列
- `plugin.json` は省略可。含める場合の必須は `name` のみ
- plugin側の `settings.json` は `agent`/`subagentStatusLine` のみ対応 — **`permissions`(allow/deny)はplugin側に置けない**（技術的制約）
- hooksは `settings.json` の `hooks` オブジェクトをそのまま `hooks/hooks.json` にコピーするだけで移行可能
- `${CLAUDE_PLUGIN_ROOT}` はhooks/MCP等の構造化フィールドだけでなく、SKILL.md本文（Markdown散文）内でも実際に展開されることをローカル検証で確認済み（`skills/steering/SKILL.md`のテンプレート読込で実証）
- `commands/smart-review.md` が呼ぶ `Skill(security-review)` はclaude-config固有ではなくClaude Code本体の組み込みスキルであり、plugin化しても壊れない

## Decision

1. **単一plugin（`claude-config`）に一本化する**。10 agents・12 commands・7 skillsは全て「PRD→steering→実装→レビュー→出荷」という単一の開発ワークフローに従属しており、研究/開発のような利用コンテキストの分岐がないため分割不要。
2. **追加のみ（コピー）、`.claude/` は当面無改変**。`.claude/`を直接移動すると`scripts/sync.sh`による既存メンバーの`~/.claude/{agents,commands}/` symlinkが壊れるため、移行期間中は`.claude/`と`plugins/claude-config/`の二重管理を許容する。
3. **permissions(allow/deny)はbaseline（`.claude/settings.json`）に残置**。plugin側に置けない技術的制約に加え、`deny`（`.env`/`secrets`/`.aws`/`.ssh`読み取り拒否）はセキュリティガードでありplugin無効時に効かなくなってはならないため、そもそも置くべきでもない。
4. **hooks（PostToolUse prettier整形、Stop macOS通知）はplugin側にも複製する**。セキュリティに無関係な利便性機能であり、plugin配布の目的（settings.json手動編集からの解放）に資するため。今日時点では`.claude/settings.json`側からは削除せず二重状態を許容する。
5. `plugins/claude-config/skills/steering/SKILL.md`内のリポジトリルート相対ハードコードパス（`.claude/skills/steering/templates/*.md`）を`${CLAUDE_PLUGIN_ROOT}/skills/steering/templates/*.md`に書き換える（コピー側のみ、`.claude/`原本は無改変）。

## Consequences

- `.claude/`と`plugins/claude-config/`の間に一時的な重複コンテンツが生じる。正式カットオーバー（`.claude/`削除、README/ONBOARDINGの全面書き換え、`scripts/sync.sh`・`.githooks`の廃止）は別途の意思決定として先送りする。
- チームメンバーはPlugin方式・従来方式のどちらでも導入できる過渡期になる。導入手順は[`docs/plugin-getting-started.md`](../plugin-getting-started.md)を参照。
- `.claude/settings.json`の`mcpServers.context7`直書きと`.mcp.json`の不整合（既存の別バグ）は本ADRの範囲外として残置する。
- 複数pluginへの分割は現状ニーズがないため行わない。将来「PRD専用」「レビュー専用」等の利用文脈の分化が実際に発生したら、`plugins/`配下にディレクトリを追加し`marketplace.json`にエントリを足すだけで対応できる。
