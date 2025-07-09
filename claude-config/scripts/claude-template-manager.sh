#!/bin/bash
#
# Claude Template Manager
# Automatically creates appropriate CLAUDE.md files based on project type
#

TEMPLATE_DIR="$HOME/.config/claude/templates"

# Function to detect project type
detect_project_type() {
    local project_path="${1:-$(pwd)}"
    
    # Check for various project indicators
    if [ -f "$project_path/package.json" ]; then
        local package_content=$(cat "$project_path/package.json" 2>/dev/null || echo "{}")
        
        # Check for React
        if echo "$package_content" | jq -e '.dependencies.react' >/dev/null 2>&1; then
            echo "react"
            return
        fi
        
        # Check for Node.js backend patterns
        if echo "$package_content" | jq -e '.dependencies.express' >/dev/null 2>&1 || \
           echo "$package_content" | jq -e '.dependencies.fastify' >/dev/null 2>&1 || \
           echo "$package_content" | jq -e '.dependencies["@nestjs/core"]' >/dev/null 2>&1; then
            echo "nodejs"
            return
        fi
        
        # Default to nodejs for any package.json project
        echo "nodejs"
        return
    fi
    
    # Check for Python
    if [ -f "$project_path/requirements.txt" ] || \
       [ -f "$project_path/pyproject.toml" ] || \
       [ -f "$project_path/setup.py" ] || \
       [ -f "$project_path/Pipfile" ]; then
        echo "python"
        return
    fi
    
    # Check for Python in directory contents
    if find "$project_path" -name "*.py" -type f | head -1 | grep -q ".*"; then
        echo "python"
        return
    fi
    
    # Check for other languages/frameworks
    if [ -f "$project_path/Cargo.toml" ]; then
        echo "rust"
        return
    fi
    
    if [ -f "$project_path/go.mod" ]; then
        echo "go"
        return
    fi
    
    if [ -f "$project_path/pom.xml" ] || [ -f "$project_path/build.gradle" ]; then
        echo "java"
        return
    fi
    
    # Default fallback
    echo "default"
}

# Function to get project information
get_project_info() {
    local project_path="${1:-$(pwd)}"
    local project_name=$(basename "$project_path")
    local date=$(date '+%Y-%m-%d')
    
    # Try to get additional info based on project type
    local python_version=""
    local node_version=""
    local react_version=""
    
    if command -v python3 &>/dev/null; then
        python_version=$(python3 --version 2>&1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
    fi
    
    if command -v node &>/dev/null; then
        node_version=$(node --version 2>&1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
    fi
    
    if [ -f "$project_path/package.json" ]; then
        react_version=$(cat "$project_path/package.json" | jq -r '.dependencies.react // empty' 2>/dev/null | sed 's/[^0-9.]//g')
    fi
    
    echo "PROJECT_NAME=$project_name"
    echo "PROJECT_PATH=$project_path"
    echo "DATE=$date"
    echo "PYTHON_VERSION=$python_version"
    echo "NODE_VERSION=$node_version"
    echo "REACT_VERSION=$react_version"
}

# Function to create CLAUDE.md from template
create_claude_md() {
    local project_type="$1"
    local project_path="${2:-$(pwd)}"
    local template_file="$TEMPLATE_DIR/CLAUDE-${project_type}.md"
    local output_file="$project_path/CLAUDE.md"
    
    if [ ! -f "$template_file" ]; then
        echo "❌ Template not found: $template_file"
        echo "💡 Using default template instead"
        template_file="$TEMPLATE_DIR/CLAUDE-default.md"
    fi
    
    if [ -f "$output_file" ]; then
        echo "⚠️  CLAUDE.md already exists in $project_path"
        echo "💡 Use 'claude-update-template' to refresh it"
        return 1
    fi
    
    # Get project variables
    local project_info=$(get_project_info "$project_path")
    
    # Create the CLAUDE.md file with variable substitution
    local temp_file=$(mktemp)
    cp "$template_file" "$temp_file"
    
    # Substitute variables
    while IFS='=' read -r key value; do
        if [ -n "$key" ] && [ -n "$value" ]; then
            sed -i.bak "s|{${key}}|${value}|g" "$temp_file"
        fi
    done <<< "$project_info"
    
    # Copy to final location
    cp "$temp_file" "$output_file"
    rm "$temp_file"
    
    echo "✅ Created CLAUDE.md for $project_type project"
    echo "📁 Location: $output_file"
    echo "💡 Edit the file to add project-specific details"
}

# Function to update existing CLAUDE.md with new template
update_claude_md() {
    local project_path="${1:-$(pwd)}"
    local output_file="$project_path/CLAUDE.md"
    
    if [ ! -f "$output_file" ]; then
        echo "❌ No CLAUDE.md found in $project_path"
        echo "💡 Use 'claude-init' to create one"
        return 1
    fi
    
    # Backup existing file
    cp "$output_file" "$output_file.backup"
    
    # Extract the "Recent Context & Instructions" section
    local context_section=""
    if grep -q "## Recent Context & Instructions" "$output_file"; then
        context_section=$(sed -n '/## Recent Context & Instructions/,$p' "$output_file")
    fi
    
    # Detect project type and create new template
    local project_type=$(detect_project_type "$project_path")
    local template_file="$TEMPLATE_DIR/CLAUDE-${project_type}.md"
    
    if [ ! -f "$template_file" ]; then
        template_file="$TEMPLATE_DIR/CLAUDE-default.md"
    fi
    
    # Get project variables
    local project_info=$(get_project_info "$project_path")
    
    # Create updated file
    local temp_file=$(mktemp)
    cp "$template_file" "$temp_file"
    
    # Substitute variables
    while IFS='=' read -r key value; do
        if [ -n "$key" ] && [ -n "$value" ]; then
            sed -i.bak "s|{${key}}|${value}|g" "$temp_file"
        fi
    done <<< "$project_info"
    
    # If we have existing context, replace the template's context section
    if [ -n "$context_section" ]; then
        # Remove the template's context section and add the preserved one
        sed -i.bak '/## Recent Context & Instructions/,$d' "$temp_file"
        echo "$context_section" >> "$temp_file"
    fi
    
    # Copy to final location
    cp "$temp_file" "$output_file"
    rm "$temp_file"
    
    echo "✅ Updated CLAUDE.md with $project_type template"
    echo "📁 Backup saved: $output_file.backup"
}

# Function to add context to existing CLAUDE.md
add_context_to_claude_md() {
    local context="$1"
    local project_path="${2:-$(pwd)}"
    local output_file="$project_path/CLAUDE.md"
    
    if [ -z "$context" ]; then
        echo "Usage: add_context_to_claude_md 'Your context'"
        return 1
    fi
    
    if [ ! -f "$output_file" ]; then
        echo "❌ No CLAUDE.md found in $project_path"
        echo "💡 Use 'claude-init' to create one"
        return 1
    fi
    
    # Add context to the Recent Context section
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Check if Recent Context section exists
    if ! grep -q "## Recent Context & Instructions" "$output_file"; then
        echo "" >> "$output_file"
        echo "## Recent Context & Instructions" >> "$output_file"
        echo "[This section will be automatically updated with recent instructions and context]" >> "$output_file"
        echo "" >> "$output_file"
    fi
    
    # Add the new context
    echo "" >> "$output_file"
    echo "### Context Added: $timestamp" >> "$output_file"
    echo "$context" >> "$output_file"
    echo "" >> "$output_file"
    
    echo "✅ Added context to CLAUDE.md"
}

# Function to list available templates
list_templates() {
    echo "📋 Available CLAUDE.md templates:"
    for template in "$TEMPLATE_DIR"/CLAUDE-*.md; do
        if [ -f "$template" ]; then
            local name=$(basename "$template" .md | sed 's/CLAUDE-//')
            echo "  - $name"
        fi
    done
}

# Function to show template preview
show_template() {
    local template_type="$1"
    local template_file="$TEMPLATE_DIR/CLAUDE-${template_type}.md"
    
    if [ ! -f "$template_file" ]; then
        echo "❌ Template not found: $template_type"
        list_templates
        return 1
    fi
    
    echo "📋 Template preview: $template_type"
    echo "================================================"
    head -50 "$template_file"
    echo "================================================"
}

# Main function
main() {
    case "$1" in
        "detect")
            detect_project_type "$2"
            ;;
        "create")
            local project_type="${2:-$(detect_project_type)}"
            create_claude_md "$project_type" "$3"
            ;;
        "update")
            update_claude_md "$2"
            ;;
        "add-context")
            add_context_to_claude_md "$2" "$3"
            ;;
        "list")
            list_templates
            ;;
        "show")
            show_template "$2"
            ;;
        "info")
            get_project_info "$2"
            ;;
        *)
            echo "Claude Template Manager"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  detect [path]              Detect project type"
            echo "  create [type] [path]       Create CLAUDE.md from template"
            echo "  update [path]              Update existing CLAUDE.md"
            echo "  add-context 'text' [path]  Add context to CLAUDE.md"
            echo "  list                       List available templates"
            echo "  show <type>                Show template preview"
            echo "  info [path]                Show project information"
            echo ""
            echo "Examples:"
            echo "  $0 detect                  # Detect current project type"
            echo "  $0 create react            # Create React CLAUDE.md"
            echo "  $0 update                  # Update current CLAUDE.md"
            echo "  $0 add-context 'Use hooks' # Add context to CLAUDE.md"
            ;;
    esac
}

# Export functions for use in other scripts
export -f detect_project_type
export -f create_claude_md
export -f add_context_to_claude_md

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi