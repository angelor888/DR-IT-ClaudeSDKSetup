#!/bin/bash
#
# Claude Code Workflow Integration Script
# Provides seamless terminal integration and workflow shortcuts
#

# Claude Code aliases for enhanced workflow
alias c='claude'
alias cc='claude --continue'
alias cr='claude --resume'
alias cp='claude -p'
alias cplan='claude "Please start in plan mode and provide a detailed execution plan"'
alias cthink='claude "Think carefully about this and provide an extended analysis"'
alias cinit='claude "/init"'
alias cmemory='claude "/memory"'
alias ctools='claude "/tools"'

# Project initialization with Claude Code
function claude-init() {
    local project_name="${1:-$(basename $(pwd))}"
    echo "🚀 Initializing Claude Code workspace for: $project_name"
    
    # Use template manager to create appropriate CLAUDE.md
    if [ ! -f "./CLAUDE.md" ]; then
        source ~/.config/claude/scripts/claude-template-manager.sh
        local project_type=$(detect_project_type "$(pwd)")
        echo "📋 Detected project type: $project_type"
        
        create_claude_md "$project_type" "$(pwd)"
    else
        echo "📋 CLAUDE.md already exists"
        echo "💡 Use 'claude-update-template' to refresh with latest template"
    fi
    
    # Initialize Git if not already initialized
    if [ ! -d ".git" ]; then
        git init
        echo "✅ Initialized Git repository"
    fi
    
    # Start Claude Code in the project
    echo "🤖 Starting Claude Code..."
    claude "I'm working in the $project_name project. Please review the CLAUDE.md file and help me understand the project structure and how I can assist with development."
}

# Quick context addition to CLAUDE.md
function claude-context() {
    local context="$1"
    if [ -z "$context" ]; then
        echo "Usage: claude-context 'Your context or instruction'"
        return 1
    fi
    
    if [ ! -f "./CLAUDE.md" ]; then
        echo "❌ No CLAUDE.md file found. Run claude-init first."
        return 1
    fi
    
    # Use template manager for consistent context addition
    source ~/.config/claude/scripts/claude-template-manager.sh
    add_context_to_claude_md "$context" "$(pwd)"
    
    echo "💡 Consider running: claude 'Please review the updated CLAUDE.md'"
}

# Update CLAUDE.md template
function claude-update-template() {
    source ~/.config/claude/scripts/claude-template-manager.sh
    update_claude_md "$(pwd)"
}

# Git checkpoint with Claude Code integration
function claude-checkpoint() {
    local message="${1:-Checkpoint: Claude Code assisted changes}"
    
    # Check if there are changes to commit
    if ! git diff --quiet --exit-code || ! git diff --cached --quiet --exit-code; then
        git add -A
        git commit -m "$message"
        echo "✅ Created Git checkpoint: $message"
        echo "💡 Use 'git reset --soft HEAD~1' to undo if needed"
    else
        echo "📋 No changes to checkpoint"
    fi
}

# Quick project switching with Claude Code context
function claude-switch() {
    local project_path="$1"
    if [ -z "$project_path" ]; then
        echo "Usage: claude-switch /path/to/project"
        return 1
    fi
    
    if [ ! -d "$project_path" ]; then
        echo "❌ Directory does not exist: $project_path"
        return 1
    fi
    
    cd "$project_path"
    echo "📁 Switched to: $(pwd)"
    
    # Check for CLAUDE.md and start Claude Code with context
    if [ -f "./CLAUDE.md" ]; then
        echo "📋 Found CLAUDE.md - starting Claude Code with project context"
        claude "I've switched to the $(basename $(pwd)) project. Please review the CLAUDE.md file and help me understand how to work effectively in this codebase."
    else
        echo "⚠️  No CLAUDE.md found. Consider running claude-init"
        claude "I've switched to the $(basename $(pwd)) project. Can you help me understand the structure and create a CLAUDE.md file?"
    fi
}

# Enhanced Claude Code execution with plan mode preference
function claude-plan() {
    local request="$*"
    if [ -z "$request" ]; then
        echo "Usage: claude-plan 'Your request'"
        return 1
    fi
    
    claude "PLAN MODE: $request

Please start by creating a detailed execution plan before making any changes. Show me:
1. Understanding of the request
2. Detailed step-by-step plan
3. Files that will be affected
4. Potential risks or considerations
5. Expected outcomes

Wait for my approval before executing the plan."
}

# Multi-project context aggregation
function claude-multi() {
    local additional_paths="$*"
    if [ -z "$additional_paths" ]; then
        echo "Usage: claude-multi /path/to/project1 /path/to/project2"
        return 1
    fi
    
    local context_summary="/tmp/claude-multi-context-$$.md"
    echo "# Multi-Project Context" > "$context_summary"
    echo "**Primary Project**: $(pwd)" >> "$context_summary"
    echo "**Generated**: $(date)" >> "$context_summary"
    echo "" >> "$context_summary"
    
    # Add current project context
    if [ -f "./CLAUDE.md" ]; then
        echo "## Primary Project ($(basename $(pwd)))" >> "$context_summary"
        cat "./CLAUDE.md" >> "$context_summary"
        echo "" >> "$context_summary"
    fi
    
    # Add additional project contexts
    for path in $additional_paths; do
        if [ -d "$path" ] && [ -f "$path/CLAUDE.md" ]; then
            echo "## Additional Project ($(basename $path))" >> "$context_summary"
            echo "**Path**: $path" >> "$context_summary"
            cat "$path/CLAUDE.md" >> "$context_summary"
            echo "" >> "$context_summary"
        else
            echo "⚠️  No CLAUDE.md found in: $path"
        fi
    done
    
    echo "📋 Multi-project context prepared"
    claude "I'm working across multiple projects. Please review this multi-project context file: $context_summary

Help me understand the relationships between these projects and how I can work effectively across them."
}

# Web documentation integration
function claude-docs() {
    local url="$1"
    local context="${2:-Please analyze this documentation}"
    
    if [ -z "$url" ]; then
        echo "Usage: claude-docs 'https://docs.example.com' 'Optional context'"
        return 1
    fi
    
    claude "Please fetch and analyze the latest documentation from: $url

Context: $context

Use this documentation to help with my current project and keep it as reference for future questions."
}

# Quality assurance trigger
function claude-qa() {
    local scope="${1:-recent changes}"
    
    claude "Please perform a comprehensive quality assurance review of $scope:

1. **Code Quality Review**:
   - Check for potential bugs and edge cases
   - Verify error handling and input validation
   - Review performance implications
   - Ensure code follows best practices

2. **Testing Analysis**:
   - Identify areas that need testing
   - Suggest test cases for critical functionality
   - Check for potential integration issues

3. **Documentation Review**:
   - Verify code is properly documented
   - Check if CLAUDE.md needs updates
   - Ensure commit messages are clear

4. **Security Considerations**:
   - Review for potential security vulnerabilities
   - Check for exposed sensitive data
   - Validate input sanitization

Please provide a detailed assessment and recommendations."
}

# Function to add this script to shell startup files
function install-claude-integration() {
    local shell_rc=""
    case "$SHELL" in
        */bash) shell_rc="$HOME/.bashrc" ;;
        */zsh) shell_rc="$HOME/.zshrc" ;;
        *) echo "Unsupported shell: $SHELL"; return 1 ;;
    esac
    
    local integration_line="source ~/.config/claude/scripts/claude-workflow-integration.sh"
    
    if ! grep -q "$integration_line" "$shell_rc"; then
        echo "" >> "$shell_rc"
        echo "# Claude Code Workflow Integration" >> "$shell_rc"
        echo "$integration_line" >> "$shell_rc"
        echo "✅ Added Claude Code integration to $shell_rc"
        echo "💡 Run 'source $shell_rc' or restart your terminal"
    else
        echo "📋 Claude Code integration already installed in $shell_rc"
    fi
}

# Show available commands
function claude-help() {
    cat <<EOF
🤖 Claude Code Workflow Integration Commands

Basic Commands:
  c, cc, cr, cp, cplan, cthink, cinit, cmemory, ctools

Project Management:
  claude-init [name]           Initialize project with CLAUDE.md
  claude-context 'text'        Add context to CLAUDE.md
  claude-switch /path          Switch to project with context
  claude-multi /path1 /path2   Work across multiple projects

Development Workflow:
  claude-plan 'request'        Start with detailed execution plan
  claude-checkpoint ['msg']    Create Git checkpoint
  claude-qa ['scope']          Run quality assurance review
  claude-docs 'url' ['ctx']    Fetch and analyze documentation

Setup:
  install-claude-integration   Add to shell startup
  claude-help                  Show this help

Examples:
  claude-init my-app
  claude-plan 'Add user authentication'
  claude-context 'Use React hooks, prefer TypeScript'
  claude-checkpoint 'Added login component'
  claude-qa 'authentication module'
EOF
}

echo "🤖 Claude Code Workflow Integration Loaded"
echo "💡 Run 'claude-help' to see available commands"