# DR-IT-ClaudeSDKSetup

A comprehensive setup guide and automation for Claude SDK, MCP services, and development environment configuration following DuetRight's standards.

## 📋 Project Overview

This repository documents and automates the complete setup process for:
- Claude SDK (Python & TypeScript)
- MCP (Model Context Protocol) services
- Auto-update systems
- Security configurations
- Development environment optimization

Created: 2025-07-08
Author: DuetRight IT Team

## 🎯 Why This Project Exists

### Problems Solved:
1. **Manual Setup Complexity**: Setting up Claude SDK and MCP services involved numerous manual steps
2. **Lack of Auto-Updates**: No automated system for keeping tools current
3. **Security Concerns**: API keys and tokens needed proper management
4. **Integration Challenges**: Multiple services needed to work together seamlessly

### Benefits Delivered:
- ✅ One-command setup for complete environment
- ✅ Automated daily updates for all components
- ✅ Secure credential management
- ✅ Comprehensive monitoring and health checks
- ✅ Ready-to-use examples and integrations

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Claude Desktop App                      │
├─────────────────────────────────────────────────────────┤
│                    MCP Services Layer                     │
├──────────┬──────────┬──────────┬──────────┬────────────┤
│Filesystem│  Memory  │ Puppeteer│  GitHub  │    ...      │
│  (Docker)│ (Docker) │ (Docker) │ (Docker) │            │
├──────────┴──────────┴──────────┴──────────┴────────────┤
│                    Claude SDK Layer                       │
├────────────────────┬────────────────────────────────────┤
│   Python SDK       │      TypeScript SDK                │
├────────────────────┴────────────────────────────────────┤
│                 Auto-Update System                       │
│            (LaunchAgent + Watchtower)                    │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- macOS (tested on 15.6)
- Homebrew installed
- Docker Desktop running
- GitHub account
- Anthropic API key

### One-Line Installation
```bash
curl -fsSL https://raw.githubusercontent.com/angelor888/DR-IT-ClaudeSDKSetup/main/install.sh | bash
```

### Manual Installation
```bash
# Clone repository
git clone https://github.com/angelor888/DR-IT-ClaudeSDKSetup.git
cd DR-IT-ClaudeSDKSetup

# Run setup
./scripts/setup-all.sh
```

## 📦 What Gets Installed

### 1. Development Toolchain
- **Node.js**: v22+ LTS JavaScript runtime
- **Claude CLI**: Command-line interface for Claude Code
- **Playwright MCP**: Browser automation server
- **Python uv**: Fast Python package manager
- **Bun**: Alternative JavaScript runtime
- **n8n**: Workflow automation platform

### 2. MCP Services (Docker-based)
- **filesystem**: File operations in containers
- **memory**: Persistent knowledge storage
- **puppeteer**: Web browser automation
- **everything**: Multi-purpose utility server
- **github**: GitHub API integration
- **postgres**: Database operations
- **redis**: Caching service
- **slack**: Team communication

### 3. Claude SDK
- Python SDK with virtual environment
- TypeScript/JavaScript SDK
- Example scripts for both languages
- Integration examples with MCP services

### 4. Auto-Update System
- Daily updates at 2 AM via LaunchAgent
- Docker Watchtower for container updates
- Update scripts with logging
- Token rotation utilities

### 5. Security Features
- Encrypted credential storage
- API key rotation scripts
- Git-ignored sensitive files
- Proper file permissions

## 📁 Project Structure

```
DR-IT-ClaudeSDKSetup/
├── README.md                    # This file
├── install.sh                   # Main installation script
├── SOPs/                       # Standard Operating Procedures
│   └── DR-SOP-IT-ClaudeSetup-v1.0-20250708.md
├── scripts/                    # Automation scripts
│   ├── setup-all.sh           # Complete setup script
│   ├── setup-mcp.sh           # MCP services setup
│   ├── setup-sdk.sh           # Claude SDK setup
│   ├── setup-autoupdate.sh    # Auto-update configuration
│   ├── setup-dev-toolchain.sh # Development tools setup
│   ├── verify-installation.sh # Health check script
│   └── verify-toolchain.sh    # Toolchain verification
├── configs/                    # Configuration files
│   ├── docker-compose.yml     # MCP services configuration
│   ├── claude-desktop-config.json
│   ├── shell-integration.sh   # Shell aliases and functions
│   └── .env.example           # Environment template
├── sdk-examples/              # SDK usage examples
│   ├── python/               # Python examples
│   └── typescript/           # TypeScript examples
└── docs/                     # Additional documentation
    ├── SECURITY.md          # Security best practices
    ├── TROUBLESHOOTING.md   # Common issues and solutions
    └── API-PRICING.md       # Cost optimization guide
```

## 🛠️ Components Detail

### MCP Services Configuration

Each MCP service runs in Docker with:
- Automatic restart on failure
- Health monitoring
- Log rotation
- Resource limits

Example service configuration:
```yaml
mcp-filesystem:
  image: mcp-filesystem:latest
  restart: unless-stopped
  volumes:
    - ./projects:/app/projects
  environment:
    - NODE_ENV=production
    - MCP_LOG_LEVEL=info
```

### Claude SDK Setup

#### Python SDK
```python
from anthropic import Anthropic

client = Anthropic()
message = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    messages=[{"role": "user", "content": "Hello!"}]
)
```

#### TypeScript SDK
```typescript
import Anthropic from '@anthropic-ai/sdk';

const anthropic = new Anthropic();
const message = await anthropic.messages.create({
    model: 'claude-3-5-sonnet-20241022',
    messages: [{ role: 'user', content: 'Hello!' }]
});
```

### Auto-Update System

Updates run daily via LaunchAgent:
- Homebrew packages
- npm global packages
- Docker images
- Claude CLI

## 🔧 Configuration

### Environment Variables
```bash
# Required
export ANTHROPIC_API_KEY='sk-ant-...'
export GITHUB_TOKEN='ghp_...'

# Optional
export SLACK_TOKEN='xoxb-...'
export POSTGRES_CONNECTION_STRING='postgresql://...'
```

### Shell Aliases
```bash
claude-update    # Run manual update
claude-logs      # View update logs
mcp-status       # Check service status
claude-py        # Python environment
claude-ts        # TypeScript environment
```

## 📊 Monitoring

### Health Check
```bash
~/.config/claude/scripts/monitor-services.sh
```

### Service Logs
```bash
docker logs mcp-filesystem-enhanced
docker logs mcp-github-enhanced
# etc...
```

### Update History
```bash
cat ~/.config/claude/logs/auto-update-*.log
```

## 🔒 Security

### API Key Management
- Keys stored in environment variables
- Never committed to git
- Rotation reminders configured
- Secure file permissions (600)

### Token Rotation
```bash
~/.config/claude/sdk-examples/rotate-tokens.sh
```

## 📈 Cost Optimization

### API Usage Estimates
- Testing all examples: ~$0.10
- Daily automated tasks: ~$1-5
- Production usage: Monitor via Anthropic console

### Tips:
1. Use Claude Haiku for simple tasks
2. Set appropriate max_tokens
3. Cache responses when possible
4. Monitor usage dashboard regularly

## 🐛 Troubleshooting

### Common Issues

1. **"Credit balance too low"**
   - Add credits at console.anthropic.com

2. **Docker services not starting**
   - Ensure Docker Desktop is running
   - Check logs: `docker logs <container>`

3. **API key not found**
   - Run: `source ~/.zshrc`
   - Verify: `echo $ANTHROPIC_API_KEY`

## 🤝 Contributing

Following DuetRight's SOP standards:
1. Create feature branch
2. Follow naming convention
3. Test thoroughly
4. Submit PR with description

## 📝 License

Proprietary - DuetRight © 2025

## 🙏 Acknowledgments

- Anthropic for Claude SDK
- Docker team for containerization
- Open source community

---

**Repository**: [github.com/angelor888/DR-IT-ClaudeSDKSetup](https://github.com/angelor888/DR-IT-ClaudeSDKSetup)
**Last Updated**: 2025-07-08
**Version**: 1.0.0