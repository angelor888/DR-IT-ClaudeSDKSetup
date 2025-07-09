# GitHub Workflows Setup Instructions

## Token Permissions Issue

The GitHub workflows in `.github/workflows/` require a Personal Access Token with `workflow` scope to be created or updated.

## Current Error
```
! [remote rejected] main -> main (refusing to allow a Personal Access Token to create or update workflow `.github/workflows/ci.yml` without `workflow` scope)
```

## Resolution Steps

### Option 1: Update Personal Access Token Permissions
1. Go to GitHub Settings: https://github.com/settings/tokens
2. Find your current Personal Access Token
3. Edit the token and add the `workflow` scope
4. Update your local git configuration with the new token

### Option 2: Manual Upload
1. Download the workflow files from this repository
2. Navigate to your GitHub repository in the browser
3. Go to the "Actions" tab
4. Click "set up a workflow yourself"
5. Copy and paste each workflow file manually

### Option 3: GitHub CLI
```bash
# Install GitHub CLI if not already installed
brew install gh

# Authenticate with GitHub CLI
gh auth login

# Create workflows using GitHub CLI
gh workflow create ci.yml -f .github/workflows/ci.yml
gh workflow create security.yml -f .github/workflows/security.yml
gh workflow create dependency-update.yml -f .github/workflows/dependency-update.yml
gh workflow create code-quality.yml -f .github/workflows/code-quality.yml
gh workflow create deploy.yml -f .github/workflows/deploy.yml
```

## Workflow Files Available

1. **ci.yml** - Continuous Integration
   - Node.js and Python testing
   - Cross-platform compatibility checks
   - Build verification

2. **security.yml** - Security Scanning
   - CodeQL analysis
   - TruffleHog secrets detection
   - Snyk vulnerability scanning
   - npm audit

3. **dependency-update.yml** - Automated Updates
   - Weekly dependency updates
   - Claude CLI updates
   - Automated pull requests

4. **code-quality.yml** - Code Quality
   - ESLint, Prettier, TypeScript checks
   - Python: Black, Ruff, mypy
   - Shell: shellcheck, shfmt
   - Markdown: markdownlint

5. **deploy.yml** - Deployment
   - GitHub Pages documentation
   - Automated releases
   - Asset packaging

## Repository Secrets Required

Add these secrets to your GitHub repository:
- `GITHUB_TOKEN` (automatically provided)
- `SNYK_TOKEN` (for vulnerability scanning)

## After Setup

Once workflows are created, they will automatically run on:
- Push to main/develop branches
- Pull requests
- Weekly schedule (for dependency updates)
- Manual dispatch

## Testing

After setup, test workflows by:
1. Creating a pull request
2. Pushing to main branch
3. Manually triggering workflows from Actions tab

---

The workflows are production-ready and will enhance your development process with automated testing, security scanning, and deployment.