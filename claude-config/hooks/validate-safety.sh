#!/bin/bash
#
# Safety Validation Script - Test the safety hook functionality
#

set -euo pipefail

echo "🛡️ Claude Code Safety Validation"
echo "================================"

# Test 1: Check if safety hook exists and is executable
SAFETY_HOOK="$HOME/.config/claude/hooks/safety/pre-tool-use-safety.sh"
if [ -x "$SAFETY_HOOK" ]; then
    echo "✅ Safety hook exists and is executable"
else
    echo "❌ Safety hook missing or not executable"
    exit 1
fi

# Test 2: Check settings.json configuration
SETTINGS_FILE="$HOME/.config/claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    if grep -q "preToolUse" "$SETTINGS_FILE"; then
        echo "✅ preToolUse hook configured in settings"
    else
        echo "❌ preToolUse hook not found in settings"
    fi
else
    echo "❌ Settings file not found"
fi

# Test 3: Create safe test environment
TEST_DIR="/tmp/claude-safety-validation-$$"
mkdir -p "$TEST_DIR"
echo "test content" > "$TEST_DIR/test.txt"
echo "✅ Created test directory: $TEST_DIR"

# Test 4: Test hook directly with dangerous command simulation
echo ""
echo "Testing safety hook directly..."
echo '{"tool": "Bash", "arguments": {"command": "rm -rf /tmp/test"}}' | "$SAFETY_HOOK"
HOOK_EXIT_CODE=$?

if [ $HOOK_EXIT_CODE -eq 0 ]; then
    echo "❌ Safety hook should have blocked dangerous command"
else
    echo "✅ Safety hook properly blocked dangerous command"
fi

# Test 5: Test with sensitive file
echo ""
echo "Testing sensitive file protection..."
echo '{"tool": "Edit", "arguments": {"file_path": "/etc/passwd"}}' | "$SAFETY_HOOK"
HOOK_EXIT_CODE=$?

if [ $HOOK_EXIT_CODE -eq 0 ]; then
    echo "❌ Safety hook should have blocked sensitive file access"
else
    echo "✅ Safety hook properly blocked sensitive file access"
fi

# Test 6: Test with safe command
echo ""
echo "Testing safe command..."
echo '{"tool": "Bash", "arguments": {"command": "echo hello"}}' | "$SAFETY_HOOK"
HOOK_EXIT_CODE=$?

if [ $HOOK_EXIT_CODE -eq 0 ]; then
    echo "✅ Safety hook properly allowed safe command"
else
    echo "❌ Safety hook incorrectly blocked safe command"
fi

# Cleanup
rm -rf "$TEST_DIR"
echo ""
echo "🎯 Validation complete!"

# Test 7: Check log directory structure
LOG_DIR="$HOME/.config/claude/logs"
mkdir -p "$LOG_DIR"

if [ -f "$LOG_DIR/safety-blocks.log" ]; then
    echo "📊 Recent safety blocks:"
    tail -5 "$LOG_DIR/safety-blocks.log" 2>/dev/null || echo "  (no recent blocks)"
else
    echo "📊 No safety blocks logged yet"
fi

echo ""
echo "💡 To activate the hooks, restart Claude Code or start a new session"
echo "💡 Use 'claude -p \"test command\"' to test in programmable mode"