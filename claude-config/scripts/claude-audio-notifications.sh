#!/bin/bash
# Claude Code Audio Notification System
# Project-specific audio cues and notifications

set -euo pipefail

# Configuration
CLAUDE_CONFIG_DIR="$HOME/.config/claude"
AUDIO_DIR="$CLAUDE_CONFIG_DIR/audio"
AUDIO_CONFIG="$AUDIO_DIR/audio-config.json"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

# Initialize audio system
init_audio_system() {
    mkdir -p "$AUDIO_DIR"
    mkdir -p "$AUDIO_DIR/project-sounds"
    mkdir -p "$AUDIO_DIR/system-sounds"
    
    # Create audio configuration
    if [ ! -f "$AUDIO_CONFIG" ]; then
        cat > "$AUDIO_CONFIG" << 'EOF'
{
  "version": "1.0.0",
  "enabled": true,
  "volume": 0.7,
  "systemSounds": {
    "taskComplete": "system-sounds/task-complete.aiff",
    "error": "system-sounds/error.aiff",
    "warning": "system-sounds/warning.aiff",
    "success": "system-sounds/success.aiff",
    "notification": "system-sounds/notification.aiff"
  },
  "projectSounds": {},
  "voiceSettings": {
    "enabled": true,
    "voice": "Samantha",
    "rate": 180,
    "volume": 0.8
  },
  "contextualSounds": {
    "git": "system-sounds/git-action.aiff",
    "build": "system-sounds/build-complete.aiff",
    "test": "system-sounds/test-complete.aiff",
    "deploy": "system-sounds/deploy-complete.aiff"
  }
}
EOF
    fi
    
    # Create default system sounds
    create_system_sounds
    
    echo -e "${GREEN}✅ Audio notification system initialized${NC}"
}

# Create system sounds using macOS built-in sounds
create_system_sounds() {
    local sounds_dir="$AUDIO_DIR/system-sounds"
    
    # Check if we have access to system sounds
    if [ -d "/System/Library/Sounds" ]; then
        # Create symbolic links to system sounds
        ln -sf "/System/Library/Sounds/Glass.aiff" "$sounds_dir/task-complete.aiff" 2>/dev/null || true
        ln -sf "/System/Library/Sounds/Basso.aiff" "$sounds_dir/error.aiff" 2>/dev/null || true
        ln -sf "/System/Library/Sounds/Ping.aiff" "$sounds_dir/warning.aiff" 2>/dev/null || true
        ln -sf "/System/Library/Sounds/Blow.aiff" "$sounds_dir/success.aiff" 2>/dev/null || true
        ln -sf "/System/Library/Sounds/Purr.aiff" "$sounds_dir/notification.aiff" 2>/dev/null || true
        ln -sf "/System/Library/Sounds/Morse.aiff" "$sounds_dir/git-action.aiff" 2>/dev/null || true
        ln -sf "/System/Library/Sounds/Tink.aiff" "$sounds_dir/build-complete.aiff" 2>/dev/null || true
        ln -sf "/System/Library/Sounds/Pop.aiff" "$sounds_dir/test-complete.aiff" 2>/dev/null || true
        ln -sf "/System/Library/Sounds/Sosumi.aiff" "$sounds_dir/deploy-complete.aiff" 2>/dev/null || true
    else
        echo -e "${YELLOW}⚠️  System sounds not available, using voice only${NC}"
    fi
}

# Play sound effect
play_sound() {
    local sound_type="$1"
    local message="${2:-}"
    
    if [ ! -f "$AUDIO_CONFIG" ]; then
        init_audio_system
    fi
    
    # Check if audio is enabled
    local audio_enabled
    audio_enabled=$(get_config_value "enabled" "true")
    
    if [ "$audio_enabled" = "false" ]; then
        return 0
    fi
    
    # Get sound file path
    local sound_file
    sound_file=$(get_sound_file "$sound_type")
    
    # Play sound if file exists
    if [ -f "$sound_file" ]; then
        local volume
        volume=$(get_config_value "volume" "0.7")
        
        if command -v afplay &> /dev/null; then
            afplay "$sound_file" -v "$volume" 2>/dev/null &
        elif command -v play &> /dev/null; then
            play "$sound_file" -v "$volume" 2>/dev/null &
        fi
    fi
    
    # Play voice notification if enabled and message provided
    if [ -n "$message" ]; then
        play_voice_notification "$message"
    fi
}

# Play voice notification
play_voice_notification() {
    local message="$1"
    
    local voice_enabled
    voice_enabled=$(get_config_value "voiceSettings.enabled" "true")
    
    if [ "$voice_enabled" = "false" ]; then
        return 0
    fi
    
    local voice
    voice=$(get_config_value "voiceSettings.voice" "Samantha")
    
    local rate
    rate=$(get_config_value "voiceSettings.rate" "180")
    
    local volume
    volume=$(get_config_value "voiceSettings.volume" "0.8")
    
    if command -v say &> /dev/null; then
        say -v "$voice" -r "$rate" -v "$volume" "$message" 2>/dev/null &
    fi
}

# Get sound file path
get_sound_file() {
    local sound_type="$1"
    
    # Check for project-specific sound first
    local project_name
    project_name=$(get_project_name)
    
    if [ -n "$project_name" ]; then
        local project_sound="$AUDIO_DIR/project-sounds/$project_name-$sound_type.aiff"
        if [ -f "$project_sound" ]; then
            echo "$project_sound"
            return 0
        fi
    fi
    
    # Fall back to system sound
    local system_sound
    case "$sound_type" in
        "complete"|"success"|"taskComplete")
            system_sound="$AUDIO_DIR/system-sounds/task-complete.aiff"
            ;;
        "error"|"fail")
            system_sound="$AUDIO_DIR/system-sounds/error.aiff"
            ;;
        "warning"|"warn")
            system_sound="$AUDIO_DIR/system-sounds/warning.aiff"
            ;;
        "notification"|"info")
            system_sound="$AUDIO_DIR/system-sounds/notification.aiff"
            ;;
        "git")
            system_sound="$AUDIO_DIR/system-sounds/git-action.aiff"
            ;;
        "build")
            system_sound="$AUDIO_DIR/system-sounds/build-complete.aiff"
            ;;
        "test")
            system_sound="$AUDIO_DIR/system-sounds/test-complete.aiff"
            ;;
        "deploy")
            system_sound="$AUDIO_DIR/system-sounds/deploy-complete.aiff"
            ;;
        *)
            system_sound="$AUDIO_DIR/system-sounds/notification.aiff"
            ;;
    esac
    
    echo "$system_sound"
}

# Get project name
get_project_name() {
    local current_dir="$(pwd)"
    local project_name=""
    
    # Try to get project name from git
    if [ -d ".git" ]; then
        project_name=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null || echo "")
    fi
    
    # Fall back to directory name
    if [ -z "$project_name" ]; then
        project_name=$(basename "$current_dir")
    fi
    
    echo "$project_name"
}

# Get configuration value
get_config_value() {
    local key="$1"
    local default="$2"
    
    if [ -f "$AUDIO_CONFIG" ] && command -v jq &> /dev/null; then
        jq -r ".$key // \"$default\"" "$AUDIO_CONFIG" 2>/dev/null || echo "$default"
    else
        echo "$default"
    fi
}

# Set configuration value
set_config_value() {
    local key="$1"
    local value="$2"
    
    if [ -f "$AUDIO_CONFIG" ] && command -v jq &> /dev/null; then
        local temp_config="/tmp/audio_config.json"
        jq ".$key = \"$value\"" "$AUDIO_CONFIG" > "$temp_config"
        mv "$temp_config" "$AUDIO_CONFIG"
    fi
}

# Create project-specific sound
create_project_sound() {
    local project_name="$1"
    local sound_type="$2"
    local source_file="$3"
    
    local project_sound="$AUDIO_DIR/project-sounds/$project_name-$sound_type.aiff"
    
    if [ -f "$source_file" ]; then
        cp "$source_file" "$project_sound"
        echo -e "${GREEN}✅ Created project sound: $project_sound${NC}"
    else
        echo -e "${RED}❌ Source file not found: $source_file${NC}"
        return 1
    fi
}

# List available sounds
list_sounds() {
    echo -e "${BLUE}🔊 Available Audio Notifications${NC}"
    echo "=================================="
    
    echo -e "${PURPLE}System Sounds:${NC}"
    if [ -d "$AUDIO_DIR/system-sounds" ]; then
        find "$AUDIO_DIR/system-sounds" -name "*.aiff" -exec basename {} \; | sort
    else
        echo "  None found"
    fi
    
    echo -e "${PURPLE}Project Sounds:${NC}"
    if [ -d "$AUDIO_DIR/project-sounds" ]; then
        find "$AUDIO_DIR/project-sounds" -name "*.aiff" -exec basename {} \; | sort
    else
        echo "  None found"
    fi
    
    echo -e "${PURPLE}Voice Settings:${NC}"
    echo "  Enabled: $(get_config_value "voiceSettings.enabled" "true")"
    echo "  Voice: $(get_config_value "voiceSettings.voice" "Samantha")"
    echo "  Rate: $(get_config_value "voiceSettings.rate" "180")"
    echo "  Volume: $(get_config_value "voiceSettings.volume" "0.8")"
}

# Test sound
test_sound() {
    local sound_type="${1:-complete}"
    local message="${2:-Test notification}"
    
    echo -e "${BLUE}🔊 Testing sound: $sound_type${NC}"
    echo -e "${BLUE}📢 Message: $message${NC}"
    
    play_sound "$sound_type" "$message"
}

# Configure audio settings
configure_audio() {
    local setting="$1"
    local value="$2"
    
    case "$setting" in
        "enable")
            set_config_value "enabled" "true"
            echo -e "${GREEN}✅ Audio notifications enabled${NC}"
            ;;
        "disable")
            set_config_value "enabled" "false"
            echo -e "${YELLOW}⚠️  Audio notifications disabled${NC}"
            ;;
        "volume")
            set_config_value "volume" "$value"
            echo -e "${GREEN}✅ Volume set to $value${NC}"
            ;;
        "voice")
            set_config_value "voiceSettings.voice" "$value"
            echo -e "${GREEN}✅ Voice set to $value${NC}"
            ;;
        "voice-rate")
            set_config_value "voiceSettings.rate" "$value"
            echo -e "${GREEN}✅ Voice rate set to $value${NC}"
            ;;
        "voice-volume")
            set_config_value "voiceSettings.volume" "$value"
            echo -e "${GREEN}✅ Voice volume set to $value${NC}"
            ;;
        "voice-enable")
            set_config_value "voiceSettings.enabled" "true"
            echo -e "${GREEN}✅ Voice notifications enabled${NC}"
            ;;
        "voice-disable")
            set_config_value "voiceSettings.enabled" "false"
            echo -e "${YELLOW}⚠️  Voice notifications disabled${NC}"
            ;;
        *)
            echo -e "${RED}❌ Unknown setting: $setting${NC}"
            return 1
            ;;
    esac
}

# Context-aware notification
context_notify() {
    local context="$1"
    local message="$2"
    local success="${3:-true}"
    
    local sound_type="complete"
    
    # Determine sound based on context
    case "$context" in
        "git")
            sound_type="git"
            ;;
        "build")
            sound_type="build"
            ;;
        "test")
            sound_type="test"
            ;;
        "deploy")
            sound_type="deploy"
            ;;
        "error")
            sound_type="error"
            ;;
        *)
            sound_type="complete"
            ;;
    esac
    
    # Modify sound for failure
    if [ "$success" = "false" ]; then
        sound_type="error"
    fi
    
    play_sound "$sound_type" "$message"
}

# Main command dispatcher
main() {
    local command="${1:-help}"
    
    case "$command" in
        "init")
            init_audio_system
            ;;
        "play")
            if [ $# -lt 2 ]; then
                echo "Usage: claude-audio play <sound-type> [message]"
                return 1
            fi
            test_sound "$2" "${3:-}"
            ;;
        "test")
            test_sound "${2:-complete}" "${3:-Test notification}"
            ;;
        "list")
            list_sounds
            ;;
        "configure")
            if [ $# -lt 2 ]; then
                echo "Usage: claude-audio configure <setting> [value]"
                return 1
            fi
            configure_audio "$2" "${3:-}"
            ;;
        "context")
            if [ $# -lt 3 ]; then
                echo "Usage: claude-audio context <context> <message> [success]"
                return 1
            fi
            context_notify "$2" "$3" "${4:-true}"
            ;;
        "project")
            if [ $# -lt 4 ]; then
                echo "Usage: claude-audio project <project-name> <sound-type> <source-file>"
                return 1
            fi
            create_project_sound "$2" "$3" "$4"
            ;;
        "status")
            echo -e "${BLUE}🔊 Audio Notification Status${NC}"
            echo "Enabled: $(get_config_value "enabled" "true")"
            echo "Volume: $(get_config_value "volume" "0.7")"
            echo "Voice Enabled: $(get_config_value "voiceSettings.enabled" "true")"
            echo "Voice: $(get_config_value "voiceSettings.voice" "Samantha")"
            echo "Config: $AUDIO_CONFIG"
            ;;
        "help"|"-h"|"--help")
            echo "Claude Audio Notification System"
            echo ""
            echo "Usage: claude-audio <command> [options]"
            echo ""
            echo "Commands:"
            echo "  init                     Initialize audio system"
            echo "  play <type> [message]    Play sound with optional voice"
            echo "  test [type] [message]    Test sound (default: complete)"
            echo "  list                     List available sounds"
            echo "  configure <setting> [value] Configure audio settings"
            echo "  context <ctx> <msg> [success] Context-aware notification"
            echo "  project <name> <type> <file> Create project sound"
            echo "  status                   Show audio system status"
            echo "  help                     Show this help message"
            echo ""
            echo "Sound Types:"
            echo "  complete, success, error, warning, notification"
            echo "  git, build, test, deploy"
            echo ""
            echo "Configuration:"
            echo "  enable/disable           Enable/disable audio"
            echo "  volume <0.0-1.0>        Set sound volume"
            echo "  voice <name>            Set voice name"
            echo "  voice-rate <rate>       Set voice rate"
            echo "  voice-volume <0.0-1.0>  Set voice volume"
            echo "  voice-enable/disable    Enable/disable voice"
            echo ""
            echo "Examples:"
            echo "  claude-audio test complete \"Task completed successfully\""
            echo "  claude-audio configure volume 0.8"
            echo "  claude-audio context git \"Repository updated\" true"
            ;;
        *)
            echo "Unknown command: $command"
            echo "Run 'claude-audio help' for usage information"
            return 1
            ;;
    esac
}

# Initialize on first run
if [ ! -d "$AUDIO_DIR" ]; then
    echo -e "${YELLOW}🔧 First run: Initializing audio system...${NC}"
    init_audio_system
fi

# Run main function
main "$@"