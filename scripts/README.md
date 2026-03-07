# Weekly Claude Report Scripts

## Overview

This directory contains scripts for generating weekly reports on Claude Code reviews across the Everforth Organization.

## Scripts

### `weekly-claude-report.sh`

Collects PRs that have been reviewed by Claude Code (identified by the `EF-guideline-called` label) and automatically executes Claude Code CLI for analysis.

**What it does:**

1. Scans all repositories in the Everforth Organization
2. Finds PRs with the `EF-guideline-called` label updated in the last 7 days
3. Aggregates PR data into a JSON file
4. Generates a prompt with the PR list
5. Automatically executes `claude --message "<prompt>"` for analysis

### `test-weekly-report.sh`

Test version of the weekly report script that scans only a small subset of repositories (pj-ring-api, wismettac-sales-ai-api, pj-hotel-lovers-api) for quick verification.

**Use this script to:**

- Verify your environment is set up correctly
- Test the script functionality before running on all repositories
- Debug issues without waiting for a full organization scan

## Prerequisites

### Required Tools

1. **GitHub CLI (`gh`)**

   ```bash
   # macOS
   brew install gh

   # Ubuntu/Debian
   sudo apt install gh

   # Verify installation
   gh --version
   ```

2. **jq (JSON processor)**

   ```bash
   # macOS
   brew install jq

   # Ubuntu/Debian
   sudo apt install jq

   # Verify installation
   jq --version
   ```

3. **Claude Code CLI**

   ```bash
   # Install Claude Code CLI (if not already installed)
   # See: https://github.com/anthropics/claude-code

   # Verify installation
   claude --version
   ```

### Authentication

Authenticate with GitHub CLI:

```bash
gh auth login
# Follow the prompts and select:
# - GitHub.com
# - HTTPS
# - Login with a web browser (or paste an authentication token)
```

Verify access to Everforth Organization:

```bash
gh repo list Everforth --limit 1
```

## Usage

### Testing First (Recommended)

Before running the full script, test with a subset of repositories:

```bash
./scripts/test-weekly-report.sh
```

This will scan only 3 repositories and automatically execute Claude Code for analysis.

### Basic Usage

Run the script from the repository root:

```bash
./scripts/weekly-claude-report.sh
```

The script will:

1. Scan all Everforth Organization repositories
2. Collect PRs with the `EF-guideline-called` label from the last 7 days
3. Save raw data to `claude-report-data.json`
4. Automatically execute Claude Code with a prompt containing the PR list
5. Display Claude's analysis in the terminal

### Output Files

The script generates:

**`claude-report-data.json`** - Raw PR data in JSON format

```json
[
  {
    "number": 121,
    "title": "Feature: Add user authentication",
    "url": "https://github.com/Everforth/pj-ring-api/pull/121",
    "author": {"login": "user1"},
    "createdAt": "2026-03-01T10:00:00Z",
    "updatedAt": "2026-03-05T15:30:00Z",
    "state": "merged",
    "labels": [{"name": "EF-guideline-called"}],
    "repository": "pj-ring-api"
  }
]
```

### What Claude Code Analyzes

The script passes a prompt to Claude Code asking it to evaluate each PR based on:

1. Review implementation status (normal, misaligned review, multiple calls, etc.)
2. Notable points or patterns
3. Insights about review quality and content

Claude Code will analyze the actual PR contents and provide feedback in Japanese.

### Customization

Edit the script to customize parameters:

```bash
# Configuration variables (at the top of the script)
ORG="Everforth"           # GitHub Organization
DAYS_BACK=7               # Number of days to look back
LABEL="EF-guideline-called"  # Label to filter PRs
OUTPUT_FILE="claude-report-data.json"  # Output file name
```

## Troubleshooting

### Issue: `gh` authentication error

```bash
gh auth login
# Re-authenticate with GitHub
```

### Issue: Permission denied when running script

```bash
chmod +x scripts/weekly-claude-report.sh
```

### Issue: `jq: command not found`

Install jq using your package manager (see Prerequisites section).

### Issue: No PRs found

- Verify that PRs in your organization have the `EF-guideline-called` label
- Check if the label is added by the Claude workflow (`.github/workflows/claude.yml`)
- Try increasing `DAYS_BACK` to look further back in history

### Issue: Rate limiting

If you have many repositories, you might hit GitHub API rate limits:

```bash
# Check your rate limit status
gh api rate_limit
```

Wait for the rate limit to reset, or use a Personal Access Token with higher limits.

### Issue: `claude: command not found`

The Claude Code CLI is not installed or not in your PATH:

```bash
# Verify installation
which claude

# If not found, install Claude Code CLI
# See: https://github.com/anthropics/claude-code
```

## Future Enhancements (Phase 2)

The following features are planned for GitHub Actions integration:

- [ ] Automated weekly execution via cron schedule
- [ ] PR list collection using the shell script
- [ ] Claude Code execution via `anthropics/claude-code-action@beta`
- [ ] Automatic GitHub Issue creation with Claude's analysis
- [ ] Custom report templates

## Related Files

- `.github/workflows/claude.yml` - The Claude Code review workflow that adds the `EF-guideline-called` label
- `.github/workflows/weekly-report.yml` - (Future) GitHub Actions workflow for automated weekly reports

## License

This script is part of the shared-codereview-guidelines repository and follows the same license.
