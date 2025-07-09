#!/bin/bash
# Claude Code IDE Integration Enhancement
# Advanced file handling and editor integration

set -euo pipefail

# Configuration
CLAUDE_CONFIG_DIR="$HOME/.config/claude"
IDE_CONFIG_DIR="$CLAUDE_CONFIG_DIR/ide"
FILE_CONTEXT_FILE="$IDE_CONFIG_DIR/file-context.json"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Initialize IDE integration
init_ide_integration() {
    mkdir -p "$IDE_CONFIG_DIR"
    
    # Create file context database
    if [ ! -f "$FILE_CONTEXT_FILE" ]; then
        cat > "$FILE_CONTEXT_FILE" << 'EOF'
{
  "version": "1.0.0",
  "activeFiles": [],
  "recentFiles": [],
  "projectStructure": {},
  "fileReferences": {},
  "workspaceSettings": {
    "editor": "auto-detect",
    "autoFileDetection": true,
    "dragDropEnabled": true,
    "screenshotAnalysis": true
  }
}
EOF
    fi
    
    echo -e "${GREEN}✅ IDE integration initialized${NC}"
}

# Detect active IDE
detect_ide() {
    local ide_type="unknown"
    
    # Check for VS Code
    if pgrep -x "code" > /dev/null || pgrep -x "Code" > /dev/null; then
        ide_type="vscode"
    # Check for Cursor
    elif pgrep -x "cursor" > /dev/null || pgrep -x "Cursor" > /dev/null; then
        ide_type="cursor"
    # Check for other editors
    elif pgrep -x "subl" > /dev/null; then
        ide_type="sublime"
    elif pgrep -x "atom" > /dev/null; then
        ide_type="atom"
    fi
    
    echo "$ide_type"
}

# Get workspace information
get_workspace_info() {
    local workspace_path="$(pwd)"
    local ide_type="$(detect_ide)"
    
    # Try to get VS Code workspace
    if [ "$ide_type" = "vscode" ] && command -v code &> /dev/null; then
        # Check if current directory is a VS Code workspace
        if [ -d ".vscode" ]; then
            workspace_path="$(pwd)"
        fi
    fi
    
    # Try to get Cursor workspace
    if [ "$ide_type" = "cursor" ] && command -v cursor &> /dev/null; then
        if [ -d ".cursor" ]; then
            workspace_path="$(pwd)"
        fi
    fi
    
    echo "$workspace_path"
}

# Process file reference (@filename)
process_file_reference() {
    local file_ref="$1"
    local workspace_path="$(get_workspace_info)"
    
    # Remove @ symbol
    local file_path="${file_ref#@}"
    
    # Handle different reference types
    if [[ "$file_path" == *"/"* ]]; then
        # Directory reference
        if [ -d "$workspace_path/$file_path" ]; then
            echo "📁 Directory: $file_path"
            ls -la "$workspace_path/$file_path" | head -10
        else
            echo "❌ Directory not found: $file_path"
        fi
    else
        # File reference
        local found_files=()
        
        # Search for exact match
        if [ -f "$workspace_path/$file_path" ]; then
            found_files+=("$workspace_path/$file_path")
        else
            # Search in common directories
            while IFS= read -r -d '' file; do
                found_files+=("$file")
            done < <(find "$workspace_path" -name "$file_path" -type f -print0 2>/dev/null | head -20)
        fi
        
        if [ ${#found_files[@]} -eq 0 ]; then
            echo "❌ File not found: $file_path"
        elif [ ${#found_files[@]} -eq 1 ]; then
            echo "📄 File: ${found_files[0]}"
            echo "---"
            head -20 "${found_files[0]}"
        else
            echo "🔍 Multiple files found for: $file_path"
            for file in "${found_files[@]}"; do
                echo "  - $file"
            done
        fi
    fi
}

# Setup drag-and-drop simulation
setup_drag_drop() {
    echo -e "${BLUE}🎯 Setting up drag-and-drop simulation...${NC}"
    
    # Create AppleScript for drag-and-drop detection
    cat > "$IDE_CONFIG_DIR/drag-drop-detector.applescript" << 'EOF'
on run argv
    set filePath to item 1 of argv
    set fileInfo to info for (POSIX file filePath)
    
    return "File: " & filePath & "\n" & 
           "Type: " & (name extension of fileInfo) & "\n" & 
           "Size: " & (size of fileInfo) & " bytes\n" & 
           "Modified: " & (modification date of fileInfo)
end run
EOF
    
    echo -e "${GREEN}✅ Drag-and-drop simulation ready${NC}"
}

# Analyze screenshot from clipboard
analyze_screenshot() {
    local temp_dir="/tmp/claude-screenshots"
    local screenshot_file="$temp_dir/screenshot-$(date +%s).png"
    
    mkdir -p "$temp_dir"
    
    # Check if there's an image in clipboard (macOS)
    if command -v pngpaste &> /dev/null; then
        if pngpaste "$screenshot_file" 2>/dev/null; then
            echo -e "${GREEN}📸 Screenshot captured${NC}"
            echo "File: $screenshot_file"
            
            # Basic image analysis
            if command -v file &> /dev/null; then
                file "$screenshot_file"
            fi
            
            # Try to extract text if tesseract is available
            if command -v tesseract &> /dev/null; then
                echo -e "${BLUE}🔍 Extracting text from screenshot...${NC}"
                tesseract "$screenshot_file" "$temp_dir/screenshot-text" 2>/dev/null
                if [ -f "$temp_dir/screenshot-text.txt" ]; then
                    echo "Extracted text:"
                    head -20 "$temp_dir/screenshot-text.txt"
                fi
            fi
            
            return 0
        else
            echo -e "${RED}❌ No image found in clipboard${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  pngpaste not available. Install with: brew install pngpaste${NC}"
        return 1
    fi
}

# Get project structure
get_project_structure() {
    local workspace_path="$(get_workspace_info)"
    
    echo -e "${BLUE}📁 Project Structure:${NC}"
    echo "Workspace: $workspace_path"
    
    # Get git status if available
    if [ -d "$workspace_path/.git" ]; then
        echo -e "${GREEN}📊 Git Status:${NC}"
        cd "$workspace_path"
        git status --porcelain | head -20
    fi
    
    # Show project structure
    echo -e "${GREEN}📂 Directory Structure:${NC}"
    tree -L 3 -I 'node_modules|.git|venv|__pycache__' "$workspace_path" 2>/dev/null || \
    find "$workspace_path" -type d -name 'node_modules' -prune -o -type d -name '.git' -prune -o -type f -print | head -50
}

# Update file context
update_file_context() {
    local action="$1"
    local file_path="$2"
    
    # This would update the file context database
    # For now, just log the action
    echo "$(date): $action - $file_path" >> "$IDE_CONFIG_DIR/file-activity.log"
}

# Main command dispatcher
main() {
    local command="${1:-help}"
    
    case "$command" in
        "init")
            init_ide_integration
            setup_drag_drop
            ;;
        "detect")
            echo "IDE: $(detect_ide)"
            echo "Workspace: $(get_workspace_info)"
            ;;
        "reference")
            if [ $# -lt 2 ]; then
                echo "Usage: claude-ide reference @filename"
                return 1
            fi
            process_file_reference "$2"
            ;;
        "screenshot")
            analyze_screenshot
            ;;
        "structure")
            get_project_structure
            ;;
        "status")
            echo -e "${BLUE}📊 IDE Integration Status${NC}"
            echo "IDE: $(detect_ide)"
            echo "Workspace: $(get_workspace_info)"
            echo "Config: $IDE_CONFIG_DIR"
            if [ -f "$FILE_CONTEXT_FILE" ]; then
                echo "✅ File context initialized"
            else
                echo "❌ File context not initialized"
            fi
            ;;
        "help"|"-h"|"--help")
            echo "Claude IDE Integration Commands"
            echo ""
            echo "Usage: claude-ide <command> [options]"
            echo ""
            echo "Commands:"
            echo "  init              Initialize IDE integration"
            echo "  detect            Detect active IDE and workspace"
            echo "  reference @file   Process file reference"
            echo "  screenshot        Analyze screenshot from clipboard"
            echo "  structure         Show project structure"
            echo "  status            Show integration status"
            echo "  help              Show this help message"
            echo ""
            echo "File Reference Examples:"
            echo "  claude-ide reference @package.json"
            echo "  claude-ide reference @src/components/"
            echo "  claude-ide reference @README.md"
            ;;
        *)
            echo "Unknown command: $command"
            echo "Run 'claude-ide help' for usage information"
            return 1
            ;;
    esac
}

# Initialize on first run
if [ ! -d "$IDE_CONFIG_DIR" ]; then
    echo -e "${YELLOW}🔧 First run: Initializing IDE integration...${NC}"
    init_ide_integration
fi

# Run main function
main "$@"