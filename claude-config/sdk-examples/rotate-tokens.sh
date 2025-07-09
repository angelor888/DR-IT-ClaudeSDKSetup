#!/bin/bash
# Token Rotation Helper Script

set -euo pipefail

echo "Token Rotation Assistant"
echo "======================="

# Function to update token in file
update_token() {
    local file=$1
    local key=$2
    local old_value=$3
    local new_value=$4
    
    if [ -f "$file" ]; then
        # Create backup
        cp "$file" "$file.backup-$(date +%Y%m%d-%H%M%S)"
        
        # Update token
        if grep -q "^${key}=" "$file"; then
            # Use a different delimiter to avoid issues with special characters
            sed -i '' "s|^${key}=.*|${key}=${new_value}|" "$file"
            echo "✓ Updated $key in $file"
        else
            echo "⚠️  $key not found in $file"
        fi
    else
        echo "⚠️  File not found: $file"
    fi
}

# GitHub Token Rotation
echo ""
echo "1. GitHub Token Rotation"
echo "------------------------"
echo "Current token ends with: ...$(tail -c 5 ~/easy-mcp/.env | grep -o '[[:alnum:]]*' | tail -1)"
echo ""
echo "Steps to rotate:"
echo "1. Go to https://github.com/settings/tokens"
echo "2. Create new token with required scopes"
echo "3. Delete or regenerate the old token"
echo ""
read -p "Enter new GitHub token (or press Enter to skip): " new_github_token

if [ -n "$new_github_token" ]; then
    # Update in .env files
    update_token ~/easy-mcp/.env "GITHUB_TOKEN" "" "$new_github_token"
    
    # Update GitHub CLI
    echo "$new_github_token" | gh auth login --with-token
    echo "✓ GitHub CLI updated"
fi

# Anthropic API Key Rotation
echo ""
echo "2. Anthropic API Key Rotation"
echo "-----------------------------"
echo "Steps to rotate:"
echo "1. Go to https://console.anthropic.com/settings/keys"
echo "2. Create new API key"
echo "3. Delete the old key"
echo ""
read -p "Enter new Anthropic API key (or press Enter to skip): " new_anthropic_key

if [ -n "$new_anthropic_key" ]; then
    # Update in shell profile
    if grep -q "ANTHROPIC_API_KEY" ~/.zshrc; then
        sed -i '' "s|export ANTHROPIC_API_KEY=.*|export ANTHROPIC_API_KEY='$new_anthropic_key'|" ~/.zshrc
        echo "✓ Updated in ~/.zshrc"
    else
        echo "export ANTHROPIC_API_KEY='$new_anthropic_key'" >> ~/.zshrc
        echo "✓ Added to ~/.zshrc"
    fi
    
    # Update current session
    export ANTHROPIC_API_KEY="$new_anthropic_key"
fi

# Security check
echo ""
echo "3. Security Verification"
echo "-----------------------"

# Check file permissions
echo "Checking file permissions..."
for file in ~/easy-mcp/.env ~/.config/claude/.env ~/.zshrc; do
    if [ -f "$file" ]; then
        perms=$(ls -l "$file" | awk '{print $1}')
        if [[ "$perms" == *"rw-------"* ]] || [[ "$perms" == *"rw-r--r--"* ]]; then
            echo "✓ $file has appropriate permissions"
        else
            chmod 600 "$file"
            echo "✓ Fixed permissions for $file"
        fi
    fi
done

# Check git status
echo ""
echo "Checking git security..."
cd ~/easy-mcp
if git ls-files .env --error-unmatch 2>/dev/null; then
    echo "⚠️  WARNING: .env is tracked by git!"
    echo "Run: git rm --cached .env"
else
    echo "✓ .env is not tracked by git"
fi

echo ""
echo "Token rotation complete!"
echo ""
echo "Next steps:"
echo "1. Test your services to ensure new tokens work"
echo "2. Document the rotation date"
echo "3. Set calendar reminder for next rotation (90 days)"
echo ""
echo "Test commands:"
echo "  gh auth status                    # Test GitHub"
echo "  python -c 'import anthropic'      # Test Anthropic"