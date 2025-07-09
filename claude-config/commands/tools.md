# Tools Command - Inspect Available Claude Code Tools

List and inspect all available Claude Code tools with their capabilities and usage.

## Available Tools

### Core Tools
- **Bash** - Execute shell commands with safety checks
- **Read** - Read file contents with security validation
- **Write** - Create new files with permission checks
- **Edit** - Modify existing files with change tracking
- **MultiEdit** - Perform multiple file edits atomically
- **Glob** - Fast file pattern matching
- **Grep** - Content search with regex support
- **LS** - Directory listing with permissions

### Communication Tools
- **WebFetch** - Fetch and process web content
- **WebSearch** - Search the web for information
- **TodoWrite** - Task management and tracking

### Advanced Tools
- **Task** - Launch sub-agents for parallel processing
- **NotebookRead** - Read Jupyter notebook files
- **NotebookEdit** - Edit Jupyter notebook cells

## Tool Safety Status

### ✅ Safe Tools (Always Allowed)
- Read, LS, Glob, Grep, WebFetch, WebSearch
- NotebookRead, TodoWrite

### ⚠️ Monitored Tools (Safety Checked)
- Bash (dangerous command detection)
- Write, Edit, MultiEdit (sensitive file protection)

### 🛡️ Protected Operations
- System file modification blocked
- Dangerous commands (rm -rf, dd, etc.) blocked
- Sensitive file access (SSH keys, credentials) logged

## Current Configuration

**Safety Hooks**: ✅ Active
**Logging**: ✅ Enhanced metadata capture
**Voice Notifications**: ✅ Enabled
**Parallel Processing**: ✅ Sub-agent coordination

## Usage Examples

```bash
# Check tool permissions
claude -p "What tools are available?"

# Inspect specific tool
claude -p "Show me the capabilities of the Bash tool"

# View recent tool usage
cat ~/.config/claude/logs/tool-metadata.jsonl | tail -10
```

## Hook Status

| Hook | Status | Purpose |
|------|--------|---------|
| PreToolUse | ✅ Active | Safety validation |
| PostToolUse | ✅ Active | Logging & metrics |
| Notification | ✅ Active | Voice & visual alerts |
| SubAgentStop | ✅ Active | Parallel coordination |
| Stop | ✅ Active | Conversation logging |

## Log Files

- `~/.config/claude/logs/tool-invocations.log` - Tool execution log
- `~/.config/claude/logs/tool-metadata.jsonl` - Structured metadata
- `~/.config/claude/logs/safety-blocks.log` - Blocked operations
- `~/.config/claude/logs/performance-metrics.log` - Timing data

For more information, check the documentation at: https://docs.anthropic.com/en/docs/claude-code