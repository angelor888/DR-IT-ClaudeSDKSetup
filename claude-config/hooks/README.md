# Claude Code Hooks - Modular Architecture

This directory contains a comprehensive set of hooks for Claude Code that provide maximum safety, observability, and efficiency.

## Directory Structure

```
hooks/
├── safety/
│   └── pre-tool-use-safety.sh     # Command blocking and security validation
├── logging/
│   ├── enhanced-post-tool-use.sh  # Structured metadata capture
│   └── generate-log-interfaces.ts # TypeScript interface generation
├── notifications/
│   └── notification-hook.sh       # Voice and visual notifications
├── coordination/
│   └── sub-agent-stop-hook.sh     # Parallel agent management
├── pre-run-hook.sh                # Tool invocation logging (legacy)
├── post-run-hook.sh              # Basic output logging (legacy)
├── stop-hook.sh                  # Conversation logging
└── README.md                     # This file
```

## Hook Types & Purposes

### 🛡️ Safety Hooks (`safety/`)
- **pre-tool-use-safety.sh**: Blocks dangerous commands like `rm -rf`, protects sensitive files
- Validates all tool usage before execution
- Returns JSON responses to block or allow operations
- Logs all security events

### 📊 Logging Hooks (`logging/`)
- **enhanced-post-tool-use.sh**: Captures comprehensive metadata for every tool execution
- **generate-log-interfaces.ts**: Auto-generates TypeScript interfaces from log data
- Creates structured JSONL logs for programmatic analysis
- Tracks performance metrics and timing data

### 🔔 Notification Hooks (`notifications/`)
- **notification-hook.sh**: Sends system and voice notifications
- Different voices for different event types
- Configurable notification preferences
- Supports webhooks for external integration

### ⚡ Coordination Hooks (`coordination/`)
- **sub-agent-stop-hook.sh**: Manages parallel sub-agent execution
- Tracks completion status across multiple agents
- Generates comprehensive summary reports
- Auto-creates TypeScript interfaces for results

## Configuration

Hooks are configured in `~/.config/claude/settings.json`:

```json
{
  "hooks": {
    "enabled": true,
    "preToolUse": {
      "enabled": true,
      "script": "~/.config/claude/hooks/safety/pre-tool-use-safety.sh"
    },
    "postRun": {
      "enabled": true,
      "script": "~/.config/claude/hooks/logging/enhanced-post-tool-use.sh"
    },
    "notification": {
      "enabled": true,
      "script": "~/.config/claude/hooks/notifications/notification-hook.sh"
    }
  }
}
```

## Log Files

All logs are stored in `~/.config/claude/logs/`:

- `tool-invocations.log` - Human-readable tool execution log
- `tool-metadata.jsonl` - Structured metadata for programmatic analysis
- `safety-blocks.log` - Security blocks and violations
- `performance-metrics.log` - Execution timing and performance data
- `notifications.log` - All notification events
- `conversations/` - Complete conversation transcripts
- `sub-agents/` - Parallel agent execution logs

## Voice Notifications

Configure voice settings in `settings.json`:

```json
{
  "notifications": {
    "voiceEnabled": true,
    "voiceForTaskCompletion": true,
    "voiceForErrors": true,
    "voiceForManualIntervention": true
  }
}
```

## Safety Features

### Blocked Commands
- `rm -rf /`, `rm -rf *`, `rm -rf ~`
- `sudo rm -rf`
- `dd of=/dev/`, `mkfs.`
- `chmod -R 000`, `killall -9`
- Fork bombs and command injection patterns
- Curl/wget piped to shell

### Protected Files
- `.env`, `.aws/credentials`
- SSH keys (`id_rsa`, `id_ed25519`)
- System files (`/etc/passwd`, `/etc/shadow`)
- Private keys (`.pem`, `.p12`, `.pfx`)

## Usage

### Check Hook Status
```bash
# View recent tool usage
tail -f ~/.config/claude/logs/tool-invocations.log

# Check safety blocks
tail -f ~/.config/claude/logs/safety-blocks.log

# Monitor notifications
tail -f ~/.config/claude/logs/notifications.log
```

### Generate Interfaces
```bash
# Manual interface generation
~/.config/claude/hooks/logging/generate-log-interfaces.ts ~/.config/claude/logs/tool-metadata.jsonl
```

### Test Safety
```bash
# This will be blocked by safety hook
claude -p "run: rm -rf /tmp/test"
```

## Maintenance

Hooks automatically:
- Clean up old log files (keep last 30)
- Generate TypeScript interfaces every 10 executions
- Rotate status files for parallel agents
- Sanitize sensitive data in all logs

## Troubleshooting

1. **Hooks not running**: Check permissions with `ls -la hooks/*/`
2. **Safety not blocking**: Verify `preToolUse` is enabled in settings
3. **No voice notifications**: Check macOS permissions and `say` command
4. **Missing interfaces**: Ensure Bun is installed for TypeScript execution

## Development

To add new hooks:
1. Create script in appropriate category directory
2. Make executable: `chmod +x script.sh`
3. Update `settings.json` to reference the new hook
4. Test with a simple operation
5. Check logs for proper execution

Each hook receives environment variables and/or stdin data from Claude Code with context about the current operation.