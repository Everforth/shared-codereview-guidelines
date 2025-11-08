# Shared CodeReview Guidelines

このリポジトリは GitHub Actions 経由で Claude Code によるコードレビュー・開発支援を受けるためのGitHub Actions と Everforth におけるコードレビューの指標を管理するためのものです。

## Setup

1. Claude API Key を Secrets に設定する
   - API キーを取得して `ANTHROPIC_API_KEY` を手動で設定するか、ローカル Claude Code 上で `/github` を実行してください（ `/github` を使用する場合、2 では上書き保存してください）
2. `claude.yml` を `.github/workflows/` に配置する

## 使い方

- 何もつけずに `@claude` にメンションするとコードレビューを行います
  - レビュー依頼として重要視する観点などをつけてメンションするとその観点に集中します
- メッセージを付けて `@claude` にメンションするとメッセージに応じて分析や提案を行います

## 運用

- docs フォルダ内のドキュメントを更新することで、レビュー指標を追加・修正できます。
- 変更を加えた後、プルリクエストを作成してください。
- 変更内容は GitHub Actions によって自動的に反映されます。
