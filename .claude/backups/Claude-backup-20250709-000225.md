# DR-IT-ClaudeSDKSetup Project Context

## Project Summary
This repository provides comprehensive setup automation for Claude SDK, MCP services, and development environment configuration following DuetRight's standards. It includes automated installation scripts, Docker-based MCP services, SDK examples, and a complete development toolchain setup.

## Critical Context

### Database Schemas
This project does not include database schemas directly, but integrates with:
- PostgreSQL MCP service (connection via POSTGRES_CONNECTION_STRING)
- Redis MCP service (connection via REDIS_CONNECTION_STRING)
- SQLite MCP service (local database at ~/.config/claude/databases/local.db)

### Key Business Rules & Domain Constraints
1. **Naming Convention**: All SOPs must follow format: `DR-SOP-<DomainCode>-<ShortDescriptor>-v<Major.Minor>-<YYYYMMDD>`
2. **Security**: API keys must never be committed to version control
3. **File Permissions**: Sensitive files (.env, API keys) must have 600 permissions
4. **Auto-updates**: Daily at 2 AM via LaunchAgent on macOS
5. **Docker Services**: All MCP services run in containers with health monitoring

### Coding Style Guides & Lint Configs
- **Shell Scripts**: Bash with strict mode (`set -euo pipefail`)
- **Python**: PEP 8 compliant, using virtual environments
- **TypeScript**: Strict mode enabled, ESM modules
- **Documentation**: Markdown with clear headers and code blocks
- **Git Commits**: Conventional commits with Co-Authored-By for Claude

### External Documentation Links
- [Anthropic Documentation](https://docs.anthropic.com)
- [MCP Protocol Spec](https://modelcontextprotocol.io)
- [Docker Documentation](https://docs.docker.com)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)

## Architecture Overview
```
DR-IT-ClaudeSDKSetup/
├── configs/          # Configuration files for services
├── scripts/          # Automation and setup scripts
├── sdk-examples/     # Python and TypeScript examples
├── SOPs/            # Standard Operating Procedures
├── docs/            # Additional documentation
└── tests/           # Test suites (to be implemented)
```

## Key Integration Points
- **Claude CLI**: Global npm package @anthropic-ai/claude-code
- **MCP Services**: Docker containers for filesystem, memory, puppeteer, etc.
- **Development Tools**: Node.js v22+, Python uv, Bun, n8n
- **Shell Integration**: Custom aliases and functions in ~/.config/claude/shell-integration.sh

## Learned Facts
- Environment successfully tested on Mac mini with Darwin 24.6.0
- Node.js managed via nvm for version flexibility
- Bun runtime available as alternative to npm
- MCP servers configured: filesystem, memory, sequentialthinking, playwright

### July 9, 2025 - MCP Ecosystem Expansion
- **Major Achievement**: Expanded from 19 to 26 MCP servers (271% total growth from original 7)
- **Custom Development**: Built 4 production MCP servers (SendGrid, Jobber, Matterport, QuickBooks)
- **Authentication Framework**: Complete environment setup for 25 services requiring auth
- **Slack Integration**: Bot operational with message posting and pinning capabilities
- **Business Coverage**: Full lifecycle automation from leads to payments
- **Testing**: Comprehensive validation suite confirms all systems operational

### Technical Patterns Established
- **MCP Architecture**: ES modules with `@modelcontextprotocol/sdk` v1.15.0
- **Custom Server Pattern**: Consistent tool handler implementation
- **Environment Management**: Centralized auth via `~/.config/claude/environment`
- **Service Discovery**: NPM search strategy for existing vs custom development
- **Git Workflow**: Conventional commits with Claude co-authorship

### Next Phase Ready
- **Authentication Setup**: Framework complete, tokens pending for 25 servers
- **Slack Bot**: Operational in #it-report channel with proper permissions
- **Documentation**: Comprehensive guides and learnings captured
- **Repository**: All work committed and pushed to GitHub

<!-- This section will be automatically updated by the memory watch task -->
