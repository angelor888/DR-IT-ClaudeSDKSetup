#!/bin/bash
#
# DR-IT-ClaudeSDKSetup SDK Installation
# Version: 1.0.0
# Date: 2025-07-08
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SDK_DIR="$HOME/.config/claude/sdk-examples"

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Setup Python SDK
setup_python_sdk() {
    log "Setting up Python SDK..."
    
    PYTHON_SDK_DIR="$SDK_DIR/python"
    mkdir -p "$PYTHON_SDK_DIR"
    
    # Create virtual environment
    log "Creating Python virtual environment..."
    cd "$PYTHON_SDK_DIR"
    python3 -m venv venv
    
    # Activate and install
    source venv/bin/activate
    pip install --upgrade pip
    pip install anthropic python-dotenv rich
    
    # Copy example scripts
    log "Copying Python examples..."
    cp -r "$PROJECT_ROOT/sdk-examples/python/"* "$PYTHON_SDK_DIR/"
    
    # Create test script
    cat > "$PYTHON_SDK_DIR/test-api.py" << 'EOF'
#!/usr/bin/env python3
"""Simple API test to verify Claude SDK is working"""
import os
from anthropic import Anthropic

def main():
    client = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))
    
    print("Testing Claude API connection...")
    try:
        message = client.messages.create(
            model="claude-3-haiku-20240307",
            max_tokens=100,
            messages=[{"role": "user", "content": "Say 'API test successful!' in exactly 4 words."}]
        )
        print(f"✓ {message.content[0].text}")
        print("✓ Claude SDK is working properly!")
    except Exception as e:
        print(f"✗ API test failed: {e}")

if __name__ == "__main__":
    main()
EOF
    
    chmod +x "$PYTHON_SDK_DIR/test-api.py"
    deactivate
    
    log "✓ Python SDK setup complete"
}

# Setup TypeScript SDK
setup_typescript_sdk() {
    log "Setting up TypeScript SDK..."
    
    TS_SDK_DIR="$SDK_DIR/typescript"
    mkdir -p "$TS_SDK_DIR"
    
    cd "$TS_SDK_DIR"
    
    # Initialize npm project
    log "Initializing TypeScript project..."
    npm init -y
    
    # Install dependencies
    npm install @anthropic-ai/sdk typescript @types/node tsx dotenv
    
    # Create tsconfig.json
    cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF
    
    # Create source directory
    mkdir -p src
    
    # Copy TypeScript examples
    if [ -d "$PROJECT_ROOT/sdk-examples/typescript" ]; then
        cp -r "$PROJECT_ROOT/sdk-examples/typescript/"* "$TS_SDK_DIR/"
    fi
    
    # Create test script
    cat > src/test-api.ts << 'EOF'
import Anthropic from '@anthropic-ai/sdk';
import * as dotenv from 'dotenv';

dotenv.config();

async function main() {
    const anthropic = new Anthropic({
        apiKey: process.env.ANTHROPIC_API_KEY,
    });
    
    console.log('Testing Claude API connection...');
    
    try {
        const message = await anthropic.messages.create({
            model: 'claude-3-haiku-20240307',
            max_tokens: 100,
            messages: [{ role: 'user', content: 'Say "API test successful!" in exactly 4 words.' }],
        });
        
        console.log(`✓ ${message.content[0].text}`);
        console.log('✓ Claude SDK is working properly!');
    } catch (error) {
        console.error('✗ API test failed:', error);
    }
}

main();
EOF
    
    # Update package.json scripts
    npm pkg set scripts.test="tsx src/test-api.ts"
    npm pkg set scripts.build="tsc"
    
    log "✓ TypeScript SDK setup complete"
}

# Main function
main() {
    log "Installing Claude SDK..."
    
    # Create SDK directory
    mkdir -p "$SDK_DIR"
    
    # Setup both SDKs
    setup_python_sdk
    setup_typescript_sdk
    
    # Create SDK switcher script
    cat > "$HOME/.config/claude/scripts/sdk-switch.sh" << 'EOF'
#!/bin/bash
# Quick SDK environment switcher

case "$1" in
    python|py)
        cd ~/.config/claude/sdk-examples/python
        source venv/bin/activate
        echo "✓ Python SDK environment activated"
        ;;
    typescript|ts)
        cd ~/.config/claude/sdk-examples/typescript
        echo "✓ TypeScript SDK environment ready"
        ;;
    *)
        echo "Usage: sdk-switch [python|typescript]"
        ;;
esac
EOF
    
    chmod +x "$HOME/.config/claude/scripts/sdk-switch.sh"
    
    log "✓ Claude SDK installation complete"
    log "Test with: claude-py && python test-api.py"
}

# Run main function
main "$@"