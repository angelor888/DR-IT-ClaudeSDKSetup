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
<!-- This section will be automatically updated by the memory watch task --># [2025-07-08 16:41] Test memory entry
