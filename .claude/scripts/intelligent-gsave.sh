#!/bin/bash

# Intelligent Git Save Script
# Enhanced git save with AI-powered commit message generation

set -euo pipefail

# Configuration
CLAUDE_DIR=".claude"
GSAVE_CONFIG="$CLAUDE_DIR/settings/gsave.json"
COMMIT_LOG="$CLAUDE_DIR/logs/commit-history.log"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_message() {
    echo -e "${BLUE}[intelligent-gsave] $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[intelligent-gsave] $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}[intelligent-gsave] $1${NC}" >&2
}

log_error() {
    echo -e "${RED}[intelligent-gsave] $1${NC}" >&2
}

# Initialize gsave configuration
init_gsave_config() {
    if [[ ! -f "$GSAVE_CONFIG" ]]; then
        mkdir -p "$(dirname "$GSAVE_CONFIG")"
        cat > "$GSAVE_CONFIG" <<EOF
{
  "auto_push": true,
  "default_branch": "main",
  "commit_message_style": "conventional",
  "ai_generation": true,
  "conflict_resolution": "interactive",
  "push_retry_count": 3,
  "commit_templates": {
    "feat": "feat: add {{description}}",
    "fix": "fix: resolve {{description}}",
    "docs": "docs: update {{description}}",
    "style": "style: improve {{description}}",
    "refactor": "refactor: restructure {{description}}",
    "test": "test: add {{description}}",
    "chore": "chore: {{description}}"
  },
  "last_updated": "$TIMESTAMP"
}
EOF
    fi
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_error "Not in a git repository"
        return 1
    fi
    return 0
}

# Get current git status
get_git_status() {
    local status_output=$(git status --porcelain 2>/dev/null)
    
    if [[ -z "$status_output" ]]; then
        log_warning "No changes to commit"
        return 1
    fi
    
    echo "$status_output"
    return 0
}

# Analyze git changes for intelligent commit message
analyze_git_changes() {
    local changes="$1"
    
    # Count different types of changes
    local added_files=$(echo "$changes" | grep -c "^A" || echo "0")
    local modified_files=$(echo "$changes" | grep -c "^M" || echo "0")
    local deleted_files=$(echo "$changes" | grep -c "^D" || echo "0")
    local renamed_files=$(echo "$changes" | grep -c "^R" || echo "0")
    
    # Analyze file types
    local js_files=$(echo "$changes" | grep -c "\.js$\|\.ts$\|\.jsx$\|\.tsx$" || echo "0")
    local py_files=$(echo "$changes" | grep -c "\.py$" || echo "0")
    local md_files=$(echo "$changes" | grep -c "\.md$" || echo "0")
    local config_files=$(echo "$changes" | grep -c "\.json$\|\.yaml$\|\.yml$\|\.toml$" || echo "0")
    local test_files=$(echo "$changes" | grep -c "test\|spec" || echo "0")
    
    # Generate analysis summary
    local analysis=""
    analysis+="{\"added\": $added_files, \"modified\": $modified_files, \"deleted\": $deleted_files, \"renamed\": $renamed_files, "
    analysis+="\"js_files\": $js_files, \"py_files\": $py_files, \"md_files\": $md_files, \"config_files\": $config_files, \"test_files\": $test_files}"
    
    echo "$analysis"
}

# Generate intelligent commit message
generate_commit_message() {
    local changes="$1"
    local custom_message="$2"
    
    # If custom message provided, use it
    if [[ -n "$custom_message" ]]; then
        echo "$custom_message"
        return 0
    fi
    
    # Analyze changes
    local analysis=$(analyze_git_changes "$changes")
    
    # Extract counts
    local added=$(echo "$analysis" | jq -r '.added')
    local modified=$(echo "$analysis" | jq -r '.modified')
    local deleted=$(echo "$analysis" | jq -r '.deleted')
    local test_files=$(echo "$analysis" | jq -r '.test_files')
    local md_files=$(echo "$analysis" | jq -r '.md_files')
    local config_files=$(echo "$analysis" | jq -r '.config_files')
    
    # Generate message based on analysis
    local message=""
    local type=""
    
    # Determine commit type
    if [[ $test_files -gt 0 ]]; then
        type="test"
        message="test: add/update test files"
    elif [[ $md_files -gt 0 ]] && [[ $((added + modified + deleted)) -eq $md_files ]]; then
        type="docs"
        message="docs: update documentation"
    elif [[ $config_files -gt 0 ]] && [[ $((added + modified + deleted)) -eq $config_files ]]; then
        type="chore"
        message="chore: update configuration"
    elif [[ $added -gt 0 ]] && [[ $modified -eq 0 ]] && [[ $deleted -eq 0 ]]; then
        type="feat"
        message="feat: add new functionality"
    elif [[ $deleted -gt 0 ]] && [[ $added -eq 0 ]] && [[ $modified -eq 0 ]]; then
        type="refactor"
        message="refactor: remove unused code"
    elif [[ $modified -gt 0 ]]; then
        type="fix"
        message="fix: update existing functionality"
    else
        type="chore"
        message="chore: update project files"
    fi
    
    # Enhanced message with file details
    local file_summary=""
    if [[ $((added + modified + deleted)) -eq 1 ]]; then
        local changed_file=$(echo "$changes" | head -1 | awk '{print $2}')
        file_summary=" ($(basename "$changed_file"))"
    elif [[ $((added + modified + deleted)) -le 3 ]]; then
        local file_list=$(echo "$changes" | awk '{print $2}' | xargs -I {} basename {} | tr '\n' ',' | sed 's/,$//')
        file_summary=" ($file_list)"
    else
        file_summary=" (${added}A ${modified}M ${deleted}D files)"
    fi
    
    echo "${message}${file_summary}"
}

# Handle git conflicts
handle_git_conflicts() {
    log_warning "Git conflicts detected"
    
    local conflicts=$(git status --porcelain | grep "^UU\|^AA\|^DD")
    
    if [[ -n "$conflicts" ]]; then
        echo -e "${RED}Conflicts found in:${NC}"
        echo "$conflicts" | while read -r line; do
            echo -e "${YELLOW}  - $(echo "$line" | awk '{print $2}')${NC}"
        done
        
        echo -e "${CYAN}Resolution options:${NC}"
        echo "1. Resolve conflicts manually and re-run gsave"
        echo "2. Abort current operation (git merge --abort)"
        echo "3. Use their version (git checkout --theirs .)"
        echo "4. Use our version (git checkout --ours .)"
        
        read -p "Choose option (1-4): " choice
        
        case "$choice" in
            1)
                log_message "Please resolve conflicts manually and re-run gsave"
                return 1
                ;;
            2)
                git merge --abort
                log_message "Git merge aborted"
                return 1
                ;;
            3)
                git checkout --theirs .
                git add .
                log_success "Using their version, conflicts resolved"
                return 0
                ;;
            4)
                git checkout --ours .
                git add .
                log_success "Using our version, conflicts resolved"
                return 0
                ;;
            *)
                log_error "Invalid option"
                return 1
                ;;
        esac
    fi
    
    return 0
}

# Handle push failures
handle_push_failure() {
    local branch="$1"
    local retry_count=0
    local max_retries=3
    
    while [[ $retry_count -lt $max_retries ]]; do
        log_message "Push failed, attempting retry $((retry_count + 1))/$max_retries"
        
        # Try to pull and rebase
        if git pull --rebase origin "$branch" 2>/dev/null; then
            log_success "Successfully pulled and rebased"
            
            # Try push again
            if git push origin "$branch" 2>/dev/null; then
                log_success "Push successful after retry"
                return 0
            fi
        fi
        
        ((retry_count++))
        sleep 2
    done
    
    log_error "Push failed after $max_retries retries"
    echo -e "${CYAN}Push failure options:${NC}"
    echo "1. Force push (dangerous)"
    echo "2. Create new branch"
    echo "3. Abort push (keep local changes)"
    
    read -p "Choose option (1-3): " choice
    
    case "$choice" in
        1)
            if git push --force-with-lease origin "$branch" 2>/dev/null; then
                log_success "Force push successful"
                return 0
            else
                log_error "Force push failed"
                return 1
            fi
            ;;
        2)
            local new_branch="${branch}-$(date +%Y%m%d-%H%M%S)"
            git checkout -b "$new_branch"
            git push origin "$new_branch"
            log_success "Created and pushed new branch: $new_branch"
            return 0
            ;;
        3)
            log_message "Push aborted, local changes preserved"
            return 1
            ;;
        *)
            log_error "Invalid option"
            return 1
            ;;
    esac
}

# Log commit to history
log_commit() {
    local message="$1"
    local branch="$2"
    local commit_hash="$3"
    
    mkdir -p "$(dirname "$COMMIT_LOG")"
    
    local log_entry="{\"timestamp\": \"$TIMESTAMP\", \"message\": \"$message\", \"branch\": \"$branch\", \"commit\": \"$commit_hash\"}"
    echo "$log_entry" >> "$COMMIT_LOG"
}

# Main intelligent git save function
intelligent_gsave() {
    local custom_message="$1"
    local auto_push="${2:-true}"
    local target_branch="${3:-main}"
    
    log_message "Starting intelligent git save..."
    
    # Initialize configuration
    init_gsave_config
    
    # Check git repository
    if ! check_git_repo; then
        return 1
    fi
    
    # Get current git status
    local changes
    if ! changes=$(get_git_status); then
        return 1
    fi
    
    log_message "Found changes in $(echo "$changes" | wc -l) files"
    
    # Stage all changes
    git add .
    
    # Generate commit message
    local commit_message
    commit_message=$(generate_commit_message "$changes" "$custom_message")
    
    log_message "Generated commit message: $commit_message"
    
    # Create commit
    if git commit -m "$commit_message" -m "🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"; then
        local commit_hash=$(git rev-parse HEAD)
        log_success "Commit created: $commit_hash"
        
        # Log commit
        log_commit "$commit_message" "$target_branch" "$commit_hash"
        
        # Push if enabled
        if [[ "$auto_push" == "true" ]]; then
            log_message "Pushing to remote branch: $target_branch"
            
            if git push origin "$target_branch" 2>/dev/null; then
                log_success "Push successful"
                
                # Display success summary
                echo -e "${GREEN}✅ Intelligent Git Save Complete!${NC}"
                echo -e "${CYAN}Commit: $commit_message${NC}"
                echo -e "${CYAN}Branch: $target_branch${NC}"
                echo -e "${CYAN}Hash: $(git rev-parse --short HEAD)${NC}"
                
                return 0
            else
                log_warning "Push failed, attempting resolution..."
                handle_push_failure "$target_branch"
            fi
        else
            log_success "Commit completed (push skipped)"
            return 0
        fi
    else
        log_error "Commit failed"
        return 1
    fi
}

# Show commit statistics
show_commit_stats() {
    if [[ ! -f "$COMMIT_LOG" ]]; then
        log_warning "No commit history available"
        return 0
    fi
    
    local total_commits=$(wc -l < "$COMMIT_LOG")
    local today_commits=$(grep "$(date +%Y-%m-%d)" "$COMMIT_LOG" | wc -l)
    
    echo -e "${PURPLE}📊 Commit Statistics${NC}"
    echo -e "${CYAN}─────────────────────────────${NC}"
    echo -e "${GREEN}Total commits: $total_commits${NC}"
    echo -e "${GREEN}Today's commits: $today_commits${NC}"
    
    if [[ $total_commits -gt 0 ]]; then
        echo -e "${CYAN}Recent commits:${NC}"
        tail -n 3 "$COMMIT_LOG" | jq -r '"\(.timestamp | split("T")[0]) \(.message)"' | while read -r line; do
            echo -e "${YELLOW}  • $line${NC}"
        done
    fi
}

# Main command handling
main() {
    local custom_message=""
    local auto_push="true"
    local target_branch="main"
    local show_stats=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--message)
                custom_message="$2"
                shift 2
                ;;
            --no-push)
                auto_push="false"
                shift
                ;;
            -b|--branch)
                target_branch="$2"
                shift 2
                ;;
            --stats)
                show_stats=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -m, --message TEXT    Custom commit message"
                echo "  --no-push            Don't push to remote"
                echo "  -b, --branch BRANCH  Target branch (default: main)"
                echo "  --stats              Show commit statistics"
                echo "  -h, --help           Show this help"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    if [[ "$show_stats" == "true" ]]; then
        show_commit_stats
        return 0
    fi
    
    # Run intelligent git save
    intelligent_gsave "$custom_message" "$auto_push" "$target_branch"
}

# Execute main function
main "$@"