# **DR-SOP-IT-ClaudeSetup-v1.0-20250708**

## Standard Operating Procedure

### **Title**
Claude SDK & MCP Services Complete Setup

### **Purpose**
Standardize the installation and configuration of Claude SDK, MCP services, and related development tools to ensure consistent, secure, and maintainable AI-powered development environments across DuetRight.

### **Scope**
Applies to all DuetRight developers, IT staff, and contractors who need to set up or maintain Claude SDK and MCP services on macOS systems.

### **Prerequisites**
- macOS 14.0 or later
- Admin access to the machine
- Homebrew installed
- Docker Desktop installed and running
- GitHub account with appropriate permissions
- Anthropic Console account with API access

### **Procedure**

#### **1. Initial System Preparation**
1.1. Open Terminal
1.2. Verify prerequisites:
```bash
brew --version
docker --version
git --version
```
1.3. If any are missing, install them first

#### **2. Install Base Tools**
2.1. Install required Homebrew packages:
```bash
brew install pipx gh jq
brew install postgresql@16 redis
```
2.2. Install Python virtual environment support:
```bash
pipx ensurepath
```

#### **3. Clone Setup Repository**
3.1. Create projects directory:
```bash
mkdir -p ~/Projects
cd ~/Projects
```
3.2. Clone the setup repository:
```bash
git clone https://github.com/angelor888/DR-IT-ClaudeSDKSetup.git
cd DR-IT-ClaudeSDKSetup
```

#### **4. Configure Environment Variables**
4.1. Copy environment template:
```bash
cp configs/.env.example ~/.env
```
4.2. Edit ~/.env and add:
- ANTHROPIC_API_KEY (from console.anthropic.com)
- GITHUB_TOKEN (from github.com/settings/tokens)
- Other service tokens as needed

#### **5. Run Automated Setup**
5.1. Make scripts executable:
```bash
chmod +x scripts/*.sh
```
5.2. Run complete setup:
```bash
./scripts/setup-all.sh
```
5.3. Follow any prompts for passwords or confirmations

#### **6. Verify Installation**
6.1. Run health check:
```bash
./scripts/verify-installation.sh
```
6.2. Test Claude SDK:
```bash
cd ~/.config/claude/sdk-examples/python
source venv/bin/activate
python test-api.py
```
6.3. Check MCP services:
```bash
docker ps | grep mcp
```

#### **7. Configure Auto-Updates**
7.1. The setup script automatically configures LaunchAgent
7.2. Verify it's loaded:
```bash
launchctl list | grep claude
```
7.3. Updates will run daily at 2 AM

#### **8. Security Configuration**
8.1. Set proper file permissions:
```bash
chmod 600 ~/.env
chmod 600 ~/easy-mcp/.env
```
8.2. Ensure .env files are git-ignored:
```bash
echo ".env" >> ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
```

### **Quality Checks**
- [ ] All Docker containers are running
- [ ] Claude SDK test returns successful response
- [ ] Auto-update LaunchAgent is loaded
- [ ] Environment variables are set
- [ ] File permissions are restrictive (600)
- [ ] No API keys in git history

### **Troubleshooting**

| Issue | Solution |
|-------|----------|
| Docker not running | Start Docker Desktop app |
| API key errors | Verify key in ~/.env and run `source ~/.zshrc` |
| Permission denied | Check file ownership and run `chmod +x` on scripts |
| Container failures | Check logs with `docker logs <container-name>` |
| Credit balance low | Add credits at console.anthropic.com |

### **Maintenance**
- Run health check weekly: `~/.config/claude/scripts/monitor-services.sh`
- Rotate API keys quarterly: `~/.config/claude/sdk-examples/rotate-tokens.sh`
- Update Docker images monthly: `docker-compose pull`
- Review logs for errors: `claude-logs`

### **References**
- [Anthropic Documentation](https://docs.anthropic.com)
- [MCP Protocol Spec](https://modelcontextprotocol.io)
- [Docker Documentation](https://docs.docker.com)
- Internal: DR-SOP-IT-Security-v2.1

### **Revision History**
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| v1.0 | 2025-07-08 | IT Team | Initial release |

### **Approval**
- **Created by**: DuetRight IT Team
- **Reviewed by**: [Pending]
- **Approved by**: [Pending]
- **Effective Date**: 2025-07-08