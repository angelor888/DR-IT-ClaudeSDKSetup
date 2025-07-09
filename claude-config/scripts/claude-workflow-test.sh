#!/bin/bash
# Claude Code Workflow Testing Suite
# Comprehensive testing of all advanced features

set -euo pipefail

# Configuration
CLAUDE_CONFIG_DIR="$HOME/.config/claude"
TEST_LOG_DIR="$CLAUDE_CONFIG_DIR/test-logs"
TEST_RESULTS_FILE="$TEST_LOG_DIR/test-results-$(date +%Y%m%d-%H%M%S).json"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Initialize test environment
init_test_env() {
    mkdir -p "$TEST_LOG_DIR"
    mkdir -p "$TEST_LOG_DIR/temp"
    
    echo -e "${BLUE}🧪 Claude Code Workflow Testing Suite${NC}"
    echo "======================================"
    echo "Test session: $(date)"
    echo "Results will be saved to: $TEST_RESULTS_FILE"
    echo ""
    
    # Initialize results file
    cat > "$TEST_RESULTS_FILE" << EOF
{
  "testSession": {
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "version": "1.0.0",
    "environment": {
      "os": "$(uname -s)",
      "shell": "$SHELL",
      "user": "$USER"
    }
  },
  "tests": [],
  "summary": {
    "total": 0,
    "passed": 0,
    "failed": 0,
    "skipped": 0
  }
}
EOF
}

# Log test result
log_test_result() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    local duration="${4:-0}"
    
    if [ -f "$TEST_RESULTS_FILE" ] && command -v jq &> /dev/null; then
        local temp_results="/tmp/test_results.json"
        
        jq ".tests += [{
            \"name\": \"$test_name\",
            \"status\": \"$status\",
            \"message\": \"$message\",
            \"duration\": $duration,
            \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
        }]" "$TEST_RESULTS_FILE" > "$temp_results"
        
        mv "$temp_results" "$TEST_RESULTS_FILE"
    fi
}

# Run a test
run_test() {
    local test_name="$1"
    local test_function="$2"
    local skip_reason="${3:-}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -n "Testing: $test_name ... "
    
    # Skip test if reason provided
    if [ -n "$skip_reason" ]; then
        echo -e "${YELLOW}SKIPPED${NC} ($skip_reason)"
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
        log_test_result "$test_name" "skipped" "$skip_reason" 0
        return 0
    fi
    
    # Run test with timing
    local start_time
    start_time=$(date +%s)
    
    local test_output
    local test_status
    
    if test_output=$($test_function 2>&1); then
        test_status="passed"
        echo -e "${GREEN}PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        test_status="failed"
        echo -e "${RED}FAILED${NC}"
        echo "  Error: $test_output"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_test_result "$test_name" "$test_status" "$test_output" "$duration"
}

# Test Git worktree functionality
test_git_worktree() {
    # Check if worktree script exists and is executable
    if [ ! -x ~/.config/claude/scripts/claude-worktree.sh ]; then
        return 1
    fi
    
    # Test help command
    if ! ~/.config/claude/scripts/claude-worktree.sh help > /dev/null 2>&1; then
        return 1
    fi
    
    # Test in a temporary git repository
    local temp_repo="$TEST_LOG_DIR/temp/test-repo"
    mkdir -p "$temp_repo"
    cd "$temp_repo"
    
    # Initialize git repo
    git init > /dev/null 2>&1
    echo "test" > README.md
    git add README.md
    git commit -m "Initial commit" > /dev/null 2>&1
    
    # Test worktree creation (should fail gracefully in test environment)
    ~/.config/claude/scripts/claude-worktree.sh list > /dev/null 2>&1
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_repo"
    
    return 0
}

# Test IDE integration
test_ide_integration() {
    # Check if IDE integration script exists
    if [ ! -x ~/.config/claude/scripts/claude-ide-integration.sh ]; then
        return 1
    fi
    
    # Test status command
    if ! ~/.config/claude/scripts/claude-ide-integration.sh status > /dev/null 2>&1; then
        return 1
    fi
    
    # Test detect command
    if ! ~/.config/claude/scripts/claude-ide-integration.sh detect > /dev/null 2>&1; then
        return 1
    fi
    
    return 0
}

# Test design iteration system
test_design_iteration() {
    # Check if design iteration script exists
    if [ ! -x ~/.config/claude/scripts/claude-design-iterate.sh ]; then
        return 1
    fi
    
    # Test in temporary directory
    local temp_dir="$TEST_LOG_DIR/temp/design-test"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Test with simple brief (should create directory structure)
    timeout 30 ~/.config/claude/scripts/claude-design-iterate.sh "Test Design Brief" > /dev/null 2>&1 || true
    
    # Check if UI-iterations directory was created
    if [ -d "UI-iterations" ]; then
        # Cleanup
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 0
    fi
    
    cd - > /dev/null
    rm -rf "$temp_dir"
    return 1
}

# Test audio notification system
test_audio_notifications() {
    # Check if audio script exists
    if [ ! -x ~/.config/claude/scripts/claude-audio-notifications.sh ]; then
        return 1
    fi
    
    # Test status command
    if ! ~/.config/claude/scripts/claude-audio-notifications.sh status > /dev/null 2>&1; then
        return 1
    fi
    
    # Test list command
    if ! ~/.config/claude/scripts/claude-audio-notifications.sh list > /dev/null 2>&1; then
        return 1
    fi
    
    # Test play command (should not produce errors)
    if ! ~/.config/claude/scripts/claude-audio-notifications.sh play complete "Test notification" > /dev/null 2>&1; then
        return 1
    fi
    
    return 0
}

# Test clipboard utility
test_clipboard_utility() {
    # Check if clipboard script exists
    if [ ! -x ~/.config/claude/scripts/claude-clipboard-to-file.sh ]; then
        return 1
    fi
    
    # Test status command
    if ! ~/.config/claude/scripts/claude-clipboard-to-file.sh status > /dev/null 2>&1; then
        return 1
    fi
    
    # Test detect command
    if ! ~/.config/claude/scripts/claude-clipboard-to-file.sh detect > /dev/null 2>&1; then
        return 1
    fi
    
    return 0
}

# Test mode manager
test_mode_manager() {
    # Check if mode manager script exists
    if [ ! -x ~/.config/claude/scripts/claude-mode-manager.sh ]; then
        return 1
    fi
    
    # Test status command
    if ! ~/.config/claude/scripts/claude-mode-manager.sh status > /dev/null 2>&1; then
        return 1
    fi
    
    # Test list command
    if ! ~/.config/claude/scripts/claude-mode-manager.sh list > /dev/null 2>&1; then
        return 1
    fi
    
    return 0
}

# Test safe mode
test_safe_mode() {
    # Check if safe mode script exists
    if [ ! -x ~/.config/claude/scripts/claude-safe-mode.sh ]; then
        return 1
    fi
    
    # Test status command
    if ! ~/.config/claude/scripts/claude-safe-mode.sh status > /dev/null 2>&1; then
        return 1
    fi
    
    # Test check command with safe command
    if ! ~/.config/claude/scripts/claude-safe-mode.sh check "ls -la" > /dev/null 2>&1; then
        return 1
    fi
    
    return 0
}

# Test shell integration
test_shell_integration() {
    # Check if shell integration file exists
    if [ ! -f ~/.config/claude/shell-integration.sh ]; then
        return 1
    fi
    
    # Test sourcing the file
    if ! bash -c "source ~/.config/claude/shell-integration.sh" > /dev/null 2>&1; then
        return 1
    fi
    
    return 0
}

# Test configuration files
test_configuration_files() {
    # Check if main configuration exists
    if [ ! -f ~/.config/claude/settings.json ]; then
        return 1
    fi
    
    # Check if environment file exists
    if [ ! -f ~/.config/claude/environment ]; then
        return 1
    fi
    
    # Validate JSON files
    if command -v jq &> /dev/null; then
        if ! jq . ~/.config/claude/settings.json > /dev/null 2>&1; then
            return 1
        fi
    fi
    
    return 0
}

# Test hooks system
test_hooks_system() {
    # Check if hooks directory exists
    if [ ! -d ~/.config/claude/hooks ]; then
        return 1
    fi
    
    # Check if main hooks exist
    local hooks=("stop-hook.sh" "pre-run-hook.sh" "post-run-hook.sh")
    
    for hook in "${hooks[@]}"; do
        if [ ! -f ~/.config/claude/hooks/$hook ]; then
            return 1
        fi
    done
    
    return 0
}

# Performance test
test_performance() {
    local start_time
    start_time=$(date +%s.%N)
    
    # Run multiple commands to test performance
    ~/.config/claude/scripts/claude-mode-manager.sh status > /dev/null 2>&1
    ~/.config/claude/scripts/claude-safe-mode.sh status > /dev/null 2>&1
    ~/.config/claude/scripts/claude-audio-notifications.sh status > /dev/null 2>&1
    
    local end_time
    end_time=$(date +%s.%N)
    
    local duration
    duration=$(echo "$end_time - $start_time" | bc -l)
    
    # Performance should be under 2 seconds
    if [ "$(echo "$duration < 2.0" | bc -l)" -eq 1 ]; then
        return 0
    else
        return 1
    fi
}

# Integration test
test_integration() {
    # Test that all components work together
    local temp_dir="$TEST_LOG_DIR/temp/integration-test"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Test workflow: mode switch -> audio notification -> clipboard save
    ~/.config/claude/scripts/claude-mode-manager.sh status > /dev/null 2>&1 || return 1
    ~/.config/claude/scripts/claude-audio-notifications.sh play complete "Integration test" > /dev/null 2>&1 || return 1
    ~/.config/claude/scripts/claude-clipboard-to-file.sh status > /dev/null 2>&1 || return 1
    
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    return 0
}

# Update final test results
update_test_summary() {
    if [ -f "$TEST_RESULTS_FILE" ] && command -v jq &> /dev/null; then
        local temp_results="/tmp/test_results.json"
        
        jq ".summary = {
            \"total\": $TOTAL_TESTS,
            \"passed\": $PASSED_TESTS,
            \"failed\": $FAILED_TESTS,
            \"skipped\": $SKIPPED_TESTS
        }" "$TEST_RESULTS_FILE" > "$temp_results"
        
        mv "$temp_results" "$TEST_RESULTS_FILE"
    fi
}

# Main test runner
main() {
    local test_type="${1:-all}"
    
    case "$test_type" in
        "all")
            init_test_env
            
            # Run all tests
            run_test "Configuration Files" test_configuration_files
            run_test "Shell Integration" test_shell_integration
            run_test "Hooks System" test_hooks_system
            run_test "Git Worktree" test_git_worktree
            run_test "IDE Integration" test_ide_integration
            run_test "Design Iteration" test_design_iteration
            run_test "Audio Notifications" test_audio_notifications
            run_test "Clipboard Utility" test_clipboard_utility
            run_test "Mode Manager" test_mode_manager
            run_test "Safe Mode" test_safe_mode
            run_test "Performance" test_performance
            run_test "Integration" test_integration
            
            # Show summary
            echo ""
            echo -e "${BLUE}📊 Test Summary${NC}"
            echo "==============="
            echo "Total tests: $TOTAL_TESTS"
            echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
            echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
            echo -e "Skipped: ${YELLOW}$SKIPPED_TESTS${NC}"
            
            local success_rate
            if [ $TOTAL_TESTS -gt 0 ]; then
                success_rate=$(echo "scale=1; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc -l)
                echo "Success rate: ${success_rate}%"
            fi
            
            # Update results file
            update_test_summary
            
            echo ""
            echo -e "${BLUE}📄 Detailed results: $TEST_RESULTS_FILE${NC}"
            
            # Audio notification
            if [ $FAILED_TESTS -eq 0 ]; then
                ~/.config/claude/scripts/claude-audio-notifications.sh context "complete" "All tests passed" true 2>/dev/null || true
            else
                ~/.config/claude/scripts/claude-audio-notifications.sh context "error" "$FAILED_TESTS tests failed" false 2>/dev/null || true
            fi
            
            # Return appropriate exit code
            if [ $FAILED_TESTS -eq 0 ]; then
                return 0
            else
                return 1
            fi
            ;;
        "quick")
            init_test_env
            
            # Run quick tests only
            run_test "Configuration Files" test_configuration_files
            run_test "Shell Integration" test_shell_integration
            run_test "Mode Manager" test_mode_manager
            run_test "Safe Mode" test_safe_mode
            
            echo ""
            echo -e "${BLUE}📊 Quick Test Summary${NC}"
            echo "===================="
            echo "Total tests: $TOTAL_TESTS"
            echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
            echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
            
            update_test_summary
            ;;
        "help"|"-h"|"--help")
            echo "Claude Code Workflow Testing Suite"
            echo ""
            echo "Usage: claude-workflow-test [test-type]"
            echo ""
            echo "Test Types:"
            echo "  all                     Run all tests (default)"
            echo "  quick                   Run quick tests only"
            echo "  help                    Show this help message"
            echo ""
            echo "Examples:"
            echo "  claude-workflow-test all"
            echo "  claude-workflow-test quick"
            ;;
        *)
            echo "Unknown test type: $test_type"
            echo "Run 'claude-workflow-test help' for usage information"
            return 1
            ;;
    esac
}

# Run main function
main "$@"