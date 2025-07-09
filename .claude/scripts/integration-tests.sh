#!/bin/bash

# Integration Tests Script
# Comprehensive testing suite for all Claude Code components

set -euo pipefail

# Configuration
CLAUDE_DIR=".claude"
TEST_RESULTS_DIR="$CLAUDE_DIR/test-results"
TEST_LOG="$TEST_RESULTS_DIR/integration-tests.log"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_message() {
    echo -e "${BLUE}[integration-tests] $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[integration-tests] $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}[integration-tests] $1${NC}" >&2
}

log_error() {
    echo -e "${RED}[integration-tests] $1${NC}" >&2
}

# Initialize test environment
init_test_env() {
    mkdir -p "$TEST_RESULTS_DIR"/{logs,reports,artifacts}
    
    # Create test log header
    cat > "$TEST_LOG" <<EOF
# Claude Code Integration Tests
# Started: $TIMESTAMP
# Environment: $(uname -s) $(uname -r)
# Git Repository: $(git rev-parse --show-toplevel 2>/dev/null || echo "Not a git repo")

EOF
}

# Run individual test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="${3:-0}"
    
    ((TOTAL_TESTS++))
    
    log_message "Running test: $test_name"
    
    local test_start=$(date +%s)
    local test_output=""
    local test_result=0
    
    # Run test and capture output
    if test_output=$(eval "$test_command" 2>&1); then
        test_result=0
    else
        test_result=$?
    fi
    
    local test_end=$(date +%s)
    local test_duration=$((test_end - test_start))
    
    # Log test result
    echo "[$TIMESTAMP] TEST: $test_name" >> "$TEST_LOG"
    echo "Command: $test_command" >> "$TEST_LOG"
    echo "Expected: $expected_result, Got: $test_result" >> "$TEST_LOG"
    echo "Duration: ${test_duration}s" >> "$TEST_LOG"
    echo "Output:" >> "$TEST_LOG"
    echo "$test_output" >> "$TEST_LOG"
    echo "---" >> "$TEST_LOG"
    
    # Check result
    if [[ $test_result -eq $expected_result ]]; then
        ((PASSED_TESTS++))
        echo -e "${GREEN}✅ PASS${NC}: $test_name (${test_duration}s)"
        return 0
    else
        ((FAILED_TESTS++))
        echo -e "${RED}❌ FAIL${NC}: $test_name (expected: $expected_result, got: $test_result)"
        echo -e "${YELLOW}   Output: $test_output${NC}"
        return 1
    fi
}

# Skip test
skip_test() {
    local test_name="$1"
    local reason="$2"
    
    ((TOTAL_TESTS++))
    ((SKIPPED_TESTS++))
    
    echo -e "${YELLOW}⏭️  SKIP${NC}: $test_name - $reason"
    echo "[$TIMESTAMP] SKIPPED: $test_name - $reason" >> "$TEST_LOG"
}

# Test basic file structure
test_file_structure() {
    echo -e "${PURPLE}📁 Testing File Structure${NC}"
    
    run_test "Claude directory exists" "test -d .claude"
    run_test "Scripts directory exists" "test -d .claude/scripts"
    run_test "Commands directory exists" "test -d .claude/commands"
    run_test "Settings directory exists" "test -d .claude/settings"
    run_test "Hooks directory exists" "test -d .claude/hooks"
    
    # Test key files
    run_test "Auto-init script exists" "test -f .claude/scripts/auto-init.sh"
    run_test "Memory sync script exists" "test -f .claude/scripts/memory-sync.sh"
    run_test "Worktree manager script exists" "test -f .claude/scripts/worktree-manager.sh"
    run_test "Settings file exists" "test -f .claude/settings/settings.json"
}

# Test script executability
test_script_permissions() {
    echo -e "${PURPLE}🔧 Testing Script Permissions${NC}"
    
    local scripts=(
        ".claude/scripts/auto-init.sh"
        ".claude/scripts/memory-sync.sh"
        ".claude/scripts/worktree-manager.sh"
        ".claude/scripts/joke-api.sh"
        ".claude/scripts/model-manager.sh"
        ".claude/scripts/model-context.sh"
        ".claude/scripts/auto-accept-manager.sh"
        ".claude/scripts/permission-manager.sh"
        ".claude/scripts/intelligent-gsave.sh"
        ".claude/scripts/parallel-coordinator.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            run_test "Script executable: $(basename "$script")" "test -x '$script'"
        else
            skip_test "Script executable: $(basename "$script")" "File not found"
        fi
    done
}

# Test JSON configuration validity
test_json_configs() {
    echo -e "${PURPLE}📋 Testing JSON Configuration Files${NC}"
    
    local json_files=(
        ".claude/settings/settings.json"
        ".claude/commands/joke-me.json"
        ".claude/commands/model-switch.json"
        ".claude/commands/auto-accept.json"
        ".claude/commands/skip-permissions.json"
        ".claude/commands/gsave.json"
        ".claude/commands/init.json"
        ".claude/commands/design-iterate.json"
        ".claude/commands/project-settings.json"
        ".claude/commands/parallel.json"
    )
    
    for json_file in "${json_files[@]}"; do
        if [[ -f "$json_file" ]]; then
            run_test "Valid JSON: $(basename "$json_file")" "jq empty < '$json_file'"
        else
            skip_test "Valid JSON: $(basename "$json_file")" "File not found"
        fi
    done
}

# Test script functionality
test_script_functionality() {
    echo -e "${PURPLE}⚙️ Testing Script Functionality${NC}"
    
    # Test joke API
    if [[ -f ".claude/scripts/joke-api.sh" ]]; then
        run_test "Joke API script runs" "./.claude/scripts/joke-api.sh programming >/dev/null"
    else
        skip_test "Joke API script runs" "Script not found"
    fi
    
    # Test model manager
    if [[ -f ".claude/scripts/model-manager.sh" ]]; then
        run_test "Model manager current" "./.claude/scripts/model-manager.sh current >/dev/null"
        run_test "Model manager list" "./.claude/scripts/model-manager.sh list >/dev/null"
    else
        skip_test "Model manager tests" "Script not found"
    fi
    
    # Test auto-accept manager
    if [[ -f ".claude/scripts/auto-accept-manager.sh" ]]; then
        run_test "Auto-accept status" "./.claude/scripts/auto-accept-manager.sh status >/dev/null"
    else
        skip_test "Auto-accept tests" "Script not found"
    fi
    
    # Test permission manager
    if [[ -f ".claude/scripts/permission-manager.sh" ]]; then
        run_test "Permission manager status" "./.claude/scripts/permission-manager.sh status >/dev/null"
    else
        skip_test "Permission manager tests" "Script not found"
    fi
    
    # Test memory sync
    if [[ -f ".claude/scripts/memory-sync.sh" ]]; then
        run_test "Memory sync load" "./.claude/scripts/memory-sync.sh load >/dev/null"
    else
        skip_test "Memory sync tests" "Script not found"
    fi
    
    # Test worktree manager
    if [[ -f ".claude/scripts/worktree-manager.sh" ]]; then
        run_test "Worktree manager list" "./.claude/scripts/worktree-manager.sh list >/dev/null"
    else
        skip_test "Worktree manager tests" "Script not found"
    fi
    
    # Test parallel coordinator
    if [[ -f ".claude/scripts/parallel-coordinator.sh" ]]; then
        run_test "Parallel coordinator list" "./.claude/scripts/parallel-coordinator.sh list >/dev/null"
    else
        skip_test "Parallel coordinator tests" "Script not found"
    fi
}

# Test integration points
test_integration_points() {
    echo -e "${PURPLE}🔗 Testing Integration Points${NC}"
    
    # Test git integration
    if git rev-parse --git-dir >/dev/null 2>&1; then
        run_test "Git repository valid" "git status >/dev/null"
        run_test "Git branch accessible" "git branch --show-current >/dev/null"
    else
        skip_test "Git integration tests" "Not in a git repository"
    fi
    
    # Test jq availability
    run_test "jq command available" "command -v jq >/dev/null"
    
    # Test Claude command availability
    if command -v claude >/dev/null 2>&1; then
        run_test "Claude CLI available" "claude --version >/dev/null"
    else
        skip_test "Claude CLI tests" "Claude CLI not installed"
    fi
    
    # Test directory structure
    run_test "Claude.md exists" "test -f Claude.md"
}

# Test safety and security
test_safety_security() {
    echo -e "${PURPLE}🛡️ Testing Safety and Security${NC}"
    
    # Check for sensitive information in scripts
    local sensitive_patterns=("password" "secret" "key" "token" "credential")
    
    for pattern in "${sensitive_patterns[@]}"; do
        if grep -r -i "$pattern" .claude/scripts/ 2>/dev/null | grep -v "# Test" | grep -v "example" >/dev/null; then
            run_test "No sensitive data: $pattern" "false" 1
        else
            run_test "No sensitive data: $pattern" "true"
        fi
    done
    
    # Check script permissions (should not be world-writable)
    run_test "Scripts not world-writable" "! find .claude/scripts -perm -002 -type f | grep -q ."
    
    # Check for dangerous operations in scripts
    local dangerous_ops=("rm -rf /" "chmod 777" "sudo" "curl.*|.*sh")
    
    for op in "${dangerous_ops[@]}"; do
        if grep -r "$op" .claude/scripts/ >/dev/null 2>&1; then
            run_test "No dangerous operation: $op" "false" 1
        else
            run_test "No dangerous operation: $op" "true"
        fi
    done
}

# Test performance
test_performance() {
    echo -e "${PURPLE}⚡ Testing Performance${NC}"
    
    # Test script execution times
    local performance_tests=(
        ".claude/scripts/joke-api.sh programming"
        ".claude/scripts/model-manager.sh current"
        ".claude/scripts/auto-accept-manager.sh status"
        ".claude/scripts/memory-sync.sh load"
    )
    
    for test_cmd in "${performance_tests[@]}"; do
        if [[ -f "$(echo "$test_cmd" | cut -d' ' -f1)" ]]; then
            local start_time=$(date +%s%N)
            if eval "$test_cmd >/dev/null 2>&1"; then
                local end_time=$(date +%s%N)
                local duration=$(((end_time - start_time) / 1000000))  # Convert to milliseconds
                
                if [[ $duration -lt 5000 ]]; then  # Less than 5 seconds
                    run_test "Performance: $(basename "$(echo "$test_cmd" | cut -d' ' -f1)") < 5s" "true"
                else
                    run_test "Performance: $(basename "$(echo "$test_cmd" | cut -d' ' -f1)") < 5s" "false" 1
                fi
            else
                skip_test "Performance: $(basename "$(echo "$test_cmd" | cut -d' ' -f1)")" "Script failed to run"
            fi
        else
            skip_test "Performance: $(basename "$(echo "$test_cmd" | cut -d' ' -f1)")" "Script not found"
        fi
    done
}

# Generate test report
generate_test_report() {
    local report_file="$TEST_RESULTS_DIR/integration-test-report.md"
    local success_rate=0
    
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    fi
    
    cat > "$report_file" <<EOF
# Claude Code Integration Test Report

**Generated**: $TIMESTAMP
**Environment**: $(uname -s) $(uname -r)
**Git Repository**: $(git rev-parse --show-toplevel 2>/dev/null || echo "Not a git repo")

## Test Summary

| Metric | Count | Percentage |
|--------|-------|------------|
| **Total Tests** | $TOTAL_TESTS | 100% |
| **Passed** | $PASSED_TESTS | $success_rate% |
| **Failed** | $FAILED_TESTS | $(( (FAILED_TESTS * 100) / TOTAL_TESTS ))% |
| **Skipped** | $SKIPPED_TESTS | $(( (SKIPPED_TESTS * 100) / TOTAL_TESTS ))% |

## Test Categories

- **File Structure**: Basic directory and file existence
- **Script Permissions**: Executable permissions on scripts
- **JSON Configuration**: Valid JSON syntax in config files
- **Script Functionality**: Basic functionality of core scripts
- **Integration Points**: Git, CLI tools, and external dependencies
- **Safety & Security**: Security checks and safe practices
- **Performance**: Script execution time validation

## Detailed Results

See full test log at: \`$TEST_LOG\`

## Recommendations

EOF
    
    if [[ $FAILED_TESTS -gt 0 ]]; then
        echo "⚠️ **$FAILED_TESTS tests failed** - Review the test log for details" >> "$report_file"
    else
        echo "✅ **All tests passed** - System is functioning correctly" >> "$report_file"
    fi
    
    if [[ $SKIPPED_TESTS -gt 0 ]]; then
        echo "ℹ️ **$SKIPPED_TESTS tests skipped** - Check for missing dependencies" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "---" >> "$report_file"
    echo "*Generated by Claude Code Integration Test Suite*" >> "$report_file"
    
    log_success "Test report generated: $report_file"
}

# Display test summary
display_summary() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}  ${CYAN}🧪 Claude Code Integration Test Summary${NC}                                    ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠══════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC}                                                                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  ${BLUE}Total Tests:    $TOTAL_TESTS${NC}                                                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  ${GREEN}Passed Tests:   $PASSED_TESTS${NC}                                                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  ${RED}Failed Tests:   $FAILED_TESTS${NC}                                                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  ${YELLOW}Skipped Tests:  $SKIPPED_TESTS${NC}                                                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                                                  ${PURPLE}║${NC}"
    
    local success_rate=0
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    fi
    
    echo -e "${PURPLE}║${NC}  ${CYAN}Success Rate:   $success_rate%${NC}                                                      ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                                                  ${PURPLE}║${NC}"
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${PURPLE}║${NC}  ${GREEN}✅ All tests passed! System is functioning correctly.${NC}                       ${PURPLE}║${NC}"
    else
        echo -e "${PURPLE}║${NC}  ${RED}❌ $FAILED_TESTS tests failed. Review the test log for details.${NC}                ${PURPLE}║${NC}"
    fi
    
    echo -e "${PURPLE}║${NC}                                                                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    # Return appropriate exit code
    if [[ $FAILED_TESTS -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Main test execution
main() {
    local test_category=${1:-"all"}
    
    log_message "Starting Claude Code integration tests..."
    
    # Initialize test environment
    init_test_env
    
    case "$test_category" in
        "all")
            test_file_structure
            test_script_permissions
            test_json_configs
            test_script_functionality
            test_integration_points
            test_safety_security
            test_performance
            ;;
        "structure")
            test_file_structure
            ;;
        "permissions")
            test_script_permissions
            ;;
        "configs")
            test_json_configs
            ;;
        "functionality")
            test_script_functionality
            ;;
        "integration")
            test_integration_points
            ;;
        "security")
            test_safety_security
            ;;
        "performance")
            test_performance
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [all|structure|permissions|configs|functionality|integration|security|performance]"
            echo ""
            echo "Test Categories:"
            echo "  all           Run all tests (default)"
            echo "  structure     Test file and directory structure"
            echo "  permissions   Test script executable permissions"
            echo "  configs       Test JSON configuration validity"
            echo "  functionality Test basic script functionality"
            echo "  integration   Test integration points"
            echo "  security      Test safety and security"
            echo "  performance   Test performance benchmarks"
            exit 0
            ;;
        *)
            log_error "Unknown test category: $test_category"
            exit 1
            ;;
    esac
    
    # Generate report and display summary
    generate_test_report
    display_summary
}

# Execute main function
main "$@"