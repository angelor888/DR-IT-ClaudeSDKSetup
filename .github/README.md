# GitHub Integration Templates

This directory contains GitHub Actions workflows for automated CI/CD, testing, and deployment of Claude Code projects.

## Workflows

### `ci.yml` - Continuous Integration
- **Trigger**: Push to main/develop, Pull requests
- **Purpose**: Run tests, linting, and builds for Node.js, Python, and Shell scripts
- **Matrix**: Tests across Node.js 20.x/22.x and Python 3.9/3.10/3.11
- **Features**:
  - npm/uv dependency management
  - Test execution with Jest/pytest/bats
  - Linting and type checking
  - Build verification

### `security.yml` - Security Scanning
- **Trigger**: Push, Pull requests, Weekly schedule
- **Purpose**: Automated security vulnerability scanning
- **Features**:
  - npm audit for Node.js dependencies
  - CodeQL analysis for JavaScript/Python
  - TruffleHog for secrets detection
  - Snyk vulnerability scanning
  - Shellcheck security rules

### `dependency-update.yml` - Automated Updates
- **Trigger**: Weekly schedule, Manual dispatch
- **Purpose**: Keep dependencies up-to-date
- **Features**:
  - npm package updates
  - Claude CLI updates
  - MCP server container updates
  - Automated pull requests

### `code-quality.yml` - Code Quality Checks
- **Trigger**: Push, Pull requests
- **Purpose**: Enforce code quality standards
- **Features**:
  - ESLint/Prettier for JavaScript/TypeScript
  - Black/Ruff/mypy for Python
  - shellcheck/shfmt for Shell scripts
  - markdownlint for documentation
  - File permission checks

### `deploy.yml` - Deployment
- **Trigger**: Push to main, Tags, Manual dispatch
- **Purpose**: Deploy documentation and create releases
- **Features**:
  - GitHub Pages deployment
  - Automated releases from tags
  - Changelog generation
  - Release asset creation

## Setup Instructions

1. **Repository Secrets**: Add the following secrets to your repository:
   - `GITHUB_TOKEN` (automatically provided)
   - `SNYK_TOKEN` (for vulnerability scanning)

2. **Branch Protection**: Enable branch protection rules:
   - Require status checks to pass before merging
   - Require branches to be up to date before merging
   - Require pull request reviews

3. **Workflow Permissions**: Ensure workflows have appropriate permissions:
   - Read/write repository contents
   - Read/write pull requests
   - Read/write pages (for documentation deployment)

## Customization

### Adding New Workflows
1. Create a new `.yml` file in `.github/workflows/`
2. Follow the existing patterns for triggers and jobs
3. Add appropriate secrets and permissions

### Modifying Existing Workflows
- Update Node.js/Python versions in strategy matrices
- Add or remove linting tools
- Configure additional security scanners
- Customize deployment targets

## Best Practices

1. **Fail Fast**: Configure workflows to fail quickly on errors
2. **Caching**: Use action caching for dependencies
3. **Parallelization**: Run jobs in parallel when possible
4. **Security**: Never commit secrets to repository
5. **Monitoring**: Monitor workflow runs and fix failures promptly

## Troubleshooting

### Common Issues

1. **Workflow Timeouts**: Increase timeout values or optimize build process
2. **Permission Errors**: Check repository settings and workflow permissions
3. **Cache Issues**: Clear action caches or update cache keys
4. **Secret Access**: Verify secrets are properly configured

### Debugging

1. Enable debug logging: Add `ACTIONS_STEP_DEBUG: true` to env
2. Use `actions/cache@v4` for dependency caching
3. Check workflow logs for detailed error messages
4. Validate YAML syntax before committing

## Integration with Claude Code

These workflows are designed to work with Claude Code projects:

- Support for MCP servers and Docker containers
- Claude CLI integration and updates
- Context management file validation
- Custom command testing
- Hook script validation

## Contributing

When adding new workflows:
1. Test in a fork first
2. Follow existing naming conventions
3. Add appropriate documentation
4. Include error handling
5. Consider security implications