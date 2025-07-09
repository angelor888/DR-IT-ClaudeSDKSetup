#!/bin/bash
# Setup script for Claude SDK examples

echo "Claude SDK Environment Setup"
echo "============================"

# Check if API key is already set
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "✓ ANTHROPIC_API_KEY is already set"
else
    echo "⚠️  ANTHROPIC_API_KEY not found in environment"
    echo ""
    echo "To get your API key:"
    echo "1. Go to https://console.anthropic.com/settings/keys"
    echo "2. Create a new API key"
    echo "3. Add to your shell profile:"
    echo "   export ANTHROPIC_API_KEY='your-key-here'"
    echo ""
    echo "Or create a .env file in the example directories"
fi

# Python setup
echo ""
echo "Python SDK Setup:"
if [ -d "$HOME/.config/claude/sdk-examples/python/venv" ]; then
    echo "✓ Python virtual environment exists"
    echo "  Activate with: source ~/.config/claude/sdk-examples/python/venv/bin/activate"
else
    echo "⚠️  Python venv not found"
fi

# Node.js setup
echo ""
echo "TypeScript SDK Setup:"
if [ -f "$HOME/.config/claude/sdk-examples/typescript/package.json" ]; then
    echo "✓ Node.js project initialized"
    echo "  Run examples with: cd ~/.config/claude/sdk-examples/typescript && npx tsx <script>.ts"
else
    echo "⚠️  TypeScript project not found"
fi

echo ""
echo "Quick Start Commands:"
echo "===================="
echo "Python examples:"
echo "  cd ~/.config/claude/sdk-examples/python"
echo "  source venv/bin/activate"
echo "  python basic_example.py"
echo ""
echo "TypeScript examples:"
echo "  cd ~/.config/claude/sdk-examples/typescript"
echo "  npx tsx basic-example.ts"