#!/bin/bash
# Claude Code Clipboard-to-File Utility
# Intelligent file creation from clipboard content

set -euo pipefail

# Configuration
CLAUDE_CONFIG_DIR="$HOME/.config/claude"
CLIPBOARD_DIR="$CLAUDE_CONFIG_DIR/clipboard"
CLIPBOARD_CONFIG="$CLIPBOARD_DIR/clipboard-config.json"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

# Initialize clipboard utility
init_clipboard_utility() {
    mkdir -p "$CLIPBOARD_DIR"
    mkdir -p "$CLIPBOARD_DIR/temp"
    
    # Create configuration
    if [ ! -f "$CLIPBOARD_CONFIG" ]; then
        cat > "$CLIPBOARD_CONFIG" << 'EOF'
{
  "version": "1.0.0",
  "enabled": true,
  "autoDetection": {
    "enabled": true,
    "languages": ["javascript", "python", "bash", "html", "css", "json", "yaml", "xml", "sql"],
    "confidence": 0.8
  },
  "fileNaming": {
    "useClaudeAnalysis": true,
    "fallbackPrefix": "clipboard-",
    "timestampFormat": "%Y%m%d-%H%M%S",
    "maxFilenameLength": 50
  },
  "outputDirectory": ".",
  "backup": {
    "enabled": true,
    "directory": "~/.config/claude/clipboard/backup"
  },
  "integrations": {
    "raycast": true,
    "automator": true,
    "quickAction": true
  }
}
EOF
    fi
    
    echo -e "${GREEN}✅ Clipboard utility initialized${NC}"
}

# Get clipboard content
get_clipboard_content() {
    if command -v pbpaste &> /dev/null; then
        pbpaste
    elif command -v xclip &> /dev/null; then
        xclip -selection clipboard -o
    else
        echo -e "${RED}❌ No clipboard utility found${NC}"
        return 1
    fi
}

# Detect content type
detect_content_type() {
    local content="$1"
    
    # Check for common programming languages
    if echo "$content" | grep -q "function\|const\|let\|var\|=>" && echo "$content" | grep -q "{"; then
        echo "javascript"
    elif echo "$content" | grep -q "def\|import\|from\|print\|if __name__"; then
        echo "python"
    elif echo "$content" | grep -q "#!/bin/bash\|#!/bin/sh\|function\|if \["; then
        echo "bash"
    elif echo "$content" | grep -q "<!DOCTYPE\|<html\|<div\|<span"; then
        echo "html"
    elif echo "$content" | grep -q "{\|}\|:\|;\|@media\|#\|\."; then
        echo "css"
    elif echo "$content" | grep -q "{\|}\|:\|\""; then
        echo "json"
    elif echo "$content" | grep -q "---\|:\|  -\|^  "; then
        echo "yaml"
    elif echo "$content" | grep -q "<?xml\|<\|>"; then
        echo "xml"
    elif echo "$content" | grep -q "SELECT\|INSERT\|UPDATE\|DELETE\|CREATE\|DROP" && echo "$content" | grep -qi "FROM\|WHERE\|TABLE"; then
        echo "sql"
    elif echo "$content" | grep -q "# \|## \|### \|#### \|##### \|###### "; then
        echo "markdown"
    else
        echo "text"
    fi
}

# Get file extension for content type
get_file_extension() {
    local content_type="$1"
    
    case "$content_type" in
        "javascript") echo "js" ;;
        "python") echo "py" ;;
        "bash") echo "sh" ;;
        "html") echo "html" ;;
        "css") echo "css" ;;
        "json") echo "json" ;;
        "yaml") echo "yml" ;;
        "xml") echo "xml" ;;
        "sql") echo "sql" ;;
        "markdown") echo "md" ;;
        *) echo "txt" ;;
    esac
}

# Generate intelligent filename using Claude
generate_filename() {
    local content="$1"
    local content_type="$2"
    local extension="$3"
    
    # Create a temporary prompt file
    local temp_prompt="/tmp/claude-filename-prompt.txt"
    
    cat > "$temp_prompt" << EOF
Please analyze this ${content_type} content and suggest a descriptive filename (without extension):

Requirements:
- Be descriptive but concise (max 50 characters)
- Use kebab-case (lowercase with hyphens)
- Focus on the main purpose/functionality
- Avoid generic names like "code" or "snippet"

Content:
\`\`\`${content_type}
${content}
\`\`\`

Please respond with ONLY the filename (no extension, no explanation).
EOF
    
    # Try to get filename from Claude
    local suggested_name=""
    
    # Check if Claude CLI is available
    if command -v claude &> /dev/null; then
        suggested_name=$(claude --no-stream < "$temp_prompt" 2>/dev/null | head -1 | tr -d '\n\r' | sed 's/[^a-zA-Z0-9-]//g' | head -c 50)
    fi
    
    # Fallback to simple analysis
    if [ -z "$suggested_name" ] || [ ${#suggested_name} -lt 3 ]; then
        suggested_name=$(generate_simple_filename "$content" "$content_type")
    fi
    
    # Clean up
    rm -f "$temp_prompt"
    
    # Ensure filename is valid
    if [ -z "$suggested_name" ]; then
        suggested_name="clipboard-$(date +%Y%m%d-%H%M%S)"
    fi
    
    echo "${suggested_name}.${extension}"
}

# Generate simple filename based on content analysis
generate_simple_filename() {
    local content="$1"
    local content_type="$2"
    
    local name=""
    
    case "$content_type" in
        "javascript")
            if echo "$content" | grep -q "function.*(" | head -1; then
                name=$(echo "$content" | grep -o "function [a-zA-Z_][a-zA-Z0-9_]*" | head -1 | cut -d' ' -f2)
            elif echo "$content" | grep -q "const.*=" | head -1; then
                name=$(echo "$content" | grep -o "const [a-zA-Z_][a-zA-Z0-9_]*" | head -1 | cut -d' ' -f2)
            fi
            ;;
        "python")
            if echo "$content" | grep -q "def " | head -1; then
                name=$(echo "$content" | grep -o "def [a-zA-Z_][a-zA-Z0-9_]*" | head -1 | cut -d' ' -f2)
            elif echo "$content" | grep -q "class " | head -1; then
                name=$(echo "$content" | grep -o "class [a-zA-Z_][a-zA-Z0-9_]*" | head -1 | cut -d' ' -f2)
            fi
            ;;
        "bash")
            if echo "$content" | grep -q "^#!/bin/bash" | head -1; then
                name="bash-script"
            elif echo "$content" | grep -q "function " | head -1; then
                name=$(echo "$content" | grep -o "function [a-zA-Z_][a-zA-Z0-9_]*" | head -1 | cut -d' ' -f2)
            fi
            ;;
        "html")
            if echo "$content" | grep -q "<title>" | head -1; then
                name=$(echo "$content" | grep -o "<title>[^<]*" | head -1 | cut -d'>' -f2 | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
            else
                name="html-page"
            fi
            ;;
        "css")
            name="styles"
            ;;
        "json")
            name="data"
            ;;
        *)
            name="clipboard-content"
            ;;
    esac
    
    # Convert to kebab-case and clean
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
    
    # Fallback if empty
    if [ -z "$name" ]; then
        name="clipboard-$(date +%H%M%S)"
    fi
    
    echo "$name"
}

# Save clipboard content to file
save_clipboard_to_file() {
    local output_dir="${1:-.}"
    local filename="$2"
    
    # Get clipboard content
    local content
    if ! content=$(get_clipboard_content); then
        return 1
    fi
    
    if [ -z "$content" ]; then
        echo -e "${RED}❌ Clipboard is empty${NC}"
        return 1
    fi
    
    # Detect content type
    local content_type
    content_type=$(detect_content_type "$content")
    
    echo -e "${BLUE}📋 Detected content type: $content_type${NC}"
    
    # Generate filename if not provided
    if [ -z "$filename" ]; then
        local extension
        extension=$(get_file_extension "$content_type")
        filename=$(generate_filename "$content" "$content_type" "$extension")
    fi
    
    # Ensure output directory exists
    mkdir -p "$output_dir"
    
    # Full file path
    local file_path="$output_dir/$filename"
    
    # Check if file exists
    if [ -f "$file_path" ]; then
        echo -e "${YELLOW}⚠️  File exists: $file_path${NC}"
        echo -e "${YELLOW}   Creating backup...${NC}"
        
        # Create backup
        local backup_dir="$CLIPBOARD_DIR/backup"
        mkdir -p "$backup_dir"
        cp "$file_path" "$backup_dir/$(basename "$file_path").backup.$(date +%Y%m%d-%H%M%S)"
    fi
    
    # Save content to file
    echo "$content" > "$file_path"
    
    echo -e "${GREEN}✅ Saved clipboard content to: $file_path${NC}"
    echo -e "${BLUE}📊 Content type: $content_type${NC}"
    echo -e "${BLUE}📏 Size: $(wc -c < "$file_path") bytes${NC}"
    echo -e "${BLUE}📄 Lines: $(wc -l < "$file_path") lines${NC}"
    
    # Audio notification
    if [ -x ~/.config/claude/scripts/claude-audio-notifications.sh ]; then
        ~/.config/claude/scripts/claude-audio-notifications.sh context "complete" "File saved from clipboard" true &
    fi
    
    # Return file path for external use
    echo "$file_path"
}

# Interactive mode
interactive_mode() {
    echo -e "${BLUE}🎯 Claude Clipboard-to-File Interactive Mode${NC}"
    echo "==========================================="
    
    # Get clipboard content
    local content
    if ! content=$(get_clipboard_content); then
        return 1
    fi
    
    if [ -z "$content" ]; then
        echo -e "${RED}❌ Clipboard is empty${NC}"
        return 1
    fi
    
    # Show content preview
    echo -e "${PURPLE}📋 Clipboard Content Preview:${NC}"
    echo "$content" | head -10
    if [ $(echo "$content" | wc -l) -gt 10 ]; then
        echo "... (truncated)"
    fi
    echo ""
    
    # Detect content type
    local content_type
    content_type=$(detect_content_type "$content")
    
    echo -e "${BLUE}🔍 Detected content type: $content_type${NC}"
    
    # Generate suggested filename
    local extension
    extension=$(get_file_extension "$content_type")
    local suggested_filename
    suggested_filename=$(generate_filename "$content" "$content_type" "$extension")
    
    echo -e "${GREEN}💡 Suggested filename: $suggested_filename${NC}"
    
    # Get user input
    echo -n "Enter filename (or press Enter to use suggested): "
    read -r user_filename
    
    if [ -z "$user_filename" ]; then
        user_filename="$suggested_filename"
    fi
    
    # Get output directory
    echo -n "Enter output directory (or press Enter for current): "
    read -r output_dir
    
    if [ -z "$output_dir" ]; then
        output_dir="."
    fi
    
    # Save file
    save_clipboard_to_file "$output_dir" "$user_filename"
}

# Create Raycast script
create_raycast_script() {
    local raycast_script="$HOME/.config/raycast/scripts/claude-clipboard-to-file.sh"
    
    mkdir -p "$(dirname "$raycast_script")"
    
    cat > "$raycast_script" << 'EOF'
#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Claude Clipboard to File
# @raycast.mode fullOutput
# @raycast.packageName Claude Code

# Optional parameters:
# @raycast.icon 📋
# @raycast.description Save clipboard content to file with intelligent naming
# @raycast.author Claude
# @raycast.authorURL https://github.com/anthropics/claude-code

# Run the clipboard utility
if [ -x ~/.config/claude/scripts/claude-clipboard-to-file.sh ]; then
    ~/.config/claude/scripts/claude-clipboard-to-file.sh save
else
    echo "❌ Claude clipboard utility not found"
    exit 1
fi
EOF
    
    chmod +x "$raycast_script"
    echo -e "${GREEN}✅ Raycast script created: $raycast_script${NC}"
}

# Create Automator workflow
create_automator_workflow() {
    local workflow_dir="$HOME/Library/Services"
    local workflow_name="Claude Clipboard to File.workflow"
    local workflow_path="$workflow_dir/$workflow_name"
    
    mkdir -p "$workflow_path/Contents"
    
    # Create Info.plist
    cat > "$workflow_path/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.apple.Automator.ClaudeClipboardToFile</string>
    <key>CFBundleName</key>
    <string>Claude Clipboard to File</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>Claude Clipboard to File</string>
            </dict>
            <key>NSMessage</key>
            <string>runWorkflowAsService</string>
            <key>NSRequiredContext</key>
            <array>
                <dict>
                    <key>NSApplicationIdentifier</key>
                    <string>*</string>
                </dict>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF
    
    # Create document.wflow
    cat > "$workflow_path/Contents/document.wflow" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AMApplicationBuild</key>
    <string>521</string>
    <key>AMApplicationVersion</key>
    <string>2.10</string>
    <key>actions</key>
    <array>
        <dict>
            <key>action</key>
            <dict>
                <key>AMActionVersion</key>
                <string>2.0.3</string>
                <key>AMApplication</key>
                <array>
                    <string>Automator</string>
                </array>
                <key>AMParameterProperties</key>
                <dict>
                    <key>COMMAND_STRING</key>
                    <dict>
                        <key>tokenizedValue</key>
                        <array>
                            <string>~/.config/claude/scripts/claude-clipboard-to-file.sh save</string>
                        </array>
                    </dict>
                </dict>
                <key>AMProvides</key>
                <dict>
                    <key>Container</key>
                    <string>List</string>
                    <key>Types</key>
                    <array>
                        <string>com.apple.cocoa.string</string>
                    </array>
                </dict>
                <key>ActionBundlePath</key>
                <string>/System/Library/Automator/Run Shell Script.action</string>
                <key>ActionName</key>
                <string>Run Shell Script</string>
                <key>ActionParameters</key>
                <dict>
                    <key>COMMAND_STRING</key>
                    <string>~/.config/claude/scripts/claude-clipboard-to-file.sh save</string>
                    <key>CheckedForUserDefaultShell</key>
                    <true/>
                    <key>inputMethod</key>
                    <integer>0</integer>
                    <key>shell</key>
                    <string>/bin/bash</string>
                    <key>source</key>
                    <string></string>
                </dict>
            </dict>
        </dict>
    </array>
</dict>
</plist>
EOF
    
    echo -e "${GREEN}✅ Automator workflow created: $workflow_path${NC}"
    echo -e "${BLUE}💡 The service will appear in the Services menu${NC}"
}

# Main command dispatcher
main() {
    local command="${1:-help}"
    
    case "$command" in
        "init")
            init_clipboard_utility
            ;;
        "save")
            save_clipboard_to_file "${2:-.}" "${3:-}"
            ;;
        "interactive"|"i")
            interactive_mode
            ;;
        "detect")
            local content
            if content=$(get_clipboard_content); then
                local content_type
                content_type=$(detect_content_type "$content")
                echo "Content type: $content_type"
                echo "Extension: $(get_file_extension "$content_type")"
            fi
            ;;
        "preview")
            local content
            if content=$(get_clipboard_content); then
                echo -e "${PURPLE}📋 Clipboard Content:${NC}"
                echo "$content"
            fi
            ;;
        "raycast")
            create_raycast_script
            ;;
        "automator")
            create_automator_workflow
            ;;
        "status")
            echo -e "${BLUE}📋 Clipboard Utility Status${NC}"
            echo "Config: $CLIPBOARD_CONFIG"
            echo "Backup Directory: $CLIPBOARD_DIR/backup"
            
            local content
            if content=$(get_clipboard_content); then
                echo "Clipboard has content: Yes ($(echo "$content" | wc -c) bytes)"
                echo "Content type: $(detect_content_type "$content")"
            else
                echo "Clipboard has content: No"
            fi
            ;;
        "help"|"-h"|"--help")
            echo "Claude Clipboard-to-File Utility"
            echo ""
            echo "Usage: claude-clipboard-to-file <command> [options]"
            echo ""
            echo "Commands:"
            echo "  init                    Initialize clipboard utility"
            echo "  save [dir] [filename]   Save clipboard to file"
            echo "  interactive             Interactive mode"
            echo "  detect                  Detect clipboard content type"
            echo "  preview                 Preview clipboard content"
            echo "  raycast                 Create Raycast script"
            echo "  automator              Create Automator workflow"
            echo "  status                  Show utility status"
            echo "  help                    Show this help message"
            echo ""
            echo "Examples:"
            echo "  claude-clipboard-to-file save"
            echo "  claude-clipboard-to-file save ./scripts my-script.js"
            echo "  claude-clipboard-to-file interactive"
            echo "  claude-clipboard-to-file detect"
            echo ""
            echo "Integration:"
            echo "  - Raycast: Run 'claude-clipboard-to-file raycast' to create script"
            echo "  - Automator: Run 'claude-clipboard-to-file automator' for service"
            echo "  - Quick Action: Available after creating Automator workflow"
            ;;
        *)
            echo "Unknown command: $command"
            echo "Run 'claude-clipboard-to-file help' for usage information"
            return 1
            ;;
    esac
}

# Initialize on first run
if [ ! -d "$CLIPBOARD_DIR" ]; then
    echo -e "${YELLOW}🔧 First run: Initializing clipboard utility...${NC}"
    init_clipboard_utility
fi

# Run main function
main "$@"