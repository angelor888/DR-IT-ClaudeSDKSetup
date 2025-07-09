# Claude Multi-Computer Sync - Quick Reference

## 🚀 Mac Mini Setup (One Time)
```bash
cd ~/Projects
git clone https://github.com/angelor888/DR-IT-ClaudeSDKSetup.git
cd DR-IT-ClaudeSDKSetup
./scripts/master-claude-install.sh

# Transfer tokens securely from laptop
./scripts/secure-token-manager.sh import
# OR manually copy: scp laptop:~/.config/claude/environment ~/.config/claude/environment
```

## 📅 Daily Use

### Morning (5 seconds)
```bash
~/Projects/DR-IT-ClaudeSDKSetup/scripts/morning-claude-start.sh
```

### Evening (10 seconds)
```bash
cd ~/Projects/DR-IT-ClaudeSDKSetup
./scripts/sync-to-repo.sh
git push
```

## 🔑 Token Management
```bash
# Check what's configured
./scripts/secure-token-manager.sh check

# Export tokens (on source computer)
./scripts/secure-token-manager.sh export

# Import tokens (on target computer)
./scripts/secure-token-manager.sh import
```

## 🆘 Troubleshooting
```bash
# Claude not found
npm install -g @anthropic-ai/claude-code@latest

# Aliases not working
source ~/.config/claude/shell-integration.sh

# Full reinstall
./scripts/master-claude-install.sh
```

## 📱 Quick Aliases
- `claude-init` - Initialize new project
- `claude-plan` - Enter plan mode
- `claude-checkpoint` - Save git checkpoint
- `claude-qa` - Run quality checks
- `claude-help` - Show all commands

---
**Pro Tip**: Add alias to ~/.zshrc for even faster morning startup:
```bash
alias morning='~/Projects/DR-IT-ClaudeSDKSetup/scripts/morning-claude-start.sh'
```