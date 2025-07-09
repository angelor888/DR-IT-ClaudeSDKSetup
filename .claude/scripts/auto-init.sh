#!/bin/bash

# Automated Claude Code /init Command Handler
# Runs when Claude Code starts in new projects to ensure consistent setup

set -euo pipefail

# Configuration
CLAUDE_DIR=".claude"
CLAUDE_MD="Claude.md"
INIT_MARKER="$CLAUDE_DIR/.init-complete"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_message() {
    echo -e "${BLUE}[auto-init] $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[auto-init] $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}[auto-init] $1${NC}" >&2
}

log_error() {
    echo -e "${RED}[auto-init] $1${NC}" >&2
}

# Check if we're in a git repository
is_git_repo() {
    git rev-parse --git-dir >/dev/null 2>&1
}

# Check if this is a new project (no Claude.md or empty/minimal)
is_new_project() {
    if [[ ! -f "$CLAUDE_MD" ]]; then
        return 0
    fi
    
    # Check if Claude.md is minimal (less than 10 lines)
    if [[ $(wc -l < "$CLAUDE_MD") -lt 10 ]]; then
        return 0
    fi
    
    return 1
}

# Check if init has already been run
init_already_complete() {
    [[ -f "$INIT_MARKER" ]]
}

# Create basic project structure
create_project_structure() {
    log_message "Creating project structure..."
    
    # Create essential directories
    mkdir -p "$CLAUDE_DIR"/{logs,backups,settings,templates,sounds}
    
    # Create init marker with timestamp
    cat > "$INIT_MARKER" <<EOF
{
  "init_completed": "$TIMESTAMP",
  "project_root": "$(pwd)",
  "git_repo": $(is_git_repo && echo "true" || echo "false"),
  "claude_version": "$(claude --version 2>/dev/null || echo 'unknown')"
}
EOF
    
    log_success "Project structure created"
}

# Generate intelligent Claude.md based on project analysis
generate_claude_md() {
    log_message "Generating Claude.md..."
    
    local project_name=$(basename "$(pwd)")
    local git_branch="unknown"
    local git_remote="unknown"
    
    if is_git_repo; then
        git_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
        git_remote=$(git remote get-url origin 2>/dev/null || echo "unknown")
    fi
    
    # Analyze project type
    local project_type="General"
    local package_manager="none"
    local framework="none"
    
    if [[ -f "package.json" ]]; then
        project_type="Node.js"
        package_manager="npm"
        if [[ -f "bun.lockb" ]]; then
            package_manager="bun"
        elif [[ -f "yarn.lock" ]]; then
            package_manager="yarn"
        elif [[ -f "pnpm-lock.yaml" ]]; then
            package_manager="pnpm"
        fi
        
        # Detect framework
        if grep -q "next" package.json 2>/dev/null; then
            framework="Next.js"
        elif grep -q "react" package.json 2>/dev/null; then
            framework="React"
        elif grep -q "vue" package.json 2>/dev/null; then
            framework="Vue.js"
        elif grep -q "express" package.json 2>/dev/null; then
            framework="Express.js"
        fi
    elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
        project_type="Python"
        package_manager="pip"
        if [[ -f "pyproject.toml" ]]; then
            package_manager="poetry"
        fi
    elif [[ -f "Cargo.toml" ]]; then
        project_type="Rust"
        package_manager="cargo"
    elif [[ -f "go.mod" ]]; then
        project_type="Go"
        package_manager="go"
    fi
    
    # Generate Claude.md content
    cat > "$CLAUDE_MD" <<EOF
# $project_name Project Context

## Project Summary
This is a $project_type project$(if [[ "$framework" != "none" ]]; then echo " using $framework"; fi). 

## Critical Context

### Project Type & Configuration
- **Language/Framework**: $project_type$(if [[ "$framework" != "none" ]]; then echo " ($framework)"; fi)
- **Package Manager**: $package_manager
- **Git Branch**: $git_branch
- **Repository**: $git_remote

### Development Setup
$(if [[ -f "package.json" ]]; then
    echo "- **Install Dependencies**: \`$package_manager install\`"
    if jq -e '.scripts.dev' package.json >/dev/null 2>&1; then
        echo "- **Development Server**: \`$package_manager run dev\`"
    fi
    if jq -e '.scripts.build' package.json >/dev/null 2>&1; then
        echo "- **Build**: \`$package_manager run build\`"
    fi
    if jq -e '.scripts.test' package.json >/dev/null 2>&1; then
        echo "- **Test**: \`$package_manager run test\`"
    fi
elif [[ -f "requirements.txt" ]]; then
    echo "- **Install Dependencies**: \`pip install -r requirements.txt\`"
    echo "- **Virtual Environment**: \`python -m venv venv && source venv/bin/activate\`"
elif [[ -f "pyproject.toml" ]]; then
    echo "- **Install Dependencies**: \`poetry install\`"
    echo "- **Activate Environment**: \`poetry shell\`"
elif [[ -f "Cargo.toml" ]]; then
    echo "- **Build**: \`cargo build\`"
    echo "- **Run**: \`cargo run\`"
    echo "- **Test**: \`cargo test\`"
elif [[ -f "go.mod" ]]; then
    echo "- **Install Dependencies**: \`go mod download\`"
    echo "- **Build**: \`go build\`"
    echo "- **Run**: \`go run .\`"
    echo "- **Test**: \`go test\`"
fi)

### Key Files & Directories
$(if [[ -f "README.md" ]]; then echo "- **README.md**: Project documentation"; fi)
$(if [[ -f ".env.example" ]]; then echo "- **.env.example**: Environment configuration template"; fi)
$(if [[ -f ".gitignore" ]]; then echo "- **.gitignore**: Git ignore rules"; fi)
$(if [[ -d "src" ]]; then echo "- **src/**: Source code directory"; fi)
$(if [[ -d "public" ]]; then echo "- **public/**: Public assets"; fi)
$(if [[ -d "docs" ]]; then echo "- **docs/**: Documentation"; fi)

### Development Patterns
- **Coding Style**: $(if [[ -f ".eslintrc.js" ]] || [[ -f ".eslintrc.json" ]]; then echo "ESLint configured"; elif [[ -f "pyproject.toml" ]]; then echo "Python with Poetry"; else echo "Follow existing code patterns"; fi)
- **Git Workflow**: $(if [[ -f ".github/workflows" ]]; then echo "GitHub Actions configured"; else echo "Standard git workflow"; fi)
- **Testing**: $(if [[ -d "tests" ]] || [[ -d "test" ]] || [[ -d "__tests__" ]]; then echo "Test directory found"; else echo "No tests configured yet"; fi)

## Architecture Overview
$(if [[ -f "package.json" ]]; then
    echo "\`\`\`"
    echo "$project_name/"
    echo "├── src/          # Source code"
    echo "├── public/       # Static assets"
    echo "├── package.json  # Dependencies"
    echo "└── README.md     # Documentation"
    echo "\`\`\`"
elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
    echo "\`\`\`"
    echo "$project_name/"
    echo "├── src/          # Source code"
    echo "├── tests/        # Test files"
    echo "├── requirements.txt # Dependencies"
    echo "└── README.md     # Documentation"
    echo "\`\`\`"
else
    echo "Project structure will be documented as development progresses."
fi)

## Key Integration Points
- **Claude Code**: Integrated with auto-init for context management
- **Git**: Repository tracking and version control
- **Development Tools**: $(if [[ "$package_manager" != "none" ]]; then echo "$package_manager for dependency management"; else echo "Standard development tools"; fi)

## Learned Facts
- **Project Initialized**: $TIMESTAMP
- **Auto-init**: Claude Code context management enabled
- **Development Ready**: Basic project structure confirmed

### Recent Updates
- **$(date '+%Y-%m-%d %H:%M:%S')**: Project initialized with Claude Code auto-init
- **Context Created**: Intelligent project analysis and setup completed
- **Memory Management**: Persistent context tracking enabled

<!-- This section will be automatically updated by the memory watch task -->
EOF
    
    log_success "Claude.md generated with project analysis"
}

# Update existing Claude.md with context refresh
update_claude_md() {
    log_message "Updating existing Claude.md..."
    
    # Create backup
    cp "$CLAUDE_MD" "$CLAUDE_DIR/backups/Claude-backup-$(date +%Y%m%d-%H%M%S).md"
    
    # Add context refresh entry
    local update_entry="
### Context Refresh - $(date '+%Y-%m-%d %H:%M:%S')
- **Status**: Claude Code auto-init executed
- **Branch**: $(git branch --show-current 2>/dev/null || echo 'unknown')
- **Project State**: Active development
- **Memory**: Context updated and refreshed
"
    
    # Insert before the auto-update comment or append to end
    if grep -q "<!-- This section will be automatically updated" "$CLAUDE_MD"; then
        # Create a temporary file with the update entry
        echo "$update_entry" > /tmp/claude_update.txt
        sed -i.bak '/<!-- This section will be automatically updated/r /tmp/claude_update.txt' "$CLAUDE_MD"
        rm -f /tmp/claude_update.txt
    else
        echo "$update_entry" >> "$CLAUDE_MD"
    fi
    
    log_success "Claude.md updated with context refresh"
}

# Setup context monitoring
setup_context_monitoring() {
    log_message "Setting up context monitoring..."
    
    # Create context monitor script
    cat > "$CLAUDE_DIR/scripts/context-monitor.sh" <<'EOF'
#!/bin/bash

# Context Monitor - Watches for project changes and updates Claude.md

set -euo pipefail

CLAUDE_MD="Claude.md"
WATCH_DIRS=("src" "lib" "components" "pages" "api" "utils" "config")
WATCH_FILES=("package.json" "requirements.txt" "pyproject.toml" "Cargo.toml" "go.mod")

# Monitor file changes and update context
monitor_context() {
    local changed_file="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Add context update to Claude.md
    if [[ -f "$CLAUDE_MD" ]]; then
        local update_entry="
### Context Update - $timestamp
- **File Modified**: $changed_file
- **Auto-detected**: Context monitoring active
- **Status**: Development in progress
"
        
        # Insert before the auto-update comment
        sed -i.bak '/<!-- This section will be automatically updated/i\
'"$update_entry"'
' "$CLAUDE_MD"
    fi
}

# Main monitoring function
if [[ $# -gt 0 ]]; then
    monitor_context "$1"
fi
EOF
    
    chmod +x "$CLAUDE_DIR/scripts/context-monitor.sh"
    log_success "Context monitoring setup complete"
}

# Main execution
main() {
    log_message "Starting Claude Code auto-init..."
    
    # Check if init is needed
    if init_already_complete; then
        log_message "Init already complete, checking for updates..."
        if [[ -f "$CLAUDE_MD" ]]; then
            update_claude_md
        else
            log_warning "Claude.md missing, regenerating..."
            generate_claude_md
        fi
    else
        log_message "New project detected, running full initialization..."
        
        # Create project structure
        create_project_structure
        
        # Generate or update Claude.md
        if is_new_project; then
            generate_claude_md
        else
            update_claude_md
        fi
        
        # Setup context monitoring
        setup_context_monitoring
    fi
    
    log_success "Auto-init completed successfully"
}

# Execute main function
main "$@"