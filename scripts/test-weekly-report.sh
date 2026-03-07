#!/bin/bash
# scripts/test-weekly-report.sh
# Test script for weekly-claude-report.sh with limited repositories

set -euo pipefail

# Configuration - test with a small subset of repositories
ORG="Everforth"
DAYS_BACK=7
LABEL="EF-guideline-called"
OUTPUT_FILE="claude-report-data-test.json"
TEMP_DIR=$(mktemp -d)

# Test with specific repositories only
TEST_REPOS=("pj-ring-api" "wismettac-sales-ai-api" "pj-hotel-lovers-api")

# Calculate cutoff date (macOS and Linux compatible)
if date -v-1d > /dev/null 2>&1; then
  # macOS
  CUTOFF_DATE=$(date -u -v-${DAYS_BACK}d +%Y-%m-%d)
else
  # Linux
  CUTOFF_DATE=$(date -u -d "${DAYS_BACK} days ago" +%Y-%m-%d)
fi

echo "=== Weekly Claude Report Generator (TEST MODE) ===" >&2
echo "Organization: $ORG" >&2
echo "Looking back: $DAYS_BACK days (since $CUTOFF_DATE)" >&2
echo "Label filter: $LABEL" >&2
echo "Test repositories: ${TEST_REPOS[*]}" >&2
echo "" >&2

# Scan test repositories for labeled PRs
echo "Scanning test repositories for labeled PRs..." >&2
pr_count=0
for repo in "${TEST_REPOS[@]}"; do
  echo -n "  Checking $repo... " >&2

  # Get PRs with EF-guideline-called label (all states)
  prs=$(gh pr list --repo "$ORG/$repo" \
    --label "$LABEL" \
    --state all \
    --limit 100 \
    --json number,title,url,author,createdAt,updatedAt,state,labels,mergedAt \
    2>/dev/null || echo "[]")

  # Filter PRs updated in the last DAYS_BACK days
  filtered_prs=$(echo "$prs" | jq --arg cutoff "$CUTOFF_DATE" --arg repo "$repo" \
    '[.[] | select(.updatedAt > $cutoff) | . + {repository: $repo}]')

  count=$(echo "$filtered_prs" | jq 'length')
  if [ "$count" -gt 0 ]; then
    echo "$count PRs found" >&2
    echo "$filtered_prs" > "$TEMP_DIR/$repo.json"
    pr_count=$((pr_count + count))
  else
    echo "no PRs" >&2
  fi
done
echo "Total PRs found: $pr_count" >&2
echo "" >&2

# Aggregate results
echo "Aggregating results..." >&2
if ls "$TEMP_DIR"/*.json >/dev/null 2>&1; then
  jq -s 'add' "$TEMP_DIR"/*.json > "$OUTPUT_FILE"
else
  echo "[]" > "$OUTPUT_FILE"
fi
echo "Report data saved to $OUTPUT_FILE" >&2
echo "" >&2

# Generate PR list
pr_list=$(jq -r '.[] | "- \(.url) (\(.repository))"' "$OUTPUT_FILE")

if [ -z "$pr_list" ]; then
  echo "No PRs found in the specified period." >&2
  echo "This might be expected if:" >&2
  echo "  - No PRs were updated in the last $DAYS_BACK days" >&2
  echo "  - The Claude workflow hasn't been run recently" >&2
  echo "  - The label name has changed" >&2
  rm -rf "$TEMP_DIR"
  exit 0
fi

# Create prompt
PROMPT="以下のPRについて、内容を確認し評価して。
出力フォーマット(フォーマットは必ず守ること)
- https://github.com/Everforth/pj-ring-api/pull/121 ズレたレビュー、指摘を受けて全層レビュー完了まで進んだ
- https://github.com/Everforth/wismettac-sales-ai-api/pull/282 正常系、一発通過
- https://github.com/acetokyo-com/nextream-front/pull/4 正常系

# 対象期間
$CUTOFF_DATE 〜 $(date -u +%Y-%m-%d)

# PR一覧（合計: $pr_count 件）
$pr_list

各PRについて以下の観点で評価してください:
1. レビューの実施状況（正常系、ズレたレビュー、複数回呼び出し等）
2. 特筆すべき点やパターン
3. レビューの質や内容に関する気づき"

# Execute Claude Code
echo "" >&2
echo "=== Executing Claude Code ===" >&2
echo "" >&2
claude "$PROMPT"

# Cleanup
rm -rf "$TEMP_DIR"
