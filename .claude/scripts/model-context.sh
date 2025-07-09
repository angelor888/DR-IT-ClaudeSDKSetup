#!/bin/bash

# Model Context Analyzer
# Analyzes current project context to suggest optimal Claude model

set -euo pipefail

# Configuration
CLAUDE_DIR=".claude"
CLAUDE_MD="Claude.md"
ANALYSIS_CACHE="$CLAUDE_DIR/cache/context-analysis.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Context indicators
declare -A CONTEXT_INDICATORS=(
    # File types that suggest coding tasks
    ["*.js"]="coding"
    ["*.ts"]="coding"
    ["*.py"]="coding"
    ["*.java"]="coding"
    ["*.cpp"]="coding"
    ["*.c"]="coding"
    ["*.go"]="coding"
    ["*.rs"]="coding"
    ["*.php"]="coding"
    ["*.rb"]="coding"
    
    # Configuration files
    ["package.json"]="coding"
    ["requirements.txt"]="coding"
    ["Cargo.toml"]="coding"
    ["go.mod"]="coding"
    ["composer.json"]="coding"
    
    # Documentation suggests writing tasks
    ["*.md"]="writing"
    ["*.txt"]="writing"
    ["*.doc"]="writing"
    ["*.docx"]="writing"
    ["README*"]="writing"
    
    # Data files suggest analysis
    ["*.csv"]="analysis"
    ["*.json"]="analysis"
    ["*.xml"]="analysis"
    ["*.yaml"]="analysis"
    ["*.yml"]="analysis"
    
    # Testing suggests debugging
    ["*test*"]="debugging"
    ["*spec*"]="debugging"
    ["*.test.*"]="debugging"
)

# Task complexity indicators
declare -A COMPLEXITY_INDICATORS=(
    # High complexity keywords
    ["algorithm"]="complex"
    ["machine learning"]="complex"
    ["artificial intelligence"]="complex"
    ["deep learning"]="complex"
    ["neural network"]="complex"
    ["optimization"]="complex"
    ["architecture"]="complex"
    ["design pattern"]="complex"
    
    # Medium complexity
    ["refactor"]="coding"
    ["implement"]="coding"
    ["debug"]="debugging"
    ["fix"]="debugging"
    ["test"]="debugging"
    
    # Speed-focused
    ["quick"]="speed"
    ["fast"]="speed"
    ["simple"]="speed"
    ["basic"]="speed"
    ["iterate"]="speed"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_message() {
    echo -e "${BLUE}[model-context] $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[model-context] $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}[model-context] $1${NC}" >&2
}

log_error() {
    echo -e "${RED}[model-context] $1${NC}" >&2
}

# Analyze file types in project
analyze_file_types() {
    local file_analysis=()
    local primary_context=""
    local confidence=0
    
    # Count different file types
    while IFS= read -r -d '' file; do
        local filename=$(basename "$file")
        
        for pattern in "${!CONTEXT_INDICATORS[@]}"; do
            if [[ "$filename" == $pattern ]]; then
                file_analysis+=("${CONTEXT_INDICATORS[$pattern]}")
                break
            fi
        done
    done < <(find . -type f -not -path "./.git/*" -not -path "./.claude/*" -print0 2>/dev/null)
    
    # Determine primary context
    if [[ ${#file_analysis[@]} -gt 0 ]]; then
        # Count occurrences of each context type
        declare -A context_counts
        for context in "${file_analysis[@]}"; do
            ((context_counts[$context]++))
        done
        
        # Find most common context
        local max_count=0
        for context in "${!context_counts[@]}"; do
            if [[ ${context_counts[$context]} -gt $max_count ]]; then
                max_count=${context_counts[$context]}
                primary_context="$context"
            fi
        done
        
        # Calculate confidence based on file count
        confidence=$(( (max_count * 100) / ${#file_analysis[@]} ))
    else
        primary_context="coding"
        confidence=50
    fi
    
    echo "$primary_context:$confidence"
}

# Analyze Claude.md content for context clues
analyze_claude_md() {
    local content_context=""
    local confidence=0
    
    if [[ ! -f "$CLAUDE_MD" ]]; then
        echo "coding:50"
        return 0
    fi
    
    local content=$(cat "$CLAUDE_MD" | tr '[:upper:]' '[:lower:]')
    
    # Look for complexity indicators
    for keyword in "${!COMPLEXITY_INDICATORS[@]}"; do
        if [[ "$content" == *"$keyword"* ]]; then
            content_context="${COMPLEXITY_INDICATORS[$keyword]}"
            confidence=80
            break
        fi
    done
    
    # If no complexity indicators, look for general patterns
    if [[ -z "$content_context" ]]; then
        if [[ "$content" == *"code"* ]] || [[ "$content" == *"develop"* ]] || [[ "$content" == *"implement"* ]]; then
            content_context="coding"
            confidence=70
        elif [[ "$content" == *"write"* ]] || [[ "$content" == *"document"* ]] || [[ "$content" == *"text"* ]]; then
            content_context="writing"
            confidence=70
        elif [[ "$content" == *"analyze"* ]] || [[ "$content" == *"data"* ]] || [[ "$content" == *"research"* ]]; then
            content_context="analysis"
            confidence=70
        elif [[ "$content" == *"debug"* ]] || [[ "$content" == *"fix"* ]] || [[ "$content" == *"error"* ]]; then
            content_context="debugging"
            confidence=70
        else
            content_context="coding"
            confidence=50
        fi
    fi
    
    echo "$content_context:$confidence"
}

# Analyze recent git activity
analyze_git_activity() {
    local git_context=""
    local confidence=0
    
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "coding:50"
        return 0
    fi
    
    # Analyze recent commit messages
    local recent_commits=$(git log --oneline -10 2>/dev/null | tr '[:upper:]' '[:lower:]')
    
    if [[ -z "$recent_commits" ]]; then
        echo "coding:50"
        return 0
    fi
    
    # Look for patterns in commit messages
    if [[ "$recent_commits" == *"fix"* ]] || [[ "$recent_commits" == *"debug"* ]] || [[ "$recent_commits" == *"bug"* ]]; then
        git_context="debugging"
        confidence=75
    elif [[ "$recent_commits" == *"refactor"* ]] || [[ "$recent_commits" == *"improve"* ]] || [[ "$recent_commits" == *"optimize"* ]]; then
        git_context="coding"
        confidence=70
    elif [[ "$recent_commits" == *"add"* ]] || [[ "$recent_commits" == *"implement"* ]] || [[ "$recent_commits" == *"create"* ]]; then
        git_context="coding"
        confidence=65
    elif [[ "$recent_commits" == *"docs"* ]] || [[ "$recent_commits" == *"readme"* ]] || [[ "$recent_commits" == *"documentation"* ]]; then
        git_context="writing"
        confidence=70
    else
        git_context="coding"
        confidence=50
    fi
    
    echo "$git_context:$confidence"
}

# Analyze project structure
analyze_project_structure() {
    local structure_context=""
    local confidence=0
    
    # Check for specific project types
    if [[ -f "package.json" ]]; then
        if grep -q "\"react\"" package.json 2>/dev/null; then
            structure_context="coding"
            confidence=80
        elif grep -q "\"express\"" package.json 2>/dev/null; then
            structure_context="coding"
            confidence=80
        elif grep -q "\"next\"" package.json 2>/dev/null; then
            structure_context="coding"
            confidence=80
        else
            structure_context="coding"
            confidence=70
        fi
    elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
        # Check for data science packages
        if grep -q -E "(pandas|numpy|scikit-learn|tensorflow|pytorch)" requirements.txt 2>/dev/null; then
            structure_context="analysis"
            confidence=80
        else
            structure_context="coding"
            confidence=70
        fi
    elif [[ -f "Cargo.toml" ]]; then
        structure_context="coding"
        confidence=70
    elif [[ -f "go.mod" ]]; then
        structure_context="coding"
        confidence=70
    elif [[ -d "docs" ]] && [[ $(find docs -name "*.md" | wc -l) -gt 3 ]]; then
        structure_context="writing"
        confidence=70
    else
        structure_context="coding"
        confidence=50
    fi
    
    echo "$structure_context:$confidence"
}

# Combine all analysis results
combine_analysis() {
    local file_result=$(analyze_file_types)
    local claude_result=$(analyze_claude_md)
    local git_result=$(analyze_git_activity)
    local structure_result=$(analyze_project_structure)
    
    # Parse results
    local file_context=$(echo "$file_result" | cut -d':' -f1)
    local file_confidence=$(echo "$file_result" | cut -d':' -f2)
    
    local claude_context=$(echo "$claude_result" | cut -d':' -f1)
    local claude_confidence=$(echo "$claude_result" | cut -d':' -f2)
    
    local git_context=$(echo "$git_result" | cut -d':' -f1)
    local git_confidence=$(echo "$git_result" | cut -d':' -f2)
    
    local structure_context=$(echo "$structure_result" | cut -d':' -f1)
    local structure_confidence=$(echo "$structure_result" | cut -d':' -f2)
    
    # Weighted scoring
    declare -A context_scores=(
        ["coding"]=0
        ["writing"]=0
        ["analysis"]=0
        ["debugging"]=0
        ["creative"]=0
        ["speed"]=0
        ["complex"]=0
    )
    
    # Add weighted scores
    ((context_scores[$file_context] += file_confidence * 2))  # File types are important
    ((context_scores[$claude_context] += claude_confidence * 3))  # Claude.md is very important
    ((context_scores[$git_context] += git_confidence * 1))  # Git activity is somewhat important
    ((context_scores[$structure_context] += structure_confidence * 2))  # Project structure is important
    
    # Find highest scoring context
    local max_score=0
    local final_context="coding"
    
    for context in "${!context_scores[@]}"; do
        if [[ ${context_scores[$context]} -gt $max_score ]]; then
            max_score=${context_scores[$context]}
            final_context="$context"
        fi
    done
    
    # Calculate final confidence
    local final_confidence=$(( max_score / 4 ))
    if [[ $final_confidence -gt 100 ]]; then
        final_confidence=100
    elif [[ $final_confidence -lt 50 ]]; then
        final_confidence=50
    fi
    
    echo "$final_context:$final_confidence"
}

# Cache analysis results
cache_analysis() {
    local context="$1"
    local confidence="$2"
    
    mkdir -p "$(dirname "$ANALYSIS_CACHE")"
    
    cat > "$ANALYSIS_CACHE" <<EOF
{
  "context": "$context",
  "confidence": $confidence,
  "timestamp": "$TIMESTAMP",
  "analysis_details": {
    "file_types": "$(analyze_file_types)",
    "claude_md": "$(analyze_claude_md)",
    "git_activity": "$(analyze_git_activity)",
    "project_structure": "$(analyze_project_structure)"
  }
}
EOF
}

# Main execution
main() {
    log_message "Analyzing project context for model recommendation..."
    
    # Perform comprehensive analysis
    local analysis_result=$(combine_analysis)
    local context=$(echo "$analysis_result" | cut -d':' -f1)
    local confidence=$(echo "$analysis_result" | cut -d':' -f2)
    
    # Cache the results
    cache_analysis "$context" "$confidence"
    
    # Output results
    echo -e "${PURPLE}🔍 Project Context Analysis${NC}"
    echo -e "${CYAN}─────────────────────────────${NC}"
    echo -e "${GREEN}Primary Context: $context${NC}"
    echo -e "${YELLOW}Confidence: $confidence%${NC}"
    echo -e "${BLUE}Timestamp: $TIMESTAMP${NC}"
    
    # Output for script consumption
    echo "$context:$confidence"
    
    log_success "Context analysis completed"
}

# Execute main function
main "$@"