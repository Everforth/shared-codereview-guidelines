# Weekly Claude Report Implementation Summary

## Phase 1: Local Execution ✅ COMPLETED

### Implemented Files

1. **`scripts/weekly-claude-report.sh`** (Main script)
   - Scans all Everforth Organization repositories
   - Collects PRs with `EF-guideline-called` label from the last 7 days
   - Generates JSON data and Claude prompt
   - Automatically executes Claude Code CLI with the prompt

2. **`scripts/test-weekly-report.sh`** (Test script)
   - Tests with a small subset of repositories
   - Verifies environment setup
   - Quick validation before full run

3. **`scripts/README.md`** (Documentation)
   - Prerequisites and installation guide
   - Usage instructions
   - Troubleshooting tips
   - Customization options

### Verification ✅

- [x] All required tools are installed (gh, jq, claude)
- [x] GitHub CLI authentication is working
- [x] Access to Everforth Organization confirmed
- [x] Test script executed successfully (found 10 PRs in 3 repositories)
- [x] JSON data structure validated
- [x] Scripts are executable
- [x] Claude Code CLI integration working (automatic execution confirmed)

### Test Results

**Test execution on 2026-03-07:**

- Scanned repositories: pj-ring-api, wismettac-sales-ai-api, pj-hotel-lovers-api
- Period: 2026-02-28 to 2026-03-07 (7 days)
- PRs found: 10 total
  - pj-ring-api: 1 PR
  - wismettac-sales-ai-api: 7 PRs
  - pj-hotel-lovers-api: 2 PRs
- All PRs were in MERGED state
- All PRs had the `EF-guideline-called` label

### Sample Output Structure

```json
{
  "author": {
    "login": "ikutani41",
    "name": "Yutaro Ikutani"
  },
  "createdAt": "2026-03-06T15:41:23Z",
  "updatedAt": "2026-03-06T15:46:49Z",
  "mergedAt": "2026-03-06T15:46:47Z",
  "number": 2337,
  "state": "MERGED",
  "title": "商品通知のプッシュ通知にディープリンクとサムネイル画像を設定",
  "url": "https://github.com/Everforth/pj-hotel-lovers-api/pull/2337",
  "labels": [
    {
      "name": "enhancement",
      "description": "New feature or request"
    },
    {
      "name": "EF-guideline-called",
      "description": "Claude Code review was executed on this PR"
    }
  ],
  "repository": "pj-hotel-lovers-api"
}
```

## How to Use

### Quick Start

1. **Run test script first:**

   ```bash
   ./scripts/test-weekly-report.sh
   ```

   This will:
   - Scan 3 test repositories for PRs
   - Automatically execute Claude Code CLI
   - Display the analysis results

2. **Run full script:**

   ```bash
   ./scripts/weekly-claude-report.sh
   ```

   This will:
   - Scan all Everforth Organization repositories
   - Automatically execute Claude Code CLI
   - Display the analysis results

3. **View raw data (optional):**
   ```bash
   # View JSON data
   cat claude-report-data.json | jq .
   ```

### Expected Output

The script will:

1. List progress for each repository scanned (to stderr)
2. Show total number of PRs found (to stderr)
3. Generate `claude-report-data.json` with raw data
4. Automatically execute Claude Code CLI
5. Display Claude's analysis of each PR (to stdout)

**Sample Claude Output:**

```
# 対象期間
2026-02-28 〜 2026-03-07

# PR一覧（合計: 10 件）の評価

## 1. https://github.com/Everforth/pj-hotel-lovers-api/pull/2337
ズレたレビュー、ikutani さんからの指摘を受けずマージ

## 2. https://github.com/Everforth/pj-hotel-lovers-api/pull/2332
正常系、fortissimo さんによる複数回呼び出しで全層レビュー完了
...
```

### Customization

Edit configuration variables at the top of the scripts:

```bash
ORG="Everforth"              # GitHub Organization
DAYS_BACK=7                  # Number of days to look back
LABEL="EF-guideline-called"  # Label to filter PRs
OUTPUT_FILE="claude-report-data.json"  # Output file name
```

## Phase 2: GitHub Actions Integration (Future)

### Planned Features

- [ ] Automated weekly execution (cron schedule: Sunday 09:00 JST)
- [ ] GitHub Issue creation with report
- [ ] PAT setup for organization-wide access
- [ ] Custom report templates
- [ ] Trend analysis over multiple weeks

### Required Files (Not Yet Implemented)

- `.github/workflows/weekly-report.yml` - GitHub Actions workflow
- Organization secret: `EVERFORTH_ORG_PAT` - Personal Access Token

### PAT Requirements (For Future Implementation)

When setting up Phase 2, create a fine-grained PAT with:

- Resource owner: Everforth
- Repository access: All repositories
- Permissions:
  - Actions: Read-only
  - Contents: Read-only
  - Issues: Read and Write (for creating report issues)
  - Metadata: Read-only
  - Pull requests: Read-only

## Technical Notes

### Label-Based Approach

The implementation uses the `EF-guideline-called` label to identify PRs that have been reviewed by Claude Code. This label is automatically added by the `.github/workflows/claude.yml` workflow when it completes successfully.

**Advantages:**

- Direct PR identification without workflow history traversal
- Fast and efficient (single API call per repository)
- Reliable (label is only added on successful review)
- No duplicate PRs (same PR appears only once)

### Claude Code CLI Integration

The script automatically executes Claude Code CLI with a prompt:

```bash
claude "$PROMPT"
```

Where `$PROMPT` contains:

- Example output format
- Date range
- PR list (URLs + repository names)
- Evaluation criteria

Claude Code then analyzes each PR's actual contents and provides feedback in Japanese.

### Date Handling

The script supports both macOS and Linux date commands:

```bash
# macOS
CUTOFF_DATE=$(date -u -v-${DAYS_BACK}d +%Y-%m-%d)

# Linux
CUTOFF_DATE=$(date -u -d "${DAYS_BACK} days ago" +%Y-%m-%d)
```

### Error Handling

- API call failures return empty arrays (`|| echo "[]"`)
- Missing repositories are skipped
- Temporary files are cleaned up automatically
- Missing tools are detected with helpful error messages

## Troubleshooting

### Common Issues

1. **No PRs found**
   - Check if PRs have the `EF-guideline-called` label
   - Increase `DAYS_BACK` to look further back
   - Verify the label name matches exactly

2. **Authentication errors**
   - Run `gh auth login` to re-authenticate
   - Check organization access permissions

3. **Rate limiting**
   - Check limits: `gh api rate_limit`
   - Wait for reset or use PAT with higher limits

4. **Claude Code not found**
   - The script will still generate the prompt file
   - Run Claude Code manually: `claude --message "$(cat /tmp/claude-prompt.txt)"`

## Next Steps

To implement Phase 2 (GitHub Actions):

1. Create `.github/workflows/weekly-report.yml`
2. Set up `EVERFORTH_ORG_PAT` organization secret
3. Test with `workflow_dispatch` trigger
4. Enable cron schedule
5. Add Issue creation step
6. Monitor first automated run

## Files Created

```
scripts/
├── weekly-claude-report.sh      # Main script (110 lines)
├── test-weekly-report.sh         # Test script (111 lines)
├── README.md                     # User documentation (218 lines)
└── IMPLEMENTATION.md             # This file - implementation summary (258 lines)
```

## Conclusion

Phase 1 implementation is complete and tested. The scripts are ready for local use to generate weekly Claude Code review reports. Phase 2 (GitHub Actions automation) can be implemented when needed.
