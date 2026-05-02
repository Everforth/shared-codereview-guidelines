# Shared CodeReview Guidelines

このリポジトリは GitHub Actions 経由で Claude Code によるコードレビュー・開発支援を受けるためのGitHub Actions と Everforth におけるコードレビューの指標を管理するためのものです。

## Setup

1. Claude API Key を Secrets に設定する
   - API キーを取得して `ANTHROPIC_API_KEY` を手動で設定するか、ローカル Claude Code 上で `/github` を実行してください（ `/github` を使用する場合、2 では上書き保存してください）
2. `shared-claude-caller.yml` を `.github/workflows/` に配置する（`@claude` メンションでのレビューを使う場合）
3. `shared-refine-suggest-caller.yml` を `.github/workflows/` に配置する（週次の Refine Suggest を使う場合）

## 使い方

### `@claude` メンションによるオンデマンドレビュー

- 何もつけずに `@claude` にメンションするとコードレビューを行います
  - レビュー依頼として重要視する観点などをつけてメンションするとその観点に集中します
- メッセージを付けて `@claude` にメンションするとメッセージに応じて分析や提案を行います

### 週次 Refine Suggest

- `shared-refine-suggest-caller.yml` を配置したリポジトリで、毎週月曜 10:00 JST に自動実行されます（`workflow_dispatch` で手動実行も可能）。
- 直近 1 週間に Merge された PR の周辺ファイル（import/export/relation で 1 ホップ先まで）を対象に、最も古い機能単位 1 つに対してパターンレビューを実行し、検出された指摘ごとに Issue を作成します。
- 実行内容の詳細は [`code-refine/prompt.md`](./code-refine/prompt.md) を参照してください。
- 各リポジトリ側に `.claude/commands/pattern-review.md` を用意する必要があります（プロンプトから参照されます）。

## 運用

- docs フォルダ内のドキュメントを更新することで、レビュー指標を追加・修正できます。
- 変更を加えた後、プルリクエストを作成してください。
- 変更内容は GitHub Actions によって自動的に反映されます。
