# GitHub Actions Setup Guide

週次Claudeレビューレポートの自動生成をGitHub Actionsで設定する手順です。

## 前提条件

- Everforth Organizationのオーナーまたは管理者権限
- このリポジトリへの管理者権限
- Anthropic API key（Claude Code用）

## セットアップ手順

### 1. Personal Access Token (PAT) の作成

Organization全体のリポジトリにアクセスするためのPATを作成します。

1. GitHubにログインし、右上のプロフィールアイコンをクリック
2. **Settings** > **Developer settings** > **Personal access tokens** > **Fine-grained tokens** に移動
3. **Generate new token** をクリック

**Token settings:**

- Token name: `Weekly Claude Report - Everforth`
- Expiration: `90 days` または `No expiration`（推奨: 90日で定期的に更新）
- Resource owner: `Everforth`
- Repository access: **All repositories**

**Permissions:**

- Actions: **Read-only** ✅
- Contents: **Read-only** ✅
- Metadata: **Read-only** ✅ (自動選択)
- Pull requests: **Read-only** ✅

4. **Generate token** をクリック
5. **トークンをコピーして安全な場所に保存**（後で確認できません）

### 2. Repository Secrets の設定

このリポジトリに必要なシークレットを追加します。

1. このリポジトリのページに移動
2. **Settings** > **Secrets and variables** > **Actions** に移動
3. 以下の2つのシークレットを追加:

#### `EVERFORTH_ORG_PAT`

- **New repository secret** をクリック
- Name: `EVERFORTH_ORG_PAT`
- Secret: 手順1で作成したPATを貼り付け
- **Add secret** をクリック

#### `ANTHROPIC_API_KEY`

- **New repository secret** をクリック
- Name: `ANTHROPIC_API_KEY`
- Secret: あなたのAnthropic API keyを貼り付け
- **Add secret** をクリック

### 3. ワークフローの確認

ワークフローファイルは既に配置されています：

- `.github/workflows/weekly-report.yml`

このファイルは以下を実行します：

- **スケジュール**: 毎週日曜日 09:00 JST (00:00 UTC)
- **手動実行**: GitHub Actionsページから実行可能

### 4. テスト実行（推奨）

本番実行の前に、手動でワークフローをテストします。

1. リポジトリの **Actions** タブに移動
2. 左サイドバーから **Weekly Claude Review Report** を選択
3. 右上の **Run workflow** ボタンをクリック
4. ブランチを選択（通常は `main`）
5. **Run workflow** をクリック

**確認ポイント:**

- ✅ ワークフローが正常に開始される
- ✅ PR収集ステップが成功する
- ✅ Claude Code実行が成功する
- ✅ Issueが作成される

### 5. 生成されたIssueの確認

ワークフローが成功すると、以下のようなIssueが自動作成されます：

**Title:**

```
週次Claudeレビューレポート - 2026-02-28 〜 2026-03-07
```

**Labels:**

- `weekly-report`
- `automated`

**Content:**

- 対象期間
- 分析したPR数
- Claude Codeによる評価
- 元データ（PR一覧）

### 6. 自動実行の確認

初回の自動実行は次の日曜日 09:00 JSTに行われます。

**確認方法:**

1. 日曜日の午前中にリポジトリをチェック
2. **Actions** タブで最新のワークフロー実行を確認
3. **Issues** タブで新しいレポートIssueを確認

## トラブルシューティング

### ワークフローが失敗する

#### エラー: `gh: command not found`

→ ワークフローでは自動的に `gh` CLIがインストールされるため、このエラーは発生しないはずです。

#### エラー: `Error: Resource not accessible by personal access token`

→ PATの権限が不足しています。手順1を確認してPATを再作成してください。

#### エラー: `No PRs found`

→ 過去7日間に `EF-guideline-called` ラベルが付いたPRがない場合、レポート生成はスキップされます。これは正常な動作です。

### Claude Code が実行されない

#### エラー: `ANTHROPIC_API_KEY not found`

→ 手順2で `ANTHROPIC_API_KEY` シークレットを追加してください。

#### エラー: API rate limit exceeded

→ Anthropic APIのレート制限に達しました。しばらく待ってから再実行してください。

### Issueが作成されない

#### ワークフローは成功したがIssueがない

1. リポジトリの **Settings** > **Actions** > **General** を確認
2. **Workflow permissions** で以下が設定されているか確認:
   - "Read and write permissions" が選択されている
   - "Allow GitHub Actions to create and approve pull requests" がチェックされている

## メンテナンス

### PATの更新

PATは定期的に更新することを推奨します（90日ごと）。

1. 手順1に従って新しいPATを作成
2. 手順2に従って `EVERFORTH_ORG_PAT` シークレットを更新
3. テスト実行で動作確認

### ワークフローのカスタマイズ

`.github/workflows/weekly-report.yml` を編集することで、以下をカスタマイズできます：

- **実行スケジュール**: `cron` の値を変更
  ```yaml
  schedule:
    - cron: '0 0 * * 0'  # 毎週日曜日 00:00 UTC
  ```
- **対象期間**: `scripts/weekly-claude-report.sh` の `DAYS_BACK` 変数を変更
- **Claude Codeのプロンプト**: スクリプト内の `PROMPT_CONTENT` を変更

## サポート

問題が発生した場合：

1. **Actions** タブでワークフローログを確認
2. エラーメッセージを特定
3. 上記のトラブルシューティングを参照
4. それでも解決しない場合はIssueを作成

## 完了チェックリスト

セットアップが完了したら、以下を確認してください：

- [ ] PATを作成し、`EVERFORTH_ORG_PAT` シークレットに設定
- [ ] Anthropic API keyを `ANTHROPIC_API_KEY` シークレットに設定
- [ ] 手動でワークフローをテスト実行
- [ ] テスト実行が成功し、Issueが作成された
- [ ] 次回の自動実行日時を確認（日曜日 09:00 JST）

すべてチェックできたら、セットアップ完了です！🎉
