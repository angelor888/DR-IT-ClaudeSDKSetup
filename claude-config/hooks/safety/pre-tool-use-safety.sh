#!/bin/bash
#
# Pre-Tool-Use Safety Hook - Blocks dangerous commands and protects sensitive files
# Triggered before executing any tool to prevent destructive actions
#

set -euo pipefail

# Configuration
LOG_DIR="$HOME/.config/claude/logs"
SAFETY_LOG="$LOG_DIR/safety-blocks.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Read input from stdin (Claude Code hook protocol)
if [ ! -t 0 ]; then
    INPUT=$(cat)
else
    INPUT="${*}"
fi

# Parse tool information from input JSON or environment
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool // empty' 2>/dev/null || echo "${CLAUDE_TOOL_NAME:-unknown}")
TOOL_ARGS=$(echo "$INPUT" | jq -r '.arguments // empty' 2>/dev/null || echo "${CLAUDE_TOOL_ARGS:-}")

# Dangerous command patterns (regex-based)
DANGEROUS_PATTERNS=(
    "rm\s+-rf\s+/"                    # Root filesystem deletion
    "rm\s+-rf\s+\*"                   # Wildcard deletion  
    "rm\s+-rf\s+~"                    # Home directory deletion
    "rm\s+-rf\s+/tmp"                 # Temp directory deletion
    "rm\s+-rf\s+[^[:space:]]*"        # Any rm -rf command
    "sudo\s+rm\s+-rf"                 # Elevated deletion
    "dd\s+.*of=/dev/"                 # Disk overwrite
    "mkfs\."                          # Format filesystem
    "fdisk.*--delete"                 # Delete partitions
    "chmod\s+-R\s+000"                # Remove all permissions
    "chown\s+-R\s+.*:\s*/"            # Change ownership of root
    "killall\s+-9"                    # Kill all processes
    ":(){ :|:& };:"                   # Fork bomb
    "curl.*\|.*bash"                  # Pipe to bash (dangerous)
    "wget.*\|.*sh"                    # Download and execute
    "eval\s+\$\("                     # Command injection
    "echo.*>\s*/etc/"                 # Write to system files
    "cat.*>\s*/dev/sd"                # Write to disk devices
)

# Sensitive file patterns
SENSITIVE_PATTERNS=(
    "\.env"
    "\.aws/credentials"
    "\.ssh/id_rsa"
    "\.ssh/id_ed25519"
    "id_rsa"
    "id_ed25519"
    "private.*key"
    "\.p12"
    "\.pem"
    "\.pfx"
    "keychain"
    "password"
    "secret"
    "token"
    "/etc/passwd"
    "/etc/shadow"
    "/etc/sudoers"
)

# Function to check for dangerous patterns
check_dangerous_command() {
    local command="$1"
    local pattern
    
    for pattern in "${DANGEROUS_PATTERNS[@]}"; do
        if echo "$command" | grep -qiE "$pattern"; then
            return 0  # Found dangerous pattern
        fi
    done
    return 1  # Safe
}

# Function to check for sensitive file access
check_sensitive_files() {
    local command="$1"
    local pattern
    
    for pattern in "${SENSITIVE_PATTERNS[@]}"; do
        if echo "$command" | grep -qiE "$pattern"; then
            return 0  # Found sensitive file pattern
        fi
    done
    return 1  # Safe
}

# Function to log and block
block_command() {
    local reason="$1"
    local command="$2"
    
    # Log the block
    {
        echo "[$TIMESTAMP] SAFETY BLOCK"
        echo "  Tool: $TOOL_NAME"
        echo "  Reason: $reason"
        echo "  Command: $command"
        echo "  User: $USER"
        echo "  Working Directory: $(pwd)"
        echo "  ----------------------------------------"
    } >> "$SAFETY_LOG"
    
    # Return JSON response to block the command
    cat <<EOF
{
    "allow": false,
    "reason": "$reason",
    "message": "🛡️ SAFETY BLOCK: $reason\n\nThe command was blocked for your protection:\n'$command'\n\nIf this is intentional, please run the command manually.",
    "alternatives": [
        "Review the command for safety",
        "Run with explicit confirmation",
        "Use a safer alternative approach"
    ]
}
EOF
    exit 0
}

# Main safety checks
case "$TOOL_NAME" in
    "Bash")
        # Extract command from bash tool arguments - handle both JSON and string formats
        BASH_COMMAND=""
        if echo "$INPUT" | jq -e '.arguments.command' >/dev/null 2>&1; then
            BASH_COMMAND=$(echo "$INPUT" | jq -r '.arguments.command' 2>/dev/null)
        elif echo "$TOOL_ARGS" | jq -e '.command' >/dev/null 2>&1; then
            BASH_COMMAND=$(echo "$TOOL_ARGS" | jq -r '.command' 2>/dev/null)
        else
            BASH_COMMAND="$TOOL_ARGS"
        fi
        
        # Check for dangerous commands
        if check_dangerous_command "$BASH_COMMAND"; then
            block_command "Dangerous command detected" "$BASH_COMMAND"
        fi
        
        # Check for sensitive file access
        if check_sensitive_files "$BASH_COMMAND"; then
            block_command "Sensitive file access detected" "$BASH_COMMAND"
        fi
        ;;
        
    "Edit"|"Write"|"MultiEdit")
        # Extract file path from edit/write operations
        FILE_PATH=$(echo "$TOOL_ARGS" | jq -r '.file_path // .path // empty' 2>/dev/null || echo "")
        
        if [ -n "$FILE_PATH" ] && check_sensitive_files "$FILE_PATH"; then
            block_command "Attempting to modify sensitive file" "$FILE_PATH"
        fi
        ;;
        
    "Read")
        # Check file read operations for sensitive files
        FILE_PATH=$(echo "$TOOL_ARGS" | jq -r '.file_path // .path // empty' 2>/dev/null || echo "")
        
        if [ -n "$FILE_PATH" ] && check_sensitive_files "$FILE_PATH"; then
            # Log but allow read operations (less dangerous)
            {
                echo "[$TIMESTAMP] SENSITIVE READ WARNING"
                echo "  File: $FILE_PATH"
                echo "  Tool: $TOOL_NAME"
                echo "  User: $USER"
            } >> "$SAFETY_LOG"
        fi
        ;;
esac

# If we reach here, the command is allowed
{
    echo "[$TIMESTAMP] SAFETY CHECK PASSED"
    echo "  Tool: $TOOL_NAME"
    echo "  Command: $(echo "$TOOL_ARGS" | head -c 100)..."
} >> "$SAFETY_LOG"

# Return JSON to allow the command
cat <<EOF
{
    "allow": true,
    "message": "Safety check passed"
}
EOF