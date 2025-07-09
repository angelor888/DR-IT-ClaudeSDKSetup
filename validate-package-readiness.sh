#!/bin/bash
# Package Readiness Validation Script
# Comprehensive check before creating installation package

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Test result tracking
check_result() {
    local description="$1"
    local command="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "Checking: $description ... "
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}FAIL${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

echo -e "${BLUE}🔍 Package Readiness Validation${NC}"
echo "================================="

# Script validation
echo -e "\n${YELLOW}📜 Script Validation${NC}"
check_result "All shell scripts have proper shebangs" "find . -name '*.sh' -exec head -1 {} \; | grep -q '#!/bin/bash'"
check_result "All scripts are executable" "find . -name '*.sh' -exec test -x {} \;"
check_result "All scripts pass syntax check" "find . -name '*.sh' -exec bash -n {} \;"

# JSON validation
echo -e "\n${YELLOW}📋 Configuration Validation${NC}"
check_result "All JSON files are valid" "find . -name '*.json' -not -path './node_modules/*' -not -path './claude-config/sdk-examples/typescript/node_modules/*' -exec jq empty {} \;"
check_result "Environment template exists" "test -f claude-config/environment.template"
check_result "Setup script exists" "test -f scripts/setup-all.sh"

# Security validation
echo -e "\n${YELLOW}🔒 Security Validation${NC}"
check_result "No real secrets in repository" "! grep -r 'xoxb-[0-9]' . --exclude-dir=node_modules --exclude-dir=.git"
check_result "No real API keys in repository" "! grep -r 'sk-[a-zA-Z0-9]\\{48\\}' . --exclude-dir=node_modules --exclude-dir=.git"
check_result "Gitignore protects secrets" "grep -q 'environment$' claude-config/.gitignore"

# Structure validation
echo -e "\n${YELLOW}📁 Structure Validation${NC}"
check_result "Claude config directory exists" "test -d claude-config"
check_result "Scripts directory exists" "test -d claude-config/scripts"
check_result "Commands directory exists" "test -d claude-config/commands"
check_result "Hooks directory exists" "test -d claude-config/hooks"
check_result "Audio directory exists" "test -d claude-config/audio"
check_result "Templates directory exists" "test -d claude-config/templates"

# Documentation validation
echo -e "\n${YELLOW}📚 Documentation Validation${NC}"
check_result "README exists" "test -f README.md"
check_result "Setup guide exists" "test -f claude-config/SETUP.md"
check_result "Implementation report exists" "test -f claude-config/IMPLEMENTATION_REPORT.md"
check_result "Installation audit exists" "test -f INSTALLATION_PACKAGE_AUDIT.md"

# Dependency validation
echo -e "\n${YELLOW}🔧 Dependency Validation${NC}"
check_result "Package.json exists" "test -f package.json"
check_result "Install script exists" "test -f install.sh"
check_result "Main setup script exists" "test -f scripts/setup-all.sh"

# Testing validation
echo -e "\n${YELLOW}🧪 Testing Validation${NC}"
check_result "Test suite exists" "test -f claude-config/scripts/claude-workflow-test.sh"
check_result "Test suite is executable" "test -x claude-config/scripts/claude-workflow-test.sh"

# Show summary
echo -e "\n${BLUE}📊 Validation Summary${NC}"
echo "====================="
echo "Total checks: $TOTAL_CHECKS"
echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "\n${GREEN}✅ Repository is ready for package creation!${NC}"
    echo -e "Success rate: ${GREEN}$(echo "scale=1; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc)%${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Repository needs attention before packaging${NC}"
    echo -e "Success rate: ${YELLOW}$(echo "scale=1; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc)%${NC}"
    exit 1
fi