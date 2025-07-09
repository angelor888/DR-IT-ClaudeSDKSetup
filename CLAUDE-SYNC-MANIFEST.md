# Claude Multi-Computer Sync Manifest

## Overview
This document tracks all Claude configurations that need to be synchronized across multiple computers (Mac mini and laptop).

## Configuration Files to Sync

### 1. Core Configuration (`~/.config/claude/`)
- **settings.json** - Main Claude settings
- **shell-integration.sh** - Shell aliases and functions
- **mode-config.json** - Plan mode and other mode settings
- **safe-mode.json** - Safety configurations
- **multi-computer-sync.json** - Multi-computer sync settings
- **worktrees.json** - Git worktree configurations
- **permissions-cache.json** - Cached permissions (exclude from sync)

### 2. Scripts Directory (`~/.config/claude/scripts/`)
All scripts need to be synced:
- auto-update.sh
- claude-audio-notifications.sh
- claude-clipboard-to-file.sh
- claude-design-iterate.sh
- claude-ide-integration.sh
- claude-mode-manager.sh
- claude-safe-mode.sh
- claude-template-manager.sh
- claude-workflow-integration.sh
- claude-workflow-test.sh
- claude-worktree.sh
- memory-watch.sh
- monitor-services.sh
- validate-workflow-setup.sh

### 3. Templates (`~/.config/claude/templates/`)
- CLAUDE-default.md
- CLAUDE-nodejs.md
- CLAUDE-python.md
- CLAUDE-react.md

### 4. Commands (`~/.config/claude/commands/`)
- checkpoint.md
- design-iterate.md
- docs.md
- ide.md
- model-switch.md
- parallel.md
- plan.md
- qa.md
- tools.md
- worktree.md

### 5. Hooks (`~/.config/claude/hooks/`)
All subdirectories and hooks:
- notification-hook.sh
- post-run-hook.sh
- pre-run-hook.sh
- stop-hook.sh
- sub-agent-stop-hook.sh
- validate-safety.sh
- coordination/sub-agent-stop-hook.sh
- logging/enhanced-post-tool-use.sh
- notifications/notification-hook.sh
- safety/pre-tool-use-safety.sh

### 6. SDK Examples (`~/.config/claude/sdk-examples/`)
Exclude node_modules and venv, but sync:
- Python examples (*.py)
- TypeScript examples (*.ts)
- Configuration files (package.json, tsconfig.json, etc.)
- Documentation (README.md, SECURITY.md)
- Setup scripts (setup-env.sh, rotate-tokens.sh)

### 7. Other Configurations
- **audio/audio-config.json** - Audio notification settings
- **clipboard/clipboard-config.json** - Clipboard integration
- **ide/file-context.json** - IDE integration settings

## Files to Exclude from Sync (Sensitive/Local)

1. **environment** - Contains API keys and tokens
2. **environment.backup.*** - Backup files with tokens
3. **logs/** - Local log files
4. **permissions-cache.json** - Machine-specific permissions
5. **node_modules/** - Can be reinstalled
6. **venv/** - Python virtual environments
7. **.DS_Store** - macOS metadata

## Shell Integration Files

### In Home Directory
1. **~/.zshrc** additions - Claude aliases and PATH
2. **~/.bash_profile** additions (if using bash)

## NPM Global Packages
- @anthropic-ai/claude-code@latest
- Other global tools referenced in scripts

## Project Repository
- **DR-IT-ClaudeSDKSetup** - Main repository with all setup scripts
- Contains MCP server configurations
- OAuth setup scripts
- Documentation

## Sync Strategy

### Method 1: Direct File Copy (Recommended)
```bash
# From source computer
rsync -av --exclude-from=sync-exclude.txt ~/.config/claude/ target:~/.config/claude/
```

### Method 2: Git Repository
Store configs in DR-IT-ClaudeSDKSetup repo under `claude-config/` directory

### Method 3: Symlinks
Link config files to repo for automatic sync with git pull/push

## Daily Sync Workflow

### Morning
1. `git pull` in DR-IT-ClaudeSDKSetup
2. Run `sync-from-repo.sh` to update local configs
3. Source shell integration: `source ~/.config/claude/shell-integration.sh`

### Evening
1. Run `sync-to-repo.sh` to backup configs
2. `git add`, `git commit`, `git push`

## Verification Checklist
- [ ] Claude command works
- [ ] All aliases available (claude-init, claude-plan, etc.)
- [ ] Templates load correctly
- [ ] Hooks execute properly
- [ ] SDK examples run
- [ ] Memory watch active
- [ ] Audio notifications work
- [ ] Safe mode functions

## Notes
- Always test on non-critical project first
- Keep environment file separate and secure
- Use 1Password or similar for token management
- Regular backups before major changes