#!/bin/bash
# scripts/weekly-claude-report.sh
# Weekly Claude Code review report generator
# Collects PRs with EF-guideline-called label from configured Organizations

set -euo pipefail

# Parse command line arguments
OUTPUT_ONLY=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --output-only)
      OUTPUT_ONLY=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 [--output-only]" >&2
      exit 1
      ;;
  esac
done

# Configuration
ORGS=("Everforth" "acetokyo-com")
DAYS_BACK=7
LABEL="EF-guideline-called"
OUTPUT_FILE="claude-report-data.json"
TEMP_DIR=$(mktemp -d)

# Calculate cutoff date (macOS and Linux compatible)
if date -v-1d > /dev/null 2>&1; then
  # macOS
  CUTOFF_DATE=$(date -u -v-${DAYS_BACK}d +%Y-%m-%d)
else
  # Linux
  CUTOFF_DATE=$(date -u -d "${DAYS_BACK} days ago" +%Y-%m-%d)
fi

echo "=== Weekly Claude Report Generator ===" >&2
echo "Organizations: ${ORGS[*]}" >&2
echo "Looking back: $DAYS_BACK days (since $CUTOFF_DATE)" >&2
echo "Label filter: $LABEL" >&2
echo "" >&2

# Step 1: Fetch repository list from all organizations
echo "[1/3] Fetching repositories from ${ORGS[*]}..." >&2
repos=""
for org in "${ORGS[@]}"; do
  echo -n "  $org... " >&2
  org_repos=$(gh repo list "$org" --limit 1000 --json nameWithOwner --jq '.[].nameWithOwner')
  org_count=$([ -n "$org_repos" ] && echo "$org_repos" | wc -l | tr -d ' ' || echo 0)
  echo "$org_count repositories" >&2
  repos="${repos}${org_repos}"$'\n'
done
repos=$(echo "$repos" | sed '/^$/d')
repo_count=$(echo "$repos" | wc -l | tr -d ' ')
echo "Found $repo_count repositories total" >&2
echo "" >&2

# Step 2: Scan repositories for labeled PRs
echo "[2/3] Scanning repositories for labeled PRs..." >&2
pr_count=0
for repo in $repos; do
  echo -n "  Checking $repo... " >&2

  # Get PRs with EF-guideline-called label (all states)
  prs=$(gh pr list --repo "$repo" \
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
    safe_name=$(echo "$repo" | tr '/' '_')
    echo "$filtered_prs" > "$TEMP_DIR/$safe_name.json"
    pr_count=$((pr_count + count))
  else
    echo "no PRs" >&2
  fi
done
echo "Total PRs found: $pr_count" >&2
echo "" >&2

# Step 3: Aggregate results
echo "[3/3] Aggregating results..." >&2
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
  rm -rf "$TEMP_DIR"
  exit 0
fi

# Create prompt content
PROMPT_CONTENT="以下のPRについて、内容を確認し評価して。
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

if [ "$OUTPUT_ONLY" = true ]; then
  # Output only mode: print prompt to stdout for GitHub Actions
  echo "$PROMPT_CONTENT"
else
  # Interactive mode: execute Claude Code
  echo "=== Executing Claude Code ===" >&2
  echo "" >&2
  claude -p "$PROMPT_CONTENT"
fi

# Cleanup
rm -rf "$TEMP_DIR"
