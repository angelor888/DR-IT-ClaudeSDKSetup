#!/bin/bash
# Claude Mode Manager
# Quick model switching and mode management

set -euo pipefail

# Configuration
CLAUDE_CONFIG_DIR="$HOME/.config/claude"
MODE_CONFIG="$CLAUDE_CONFIG_DIR/mode-config.json"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

# Initialize mode manager
init_mode_manager() {
    mkdir -p "$CLAUDE_CONFIG_DIR"
    
    # Create mode configuration
    if [ ! -f "$MODE_CONFIG" ]; then
        cat > "$MODE_CONFIG" << 'EOF'
{
  "version": "1.0.0",
  "currentModel": "claude-opus-4",
  "currentMode": "default",
  "models": {
    "claude-opus-4": {
      "name": "Claude Opus 4",
      "description": "Highest capability for complex reasoning and analysis",
      "use_cases": ["complex reasoning", "architecture design", "research", "analysis"],
      "performance": "high",
      "speed": "medium"
    },
    "claude-sonnet-3.5": {
      "name": "Claude Sonnet 3.5", 
      "description": "Balanced performance and speed",
      "use_cases": ["general development", "code review", "documentation"],
      "performance": "medium",
      "speed": "fast"
    },
    "claude-haiku-3.5": {
      "name": "Claude Haiku 3.5",
      "description": "Fast responses for simple tasks",
      "use_cases": ["code formatting", "simple questions", "quick edits"],
      "performance": "basic",
      "speed": "very fast"
    }
  },
  "modes": {
    "default": {
      "name": "Default Mode",
      "description": "Standard interactive mode with full context awareness",
      "auto_accept": false,
      "plan_mode": false,
      "voice_enabled": true
    },
    "plan": {
      "name": "Plan Mode",
      "description": "Structured task planning with step-by-step execution",
      "auto_accept": false,
      "plan_mode": true,
      "voice_enabled": true
    },
    "auto": {
      "name": "Auto-Accept Mode",
      "description": "Automatic execution of safe commands",
      "auto_accept": true,
      "plan_mode": false,
      "voice_enabled": true
    },
    "speed": {
      "name": "Speed Mode",
      "description": "Optimized for fast responses",
      "auto_accept": true,
      "plan_mode": false,
      "voice_enabled": false
    }
  },
  "shortcuts": {
    "Shift+Tab Shift+Tab": "plan",
    "Cmd+Shift+P": "plan",
    "Cmd+Shift+A": "auto",
    "Cmd+Shift+D": "default"
  }
}
EOF
    fi
    
    echo -e "${GREEN}✅ Mode manager initialized${NC}"
}

# Get current configuration
get_current_config() {
    if [ -f "$MODE_CONFIG" ] && command -v jq &> /dev/null; then
        jq -r '.' "$MODE_CONFIG"
    else
        echo "{}"
    fi
}

# Get configuration value
get_config_value() {
    local key="$1"
    local default="$2"
    
    if [ -f "$MODE_CONFIG" ] && command -v jq &> /dev/null; then
        jq -r ".$key // \"$default\"" "$MODE_CONFIG" 2>/dev/null || echo "$default"
    else
        echo "$default"
    fi
}

# Set configuration value
set_config_value() {
    local key="$1"
    local value="$2"
    
    if [ -f "$MODE_CONFIG" ] && command -v jq &> /dev/null; then
        local temp_config="/tmp/mode_config.json"
        jq ".$key = \"$value\"" "$MODE_CONFIG" > "$temp_config"
        mv "$temp_config" "$MODE_CONFIG"
        
        # Update environment if needed
        export CLAUDE_MODEL="$value"
        echo "export CLAUDE_MODEL=\"$value\"" >> ~/.config/claude/environment
    fi
}

# Switch model
switch_model() {
    local model="$1"
    
    # Validate model
    case "$model" in
        "opus"|"claude-opus-4")
            model="claude-opus-4"
            ;;
        "sonnet"|"claude-sonnet-3.5")
            model="claude-sonnet-3.5"
            ;;
        "haiku"|"claude-haiku-3.5")
            model="claude-haiku-3.5"
            ;;
        *)
            echo -e "${RED}❌ Unknown model: $model${NC}"
            echo "Available models: opus, sonnet, haiku"
            return 1
            ;;
    esac
    
    # Update configuration
    set_config_value "currentModel" "$model"
    
    # Get model info
    local model_name
    model_name=$(get_config_value "models.$model.name" "$model")
    
    local model_desc
    model_desc=$(get_config_value "models.$model.description" "")
    
    echo -e "${GREEN}✅ Switched to $model_name${NC}"
    echo -e "${BLUE}📖 $model_desc${NC}"
    
    # Audio notification
    if [ -x ~/.config/claude/scripts/claude-audio-notifications.sh ]; then
        ~/.config/claude/scripts/claude-audio-notifications.sh context "complete" "Switched to $model_name" true &
    fi
}

# Switch mode
switch_mode() {
    local mode="$1"
    
    # Validate mode
    case "$mode" in
        "default"|"plan"|"auto"|"speed")
            ;;
        *)
            echo -e "${RED}❌ Unknown mode: $mode${NC}"
            echo "Available modes: default, plan, auto, speed"
            return 1
            ;;
    esac
    
    # Update configuration
    set_config_value "currentMode" "$mode"
    
    # Get mode info
    local mode_name
    mode_name=$(get_config_value "modes.$mode.name" "$mode")
    
    local mode_desc
    mode_desc=$(get_config_value "modes.$mode.description" "")
    
    echo -e "${GREEN}✅ Switched to $mode_name${NC}"
    echo -e "${BLUE}📖 $mode_desc${NC}"
    
    # Update environment variables
    local auto_accept
    auto_accept=$(get_config_value "modes.$mode.auto_accept" "false")
    
    local plan_mode
    plan_mode=$(get_config_value "modes.$mode.plan_mode" "false")
    
    local voice_enabled
    voice_enabled=$(get_config_value "modes.$mode.voice_enabled" "true")
    
    export CLAUDE_MODE="$mode"
    export CLAUDE_AUTO_ACCEPT="$auto_accept"
    export CLAUDE_PLAN_MODE="$plan_mode"
    export CLAUDE_VOICE_ENABLED="$voice_enabled"
    
    # Audio notification
    if [ -x ~/.config/claude/scripts/claude-audio-notifications.sh ]; then
        ~/.config/claude/scripts/claude-audio-notifications.sh context "complete" "Switched to $mode_name" true &
    fi
}

# Show current status
show_status() {
    echo -e "${BLUE}🎯 Claude Mode Manager Status${NC}"
    echo "=============================="
    
    local current_model
    current_model=$(get_config_value "currentModel" "claude-opus-4")
    
    local current_mode
    current_mode=$(get_config_value "currentMode" "default")
    
    echo -e "${PURPLE}Current Model:${NC} $current_model"
    echo -e "${PURPLE}Current Mode:${NC} $current_mode"
    
    # Model info
    local model_name
    model_name=$(get_config_value "models.$current_model.name" "$current_model")
    
    local model_desc
    model_desc=$(get_config_value "models.$current_model.description" "")
    
    echo -e "${GREEN}Model: $model_name${NC}"
    echo -e "${BLUE}Description: $model_desc${NC}"
    
    # Mode info
    local mode_name
    mode_name=$(get_config_value "modes.$current_mode.name" "$current_mode")
    
    local mode_desc
    mode_desc=$(get_config_value "modes.$current_mode.description" "")
    
    echo -e "${GREEN}Mode: $mode_name${NC}"
    echo -e "${BLUE}Description: $mode_desc${NC}"
    
    # Environment variables
    echo ""
    echo -e "${PURPLE}Environment:${NC}"
    echo "  CLAUDE_MODEL: ${CLAUDE_MODEL:-not set}"
    echo "  CLAUDE_MODE: ${CLAUDE_MODE:-not set}"
    echo "  CLAUDE_AUTO_ACCEPT: ${CLAUDE_AUTO_ACCEPT:-not set}"
    echo "  CLAUDE_PLAN_MODE: ${CLAUDE_PLAN_MODE:-not set}"
    echo "  CLAUDE_VOICE_ENABLED: ${CLAUDE_VOICE_ENABLED:-not set}"
}

# List available models and modes
list_options() {
    echo -e "${BLUE}📋 Available Models${NC}"
    echo "=================="
    
    if [ -f "$MODE_CONFIG" ] && command -v jq &> /dev/null; then
        jq -r '.models | to_entries[] | "\(.key): \(.value.name) - \(.value.description)"' "$MODE_CONFIG"
    else
        echo "claude-opus-4: Claude Opus 4 - Highest capability"
        echo "claude-sonnet-3.5: Claude Sonnet 3.5 - Balanced performance"
        echo "claude-haiku-3.5: Claude Haiku 3.5 - Fast responses"
    fi
    
    echo ""
    echo -e "${BLUE}📋 Available Modes${NC}"
    echo "================="
    
    if [ -f "$MODE_CONFIG" ] && command -v jq &> /dev/null; then
        jq -r '.modes | to_entries[] | "\(.key): \(.value.name) - \(.value.description)"' "$MODE_CONFIG"
    else
        echo "default: Default Mode - Standard interactive mode"
        echo "plan: Plan Mode - Structured task planning"
        echo "auto: Auto-Accept Mode - Automatic execution"
        echo "speed: Speed Mode - Optimized for fast responses"
    fi
}

# Recommend model based on task
recommend_model() {
    local task="$1"
    
    echo -e "${BLUE}🤖 Model Recommendation${NC}"
    echo "======================"
    echo -e "${PURPLE}Task:${NC} $task"
    
    # Simple keyword-based recommendation
    if echo "$task" | grep -qi "complex\|architecture\|design\|analysis\|research\|difficult\|detailed\|comprehensive"; then
        echo -e "${GREEN}Recommended Model: Claude Opus 4${NC}"
        echo -e "${BLUE}Reason: Complex reasoning and analysis required${NC}"
        echo ""
        echo "Would you like to switch? Run: claude-mode model opus"
        
    elif echo "$task" | grep -qi "quick\|simple\|format\|edit\|small\|basic\|fix\|correct"; then
        echo -e "${GREEN}Recommended Model: Claude Haiku 3.5${NC}"
        echo -e "${BLUE}Reason: Simple task that can be completed quickly${NC}"
        echo ""
        echo "Would you like to switch? Run: claude-mode model haiku"
        
    else
        echo -e "${GREEN}Recommended Model: Claude Sonnet 3.5${NC}"
        echo -e "${BLUE}Reason: Balanced capability and speed${NC}"
        echo ""
        echo "Would you like to switch? Run: claude-mode model sonnet"
    fi
}

# Create keyboard shortcuts
create_shortcuts() {
    echo -e "${BLUE}⌨️ Setting up keyboard shortcuts${NC}"
    
    # Create AppleScript for shortcuts
    local shortcuts_dir="$CLAUDE_CONFIG_DIR/shortcuts"
    mkdir -p "$shortcuts_dir"
    
    # Plan mode shortcut
    cat > "$shortcuts_dir/plan-mode.scpt" << 'EOF'
tell application "System Events"
    tell process "Claude"
        keystroke "Shift+Tab Shift+Tab"
    end tell
end tell
EOF
    
    # Auto-accept mode shortcut
    cat > "$shortcuts_dir/auto-mode.scpt" << 'EOF'
tell application "System Events"
    tell process "Claude"
        keystroke "Cmd+Shift+A"
    end tell
end tell
EOF
    
    echo -e "${GREEN}✅ Keyboard shortcuts created${NC}"
    echo "Use System Preferences > Keyboard > Shortcuts to assign hotkeys"
}

# Main command dispatcher
main() {
    local command="${1:-help}"
    
    case "$command" in
        "init")
            init_mode_manager
            ;;
        "model")
            if [ $# -lt 2 ]; then
                echo "Usage: claude-mode model <model-name>"
                echo "Available models: opus, sonnet, haiku"
                return 1
            fi
            switch_model "$2"
            ;;
        "mode")
            if [ $# -lt 2 ]; then
                echo "Usage: claude-mode mode <mode-name>"
                echo "Available modes: default, plan, auto, speed"
                return 1
            fi
            switch_mode "$2"
            ;;
        "status")
            show_status
            ;;
        "list")
            list_options
            ;;
        "recommend")
            if [ $# -lt 2 ]; then
                echo "Usage: claude-mode recommend <task-description>"
                return 1
            fi
            recommend_model "${*:2}"
            ;;
        "shortcuts")
            create_shortcuts
            ;;
        "help"|"-h"|"--help")
            echo "Claude Mode Manager"
            echo ""
            echo "Usage: claude-mode <command> [options]"
            echo ""
            echo "Commands:"
            echo "  init                    Initialize mode manager"
            echo "  model <name>           Switch to different model"
            echo "  mode <name>            Switch to different mode"
            echo "  status                 Show current status"
            echo "  list                   List available models and modes"
            echo "  recommend <task>       Get model recommendation"
            echo "  shortcuts              Create keyboard shortcuts"
            echo "  help                   Show this help message"
            echo ""
            echo "Models:"
            echo "  opus                   Claude Opus 4 (highest capability)"
            echo "  sonnet                 Claude Sonnet 3.5 (balanced)"
            echo "  haiku                  Claude Haiku 3.5 (fastest)"
            echo ""
            echo "Modes:"
            echo "  default                Standard interactive mode"
            echo "  plan                   Structured task planning"
            echo "  auto                   Auto-accept safe commands"
            echo "  speed                  Optimized for fast responses"
            echo ""
            echo "Examples:"
            echo "  claude-mode model opus"
            echo "  claude-mode mode plan"
            echo "  claude-mode recommend 'complex database design'"
            echo "  claude-mode status"
            ;;
        *)
            echo "Unknown command: $command"
            echo "Run 'claude-mode help' for usage information"
            return 1
            ;;
    esac
}

# Initialize on first run
if [ ! -f "$MODE_CONFIG" ]; then
    echo -e "${YELLOW}🔧 First run: Initializing mode manager...${NC}"
    init_mode_manager
fi

# Run main function
main "$@"