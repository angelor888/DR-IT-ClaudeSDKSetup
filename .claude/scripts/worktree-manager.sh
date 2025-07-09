#!/bin/bash

# Claude Code Worktree Manager
# Manages parallel Git worktrees for Claude agent operations

PROJECT_NAME="DR-SETUP-DEV-ClaudeSDKEnvironment-v1.0-20250708"
WORKTREE_DIR="../${PROJECT_NAME}-worktrees"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_help() {
    echo -e "${BLUE}Claude Code Worktree Manager${NC}"
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  list          List all worktrees"
    echo "  create <name> Create new worktree with feature branch"
    echo "  switch <name> Switch to existing worktree"
    echo "  remove <name> Remove worktree and branch"
    echo "  claude <name> Start Claude Code in specific worktree"
    echo "  status        Show status of all worktrees"
    echo ""
    echo "Examples:"
    echo "  $0 create ui-improvements"
    echo "  $0 claude oauth-extensions"
    echo "  $0 switch mcp-enhancements"
}

list_worktrees() {
    echo -e "${BLUE}📁 Available Worktrees:${NC}"
    git worktree list | while read line; do
        if [[ $line == *"[main]"* ]]; then
            echo -e "${GREEN}  • $line${NC}"
        else
            echo -e "${YELLOW}  • $line${NC}"
        fi
    done
}

create_worktree() {
    local name=$1
    if [[ -z "$name" ]]; then
        echo -e "${RED}Error: Please provide a name for the worktree${NC}"
        return 1
    fi
    
    local branch_name="feature/$name"
    local worktree_path="$WORKTREE_DIR/$name"
    
    echo -e "${BLUE}Creating worktree: $name${NC}"
    git worktree add -b "$branch_name" "$worktree_path"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Worktree created successfully!${NC}"
        echo -e "${YELLOW}Path: $worktree_path${NC}"
        echo -e "${YELLOW}Branch: $branch_name${NC}"
        echo ""
        echo -e "${BLUE}To start Claude Code in this worktree:${NC}"
        echo -e "${YELLOW}  cd $worktree_path && claude${NC}"
        echo -e "${YELLOW}  # or use: $0 claude $name${NC}"
    else
        echo -e "${RED}❌ Failed to create worktree${NC}"
        return 1
    fi
}

switch_worktree() {
    local name=$1
    if [[ -z "$name" ]]; then
        echo -e "${RED}Error: Please provide a worktree name${NC}"
        return 1
    fi
    
    local worktree_path="$WORKTREE_DIR/$name"
    
    if [[ -d "$worktree_path" ]]; then
        echo -e "${BLUE}Switching to worktree: $name${NC}"
        cd "$worktree_path"
        echo -e "${GREEN}✅ Now in worktree: $name${NC}"
        echo -e "${YELLOW}Path: $(pwd)${NC}"
        # Start a new shell in the worktree
        exec bash
    else
        echo -e "${RED}❌ Worktree '$name' not found${NC}"
        return 1
    fi
}

remove_worktree() {
    local name=$1
    if [[ -z "$name" ]]; then
        echo -e "${RED}Error: Please provide a worktree name${NC}"
        return 1
    fi
    
    local worktree_path="$WORKTREE_DIR/$name"
    local branch_name="feature/$name"
    
    echo -e "${YELLOW}Removing worktree: $name${NC}"
    
    # Remove worktree
    git worktree remove "$worktree_path" --force
    
    # Delete branch
    git branch -D "$branch_name" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Worktree and branch removed successfully${NC}"
    else
        echo -e "${RED}❌ Failed to remove worktree${NC}"
        return 1
    fi
}

start_claude() {
    local name=$1
    if [[ -z "$name" ]]; then
        echo -e "${RED}Error: Please provide a worktree name${NC}"
        return 1
    fi
    
    local worktree_path="$WORKTREE_DIR/$name"
    
    if [[ -d "$worktree_path" ]]; then
        echo -e "${BLUE}Starting Claude Code in worktree: $name${NC}"
        cd "$worktree_path"
        echo -e "${GREEN}✅ Claude Code starting in: $(pwd)${NC}"
        claude
    else
        echo -e "${RED}❌ Worktree '$name' not found${NC}"
        return 1
    fi
}

show_status() {
    echo -e "${BLUE}📊 Worktree Status Report:${NC}"
    echo ""
    
    git worktree list | while read line; do
        local path=$(echo $line | cut -d' ' -f1)
        local branch=$(echo $line | grep -o '\[.*\]' | tr -d '[]')
        
        if [[ -d "$path" ]]; then
            cd "$path"
            local status=$(git status --porcelain | wc -l | tr -d ' ')
            local commits=$(git rev-list --count HEAD ^main 2>/dev/null || echo "0")
            
            echo -e "${YELLOW}Branch: $branch${NC}"
            echo -e "  Path: $path"
            echo -e "  Changes: $status file(s) modified"
            echo -e "  Commits ahead: $commits"
            echo ""
        fi
    done
}

# Main command handling
case "$1" in
    "list")
        list_worktrees
        ;;
    "create")
        create_worktree "$2"
        ;;
    "switch")
        switch_worktree "$2"
        ;;
    "remove")
        remove_worktree "$2"
        ;;
    "claude")
        start_claude "$2"
        ;;
    "status")
        show_status
        ;;
    "help"|"-h"|"--help"|"")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac