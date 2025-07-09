#!/bin/bash

# Model Manager Script
# Handles Claude model switching and task-based recommendations

set -euo pipefail

# Configuration
CLAUDE_DIR=".claude"
SETTINGS_FILE="$CLAUDE_DIR/settings/settings.json"
MODEL_PREFERENCES="$CLAUDE_DIR/settings/model-preferences.json"
MODEL_LOG="$CLAUDE_DIR/logs/model-switches.log"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Available models
MODELS=(
    "claude-3-opus-20240229"
    "claude-3-sonnet-20240229"
    "claude-3-haiku-20240307"
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
    echo -e "${BLUE}[model-manager] $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[model-manager] $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}[model-manager] $1${NC}" >&2
}

log_error() {
    echo -e "${RED}[model-manager] $1${NC}" >&2
}

# Get model capability description
get_model_capability() {
    local model="$1"
    
    case "$model" in
        "claude-3-opus-20240229")
            echo "Most capable, best for complex analysis and creative tasks"
            ;;
        "claude-3-sonnet-20240229")
            echo "Balanced performance, ideal for coding and general tasks"
            ;;
        "claude-3-haiku-20240307")
            echo "Fastest response, perfect for quick tasks and iteration"
            ;;
        *)
            echo "Unknown model capability"
            ;;
    esac
}

# Get task recommendation
get_task_recommendation() {
    local task_type="$1"
    
    case "$task_type" in
        "coding"|"debugging")
            echo "claude-3-sonnet-20240229"
            ;;
        "writing"|"analysis"|"creative"|"complex")
            echo "claude-3-opus-20240229"
            ;;
        "speed"|"iteration")
            echo "claude-3-haiku-20240307"
            ;;
        *)
            echo "claude-3-sonnet-20240229"
            ;;
    esac
}

# Initialize model preferences file
init_model_preferences() {
    if [[ ! -f "$MODEL_PREFERENCES" ]]; then
        mkdir -p "$(dirname "$MODEL_PREFERENCES")"
        cat > "$MODEL_PREFERENCES" <<EOF
{
  "default_model": "claude-3-sonnet-20240229",
  "task_preferences": {
    "coding": "claude-3-sonnet-20240229",
    "writing": "claude-3-opus-20240229",
    "analysis": "claude-3-opus-20240229",
    "debugging": "claude-3-sonnet-20240229",
    "creative": "claude-3-opus-20240229",
    "speed": "claude-3-haiku-20240307"
  },
  "usage_history": {},
  "last_updated": "$TIMESTAMP"
}
EOF
    fi
}

# Get current model from settings
get_current_model() {
    if [[ -f "$SETTINGS_FILE" ]]; then
        jq -r '.models.default // "claude-3-sonnet-20240229"' "$SETTINGS_FILE" 2>/dev/null || echo "claude-3-sonnet-20240229"
    else
        echo "claude-3-sonnet-20240229"
    fi
}

# Set new default model in settings
set_default_model() {
    local new_model="$1"
    
    if [[ -f "$SETTINGS_FILE" ]]; then
        # Create backup
        cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak"
        
        # Update default model
        jq ".models.default = \"$new_model\"" "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        
        log_success "Default model updated in settings.json"
    else
        log_warning "Settings file not found, cannot update default model"
    fi
}

# Save task preference
save_task_preference() {
    local task_type="$1"
    local model="$2"
    
    init_model_preferences
    
    # Update task preference
    jq ".task_preferences.\"$task_type\" = \"$model\" | .last_updated = \"$TIMESTAMP\"" "$MODEL_PREFERENCES" > "$MODEL_PREFERENCES.tmp" && mv "$MODEL_PREFERENCES.tmp" "$MODEL_PREFERENCES"
    
    log_success "Task preference saved: $task_type -> $model"
}

# Show available models
show_models() {
    local current_model=$(get_current_model)
    
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}  ${CYAN}🤖 Available Claude Models${NC}                                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠══════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC}                                                                                  ${PURPLE}║${NC}"
    
    for model in "${MODELS[@]}"; do
        local capability=$(get_model_capability "$model")
        local status_icon="⚪"
        local color=$CYAN
        
        if [[ "$model" == "$current_model" ]]; then
            status_icon="🔸"
            color=$GREEN
        fi
        
        printf "${PURPLE}║${NC}  ${color}${status_icon} %-30s${NC}" "$model"
        printf "                                   ${PURPLE}║${NC}\n"
        printf "${PURPLE}║${NC}     ${YELLOW}→ %-70s${NC} ${PURPLE}║${NC}\n" "$capability"
        echo -e "${PURPLE}║${NC}                                                                                  ${PURPLE}║${NC}"
    done
    
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Suggest model based on task type
suggest_model() {
    local task_type=${1:-"coding"}
    local current_model=$(get_current_model)
    
    log_message "Analyzing task type: $task_type"
    
    # Check user preferences first
    local suggested_model
    if [[ -f "$MODEL_PREFERENCES" ]]; then
        suggested_model=$(jq -r ".task_preferences.\"$task_type\" // empty" "$MODEL_PREFERENCES" 2>/dev/null)
    fi
    
    if [[ -z "$suggested_model" || "$suggested_model" == "null" ]]; then
        suggested_model=$(get_task_recommendation "$task_type")
    fi
    
    echo -e "${BLUE}📊 Task Analysis: $task_type${NC}"
    echo -e "${YELLOW}Current Model: $current_model${NC}"
    echo -e "${GREEN}Suggested Model: $suggested_model${NC}"
    echo -e "${CYAN}Reason: $(get_model_capability "$suggested_model")${NC}"
    
    if [[ "$current_model" == "$suggested_model" ]]; then
        echo -e "${GREEN}✅ You're already using the optimal model for this task!${NC}"
    else
        echo -e "${YELLOW}💡 Consider switching to $suggested_model for better performance${NC}"
    fi
    
    echo "$suggested_model"
}

# Switch to a specific model
switch_model() {
    local target_model="$1"
    local save_preference=${2:-false}
    local task_type=${3:-"coding"}
    
    log_message "Switching to model: $target_model"
    
    # Validate model
    local valid_model=false
    for model in "${MODELS[@]}"; do
        if [[ "$model" == "$target_model" ]]; then
            valid_model=true
            break
        fi
    done
    
    if [[ "$valid_model" == "false" ]]; then
        log_error "Invalid model: $target_model"
        echo "Available models:"
        printf '%s\n' "${MODELS[@]}"
        return 1
    fi
    
    local current_model=$(get_current_model)
    
    if [[ "$current_model" == "$target_model" ]]; then
        log_message "Already using $target_model"
        return 0
    fi
    
    # Update default model
    set_default_model "$target_model"
    
    # Save task preference if requested
    if [[ "$save_preference" == "true" ]]; then
        save_task_preference "$task_type" "$target_model"
    fi
    
    # Log the switch
    mkdir -p "$(dirname "$MODEL_LOG")"
    echo "[$TIMESTAMP] $current_model -> $target_model (task: $task_type)" >> "$MODEL_LOG"
    
    # Update usage history
    init_model_preferences
    local usage_count=$(jq -r ".usage_history.\"$target_model\" // 0" "$MODEL_PREFERENCES" 2>/dev/null)
    ((usage_count++))
    jq ".usage_history.\"$target_model\" = $usage_count | .last_updated = \"$TIMESTAMP\"" "$MODEL_PREFERENCES" > "$MODEL_PREFERENCES.tmp" && mv "$MODEL_PREFERENCES.tmp" "$MODEL_PREFERENCES"
    
    log_success "Model switched successfully: $current_model -> $target_model"
    
    # Display success message
    echo -e "${GREEN}✅ Model Switch Successful!${NC}"
    echo -e "${CYAN}Previous: $current_model${NC}"
    echo -e "${GREEN}Current:  $target_model${NC}"
    echo -e "${YELLOW}Capability: $(get_model_capability "$target_model")${NC}"
}

# Verify model switch
verify_switch() {
    local expected_model=${1:-""}
    local current_model=$(get_current_model)
    
    if [[ -n "$expected_model" ]]; then
        if [[ "$current_model" == "$expected_model" ]]; then
            log_success "Model switch verified: $current_model"
            return 0
        else
            log_error "Model switch failed: expected $expected_model, got $current_model"
            return 1
        fi
    else
        log_success "Current model: $current_model"
        return 0
    fi
}

# Show usage statistics
show_usage_stats() {
    if [[ ! -f "$MODEL_PREFERENCES" ]]; then
        log_warning "No usage statistics available"
        return 0
    fi
    
    echo -e "${PURPLE}📊 Model Usage Statistics${NC}"
    echo -e "${CYAN}─────────────────────────────${NC}"
    
    local usage_data=$(jq -r '.usage_history // {}' "$MODEL_PREFERENCES" 2>/dev/null)
    
    if [[ "$usage_data" == "{}" ]]; then
        echo -e "${YELLOW}No usage data available${NC}"
        return 0
    fi
    
    # Show usage counts
    for model in "${MODELS[@]}"; do
        local count=$(echo "$usage_data" | jq -r ".\"$model\" // 0" 2>/dev/null)
        if [[ "$count" -gt 0 ]]; then
            echo -e "${GREEN}$model: $count times${NC}"
        fi
    done
}

# Main command handling
main() {
    local action=${1:-"help"}
    
    case "$action" in
        "suggest")
            local task_type=${2:-"coding"}
            suggest_model "$task_type"
            ;;
        "switch")
            local target_model=${2:-""}
            local save_preference=${3:-false}
            local task_type=${4:-"coding"}
            
            if [[ -z "$target_model" ]]; then
                log_error "Please specify a model to switch to"
                show_models
                return 1
            fi
            
            switch_model "$target_model" "$save_preference" "$task_type"
            ;;
        "verify")
            local expected_model=${2:-""}
            verify_switch "$expected_model"
            ;;
        "current")
            local current_model=$(get_current_model)
            echo "Current model: $current_model"
            ;;
        "list")
            show_models
            ;;
        "stats")
            show_usage_stats
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [suggest|switch|verify|current|list|stats]"
            echo ""
            echo "Commands:"
            echo "  suggest <task_type>              Get model recommendation for task"
            echo "  switch <model> [save] [task]     Switch to specified model"
            echo "  verify [expected_model]          Verify current model"
            echo "  current                          Show current model"
            echo "  list                             Show all available models"
            echo "  stats                            Show usage statistics"
            ;;
        *)
            log_error "Unknown action: $action"
            echo "Use '$0 help' for usage information"
            return 1
            ;;
    esac
}

# Execute main function
main "$@"