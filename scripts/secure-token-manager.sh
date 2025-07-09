#!/bin/bash
set -euo pipefail

# Secure Token Management for Claude
# Helps manage API tokens securely across multiple computers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$HOME/.config/claude/environment"
SECURE_TOKENS_DIR="$HOME/.config/claude/.secure-tokens"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
echo_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
echo_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  export    - Export tokens to encrypted file"
    echo "  import    - Import tokens from encrypted file"
    echo "  backup    - Create encrypted backup of current tokens"
    echo "  check     - Check which tokens are configured"
    echo "  edit      - Securely edit environment file"
    echo "  1password - Setup 1Password CLI integration"
    echo
    exit 1
}

# Ensure secure directory exists
mkdir -p "$SECURE_TOKENS_DIR"
chmod 700 "$SECURE_TOKENS_DIR"

check_tokens() {
    echo "================================================"
    echo "    Token Configuration Status"
    echo "================================================"
    echo
    
    if [ ! -f "$ENV_FILE" ]; then
        echo_error "Environment file not found!"
        return 1
    fi
    
    # List of expected tokens
    declare -a TOKENS=(
        "GITHUB_TOKEN"
        "SLACK_BOT_TOKEN"
        "GOOGLE_CLIENT_ID"
        "GOOGLE_CLIENT_SECRET"
        "NOTION_TOKEN"
        "OPENAI_API_KEY"
        "SENDGRID_API_KEY"
        "QUICKBOOKS_CONSUMER_KEY"
        "AIRTABLE_API_KEY"
        "CLOUDFLARE_API_TOKEN"
    )
    
    for token in "${TOKENS[@]}"; do
        if grep -q "^export $token=." "$ENV_FILE" || grep -q "^$token=." "$ENV_FILE"; then
            # Token has a value
            TOKEN_VALUE=$(grep -E "^(export )?$token=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"')
            if [ -n "$TOKEN_VALUE" ]; then
                # Show masked token (first 4 and last 4 chars)
                if [ ${#TOKEN_VALUE} -gt 12 ]; then
                    MASKED="${TOKEN_VALUE:0:4}...${TOKEN_VALUE: -4}"
                else
                    MASKED="***configured***"
                fi
                echo_success "$token: $MASKED"
            else
                echo_warning "$token: [empty]"
            fi
        else
            echo_error "$token: [not found]"
        fi
    done
}

export_tokens() {
    echo_info "Exporting tokens to encrypted file..."
    
    if [ ! -f "$ENV_FILE" ]; then
        echo_error "Environment file not found!"
        return 1
    fi
    
    EXPORT_FILE="$SECURE_TOKENS_DIR/tokens-$(date +%Y%m%d-%H%M%S).enc"
    
    # Use OpenSSL to encrypt
    echo_info "Enter a password to encrypt your tokens:"
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "$ENV_FILE" -out "$EXPORT_FILE"
    
    if [ $? -eq 0 ]; then
        chmod 600 "$EXPORT_FILE"
        echo_success "Tokens exported to: $EXPORT_FILE"
        echo_info "Transfer this file securely to your other computer"
        echo_warning "Remember your password! It cannot be recovered."
    else
        echo_error "Failed to export tokens"
        return 1
    fi
}

import_tokens() {
    echo_info "Import tokens from encrypted file..."
    
    # List available encrypted files
    echo "Available token files:"
    ls -la "$SECURE_TOKENS_DIR"/*.enc 2>/dev/null || {
        echo_error "No encrypted token files found in $SECURE_TOKENS_DIR"
        return 1
    }
    
    echo
    read -p "Enter filename to import (or full path): " IMPORT_FILE
    
    if [ ! -f "$IMPORT_FILE" ] && [ -f "$SECURE_TOKENS_DIR/$IMPORT_FILE" ]; then
        IMPORT_FILE="$SECURE_TOKENS_DIR/$IMPORT_FILE"
    fi
    
    if [ ! -f "$IMPORT_FILE" ]; then
        echo_error "File not found: $IMPORT_FILE"
        return 1
    fi
    
    # Backup current environment
    if [ -f "$ENV_FILE" ]; then
        cp "$ENV_FILE" "$ENV_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        echo_info "Current environment backed up"
    fi
    
    # Decrypt and import
    echo_info "Enter the password to decrypt tokens:"
    openssl enc -aes-256-cbc -d -pbkdf2 -in "$IMPORT_FILE" -out "$ENV_FILE"
    
    if [ $? -eq 0 ]; then
        chmod 600 "$ENV_FILE"
        echo_success "Tokens imported successfully!"
        check_tokens
    else
        echo_error "Failed to import tokens. Password may be incorrect."
        # Restore backup if exists
        if [ -f "$ENV_FILE.backup."* ]; then
            LATEST_BACKUP=$(ls -t "$ENV_FILE.backup."* | head -1)
            cp "$LATEST_BACKUP" "$ENV_FILE"
            echo_info "Restored previous environment"
        fi
        return 1
    fi
}

backup_tokens() {
    echo_info "Creating encrypted backup..."
    
    if [ ! -f "$ENV_FILE" ]; then
        echo_error "Environment file not found!"
        return 1
    fi
    
    BACKUP_FILE="$SECURE_TOKENS_DIR/backup-$(date +%Y%m%d-%H%M%S).enc"
    
    # Create encrypted backup
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "$ENV_FILE" -out "$BACKUP_FILE"
    
    if [ $? -eq 0 ]; then
        chmod 600 "$BACKUP_FILE"
        echo_success "Backup created: $BACKUP_FILE"
        
        # Keep only last 5 backups
        BACKUP_COUNT=$(ls "$SECURE_TOKENS_DIR"/backup-*.enc 2>/dev/null | wc -l)
        if [ $BACKUP_COUNT -gt 5 ]; then
            echo_info "Cleaning old backups (keeping last 5)..."
            ls -t "$SECURE_TOKENS_DIR"/backup-*.enc | tail -n +6 | xargs rm
        fi
    else
        echo_error "Failed to create backup"
        return 1
    fi
}

secure_edit() {
    echo_info "Opening environment file for secure editing..."
    
    # Create file if doesn't exist
    if [ ! -f "$ENV_FILE" ]; then
        touch "$ENV_FILE"
        chmod 600 "$ENV_FILE"
    fi
    
    # Check permissions
    if [ "$(stat -f %p "$ENV_FILE" | tail -c 4)" != "600" ]; then
        echo_warning "Fixing file permissions..."
        chmod 600 "$ENV_FILE"
    fi
    
    # Use preferred editor
    EDITOR="${EDITOR:-nano}"
    $EDITOR "$ENV_FILE"
    
    echo_success "Environment file saved"
    check_tokens
}

setup_1password() {
    echo_info "Setting up 1Password CLI integration..."
    
    # Check if op is installed
    if ! command -v op &> /dev/null; then
        echo_warning "1Password CLI not found. Installing..."
        brew install --cask 1password/tap/1password-cli
    fi
    
    echo_info "Creating 1Password integration script..."
    
    cat > "$HOME/.config/claude/scripts/1password-tokens.sh" << 'EOF'
#!/bin/bash
# Load tokens from 1Password into Claude environment

# Check if signed in to 1Password
if ! op account list &>/dev/null; then
    echo "Please sign in to 1Password CLI first:"
    eval $(op signin)
fi

# Load tokens from 1Password
# Adjust these references to match your 1Password items
export GITHUB_TOKEN=$(op read "op://Private/GitHub PAT/token")
export NOTION_TOKEN=$(op read "op://Private/Notion Integration/token")
export OPENAI_API_KEY=$(op read "op://Private/OpenAI/api_key")
# Add more tokens as needed

echo "Tokens loaded from 1Password"
EOF
    
    chmod +x "$HOME/.config/claude/scripts/1password-tokens.sh"
    
    echo_success "1Password integration created!"
    echo
    echo "To use:"
    echo "1. Store your tokens in 1Password"
    echo "2. Update the script with correct item references"
    echo "3. Source before using Claude: source ~/.config/claude/scripts/1password-tokens.sh"
}

# Main logic
case "${1:-help}" in
    check)
        check_tokens
        ;;
    export)
        export_tokens
        ;;
    import)
        import_tokens
        ;;
    backup)
        backup_tokens
        ;;
    edit)
        secure_edit
        ;;
    1password)
        setup_1password
        ;;
    *)
        usage
        ;;
esac