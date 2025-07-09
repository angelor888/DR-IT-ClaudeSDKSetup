# Git Worktree Multi-Agent System

I'll help you set up and manage Git worktrees for parallel Claude Code operations.

## Available Commands

### `/worktree create <feature-name>`
Creates a new Git worktree for isolated development:
- Creates worktree directory structure
- Sets up isolated branch
- Configures agent-specific environment

### `/worktree list`
Shows all active worktrees and their status:
- Active worktrees and branches
- Agent assignments
- Sync status

### `/worktree sync <source> <target>`
Synchronizes changes between worktrees:
- Intelligent merge conflict resolution
- Preserves agent-specific work
- Maintains branch history

### `/worktree merge <feature-name>`
Merges completed worktree back to main:
- Conflict-free merging
- Cleanup of temporary branches
- Progress tracking

### `/worktree cleanup <feature-name>`
Removes completed worktree:
- Cleans up directories
- Removes temporary branches
- Archives work history

## Usage Examples

```bash
# Create new worktree for UI iteration
/worktree create ui-redesign

# List all active worktrees
/worktree list

# Sync changes from main to feature branch
/worktree sync main ui-redesign

# Merge completed work back
/worktree merge ui-redesign

# Clean up after completion
/worktree cleanup ui-redesign
```

## Directory Structure

```
project/                    # Main project directory
project-worktrees/         # Worktree container
├── ui-redesign/           # Feature worktree
├── api-refactor/          # Another feature worktree
└── bug-fixes/             # Bug fix worktree
```

## Agent Coordination

Each worktree operates independently with:
- Separate Claude Code instance
- Individual branch and commit history
- Isolated file changes
- Cross-worktree communication when needed

Processing your worktree command: $ARGUMENTS