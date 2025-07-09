#!/bin/bash
# Claude Code Git Worktree Management System
# Advanced workflow for parallel Claude Code operations

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_CONFIG_DIR="$HOME/.config/claude"
WORKTREE_CONFIG="$CLAUDE_CONFIG_DIR/worktrees.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Initialize worktree configuration
init_worktree_config() {
    if [ ! -f "$WORKTREE_CONFIG" ]; then
        cat > "$WORKTREE_CONFIG" << 'EOF'
{
  "version": "1.0.0",
  "worktrees": {},
  "settings": {
    "defaultBranch": "main",
    "worktreePrefix": "claude-",
    "maxWorktrees": 8,
    "autoCleanup": true,
    "syncOnCreate": true
  }
}
EOF
        log "Initialized worktree configuration"
    fi
}

# Get project root directory
get_project_root() {
    local current_dir="$(pwd)"
    while [ "$current_dir" != "/" ]; do
        if [ -d "$current_dir/.git" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    error "Not in a Git repository"
    return 1
}

# Get project name from directory
get_project_name() {
    local project_root="$1"
    basename "$project_root"
}

# Get worktree directory
get_worktree_dir() {
    local project_root="$1"
    local project_name="$(get_project_name "$project_root")"
    echo "$(dirname "$project_root")/${project_name}-worktrees"
}

# Create new worktree
create_worktree() {
    local feature_name="$1"
    local project_root
    
    if ! project_root="$(get_project_root)"; then
        return 1
    fi
    
    local project_name="$(get_project_name "$project_root")"
    local worktree_dir="$(get_worktree_dir "$project_root")"
    local feature_dir="$worktree_dir/$feature_name"
    local branch_name="claude-$feature_name"
    
    # Check if worktree already exists
    if [ -d "$feature_dir" ]; then
        error "Worktree '$feature_name' already exists at $feature_dir"
        return 1
    fi
    
    # Create worktree directory if it doesn't exist
    mkdir -p "$worktree_dir"
    
    # Create the worktree and branch
    log "Creating worktree '$feature_name' with branch '$branch_name'"
    
    cd "$project_root"
    
    # Create new branch from current branch
    local current_branch
    current_branch="$(git branch --show-current)"
    
    if ! git worktree add -b "$branch_name" "$feature_dir" "$current_branch"; then
        error "Failed to create worktree"
        return 1
    fi
    
    # Update worktree configuration
    update_worktree_config "$feature_name" "$feature_dir" "$branch_name" "active"
    
    # Create worktree-specific configuration
    create_worktree_config "$feature_dir" "$feature_name" "$project_name"
    
    log "✅ Worktree '$feature_name' created successfully"
    info "📁 Location: $feature_dir"
    info "🌳 Branch: $branch_name"
    info "🔄 To switch: cd $feature_dir"
    
    # Voice notification if enabled
    if command -v say &> /dev/null; then
        say "Worktree $feature_name created successfully" &
    fi
}

# List all worktrees
list_worktrees() {
    local project_root
    
    if ! project_root="$(get_project_root)"; then
        return 1
    fi
    
    echo -e "${BLUE}📋 Active Git Worktrees${NC}"
    echo "================================="
    
    # Get worktrees from git
    cd "$project_root"
    git worktree list --porcelain | while read -r line; do
        if [[ "$line" =~ ^worktree ]]; then
            local worktree_path="${line#worktree }"
            local worktree_name="$(basename "$worktree_path")"
            echo -e "${GREEN}📁 $worktree_name${NC}"
            echo "   Path: $worktree_path"
        elif [[ "$line" =~ ^branch ]]; then
            local branch_name="${line#branch refs/heads/}"
            echo "   Branch: $branch_name"
        elif [[ "$line" =~ ^HEAD ]]; then
            local commit_hash="${line#HEAD }"
            echo "   Commit: ${commit_hash:0:8}"
            echo ""
        fi
    done
    
    # Show summary
    local worktree_count
    worktree_count="$(git worktree list | wc -l)"
    echo -e "${PURPLE}Total worktrees: $worktree_count${NC}"
}

# Sync worktree with source branch
sync_worktree() {
    local source_branch="${1:-main}"
    local target_worktree="$2"
    
    local project_root
    if ! project_root="$(get_project_root)"; then
        return 1
    fi
    
    local worktree_dir="$(get_worktree_dir "$project_root")"
    local target_dir="$worktree_dir/$target_worktree"
    
    if [ ! -d "$target_dir" ]; then
        error "Worktree '$target_worktree' does not exist"
        return 1
    fi
    
    log "Syncing worktree '$target_worktree' with '$source_branch'"
    
    # Switch to target worktree
    cd "$target_dir"
    
    # Fetch latest changes
    git fetch origin "$source_branch"
    
    # Merge or rebase (configurable)
    if git merge "origin/$source_branch" --no-edit; then
        log "✅ Sync completed successfully"
        update_worktree_config "$target_worktree" "$target_dir" "" "synced"
    else
        warning "⚠️  Merge conflicts detected. Please resolve manually."
        echo "   Run: cd $target_dir && git status"
    fi
}

# Merge worktree back to main
merge_worktree() {
    local feature_name="$1"
    local target_branch="${2:-main}"
    
    local project_root
    if ! project_root="$(get_project_root)"; then
        return 1
    fi
    
    local worktree_dir="$(get_worktree_dir "$project_root")"
    local feature_dir="$worktree_dir/$feature_name"
    local branch_name="claude-$feature_name"
    
    if [ ! -d "$feature_dir" ]; then
        error "Worktree '$feature_name' does not exist"
        return 1
    fi
    
    log "Merging worktree '$feature_name' into '$target_branch'"
    
    # Switch to main project
    cd "$project_root"
    
    # Switch to target branch
    git checkout "$target_branch"
    
    # Pull latest changes
    git pull origin "$target_branch"
    
    # Merge feature branch
    if git merge "$branch_name" --no-edit; then
        log "✅ Merge completed successfully"
        
        # Push changes
        if git push origin "$target_branch"; then
            log "✅ Changes pushed to remote"
        else
            warning "⚠️  Failed to push changes. Please push manually."
        fi
        
        # Update status
        update_worktree_config "$feature_name" "$feature_dir" "$branch_name" "merged"
        
        # Voice notification
        if command -v say &> /dev/null; then
            say "Worktree $feature_name merged successfully" &
        fi
    else
        error "Merge failed. Please resolve conflicts manually."
        return 1
    fi
}

# Cleanup worktree
cleanup_worktree() {
    local feature_name="$1"
    local force="${2:-false}"
    
    local project_root
    if ! project_root="$(get_project_root)"; then
        return 1
    fi
    
    local worktree_dir="$(get_worktree_dir "$project_root")"
    local feature_dir="$worktree_dir/$feature_name"
    local branch_name="claude-$feature_name"
    
    if [ ! -d "$feature_dir" ]; then
        error "Worktree '$feature_name' does not exist"
        return 1
    fi
    
    # Check if there are uncommitted changes
    cd "$feature_dir"
    if [ "$force" != "true" ] && ! git diff --quiet; then
        error "Worktree has uncommitted changes. Use --force to cleanup anyway."
        return 1
    fi
    
    log "Cleaning up worktree '$feature_name'"
    
    # Switch back to main project
    cd "$project_root"
    
    # Remove worktree
    if git worktree remove "$feature_dir"; then
        log "✅ Worktree removed"
    else
        error "Failed to remove worktree"
        return 1
    fi
    
    # Delete branch
    if git branch -D "$branch_name"; then
        log "✅ Branch '$branch_name' deleted"
    else
        warning "⚠️  Failed to delete branch '$branch_name'"
    fi
    
    # Remove from configuration
    remove_worktree_config "$feature_name"
    
    log "✅ Cleanup completed"
}

# Update worktree configuration
update_worktree_config() {
    local name="$1"
    local path="$2"
    local branch="$3"
    local status="$4"
    
    init_worktree_config
    
    local timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    
    # Update JSON config (simple approach)
    local temp_config="/tmp/worktree_config.json"
    
    if command -v jq &> /dev/null; then
        jq ".worktrees[\"$name\"] = {
            \"path\": \"$path\",
            \"branch\": \"$branch\",
            \"status\": \"$status\",
            \"created\": \"$timestamp\",
            \"lastUpdated\": \"$timestamp\"
        }" "$WORKTREE_CONFIG" > "$temp_config"
        
        mv "$temp_config" "$WORKTREE_CONFIG"
    fi
}

# Remove worktree from configuration
remove_worktree_config() {
    local name="$1"
    
    if [ -f "$WORKTREE_CONFIG" ] && command -v jq &> /dev/null; then
        local temp_config="/tmp/worktree_config.json"
        jq "del(.worktrees[\"$name\"])" "$WORKTREE_CONFIG" > "$temp_config"
        mv "$temp_config" "$WORKTREE_CONFIG"
    fi
}

# Create worktree-specific configuration
create_worktree_config() {
    local worktree_dir="$1"
    local feature_name="$2"
    local project_name="$3"
    
    # Create .claude directory in worktree
    mkdir -p "$worktree_dir/.claude"
    
    # Create worktree-specific Claude.md
    cat > "$worktree_dir/.claude/Claude.md" << EOF
# $project_name - $feature_name Worktree

## Worktree Context
- **Feature**: $feature_name
- **Created**: $(date)
- **Branch**: claude-$feature_name
- **Parent Project**: $project_name

## Task Focus
This worktree is dedicated to: $feature_name

## Important Notes
- This is an isolated worktree - changes here don't affect main project
- Use \`/worktree sync main $feature_name\` to sync with main branch
- Use \`/worktree merge $feature_name\` when ready to merge back
- Use \`/worktree cleanup $feature_name\` to remove this worktree

## Files Modified
[List will be updated as work progresses]

## Progress
- [ ] Initial setup
- [ ] Core implementation
- [ ] Testing
- [ ] Documentation
- [ ] Ready for merge
EOF
    
    # Create worktree-specific commands
    mkdir -p "$worktree_dir/.claude/commands"
    
    cat > "$worktree_dir/.claude/commands/merge-ready.md" << EOF
# Merge Ready Command

I'll prepare this worktree for merging back to main:

1. **Status Check**: Verify all changes are committed
2. **Sync Check**: Ensure we're up-to-date with main
3. **Test Run**: Run any available tests
4. **Documentation**: Update relevant documentation
5. **Merge Preparation**: Create merge commit message

Current worktree: $feature_name
Branch: claude-$feature_name

Processing merge readiness check...
EOF
    
    log "✅ Worktree-specific configuration created"
}

# Main command dispatcher
main() {
    local command="${1:-help}"
    
    case "$command" in
        "create")
            if [ $# -lt 2 ]; then
                error "Usage: claude-worktree create <feature-name>"
                return 1
            fi
            create_worktree "$2"
            ;;
        "list")
            list_worktrees
            ;;
        "sync")
            if [ $# -lt 3 ]; then
                error "Usage: claude-worktree sync <source-branch> <target-worktree>"
                return 1
            fi
            sync_worktree "$2" "$3"
            ;;
        "merge")
            if [ $# -lt 2 ]; then
                error "Usage: claude-worktree merge <feature-name> [target-branch]"
                return 1
            fi
            merge_worktree "$2" "${3:-main}"
            ;;
        "cleanup")
            if [ $# -lt 2 ]; then
                error "Usage: claude-worktree cleanup <feature-name> [--force]"
                return 1
            fi
            cleanup_worktree "$2" "${3:-false}"
            ;;
        "help"|"-h"|"--help")
            echo "Claude Code Git Worktree Management System"
            echo ""
            echo "Usage: claude-worktree <command> [options]"
            echo ""
            echo "Commands:"
            echo "  create <name>           Create new worktree"
            echo "  list                    List all worktrees"
            echo "  sync <source> <target>  Sync worktree with source branch"
            echo "  merge <name> [branch]   Merge worktree back to main"
            echo "  cleanup <name> [--force] Remove worktree"
            echo "  help                    Show this help message"
            echo ""
            echo "Examples:"
            echo "  claude-worktree create ui-redesign"
            echo "  claude-worktree sync main ui-redesign"
            echo "  claude-worktree merge ui-redesign"
            echo "  claude-worktree cleanup ui-redesign"
            ;;
        *)
            error "Unknown command: $command"
            echo "Run 'claude-worktree help' for usage information"
            return 1
            ;;
    esac
}

# Initialize configuration on first run
init_worktree_config

# Run main function
main "$@"