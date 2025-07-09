#!/bin/bash
#
# MCP Service Monitor & Health Check
# Version: 1.0.0
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
MCP_DIR="$HOME/easy-mcp"
LOG_DIR="$HOME/.config/claude/logs"
HEALTH_LOG="$LOG_DIR/health-check-$(date +%Y%m%d).log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Function to check service health
check_service() {
    local service_name=$1
    local container_name=$2
    
    if docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        # Container is running, check if it's healthy
        local status=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null || echo "unknown")
        local uptime=$(docker inspect --format='{{.State.StartedAt}}' "$container_name" 2>/dev/null || echo "unknown")
        
        if [ "$status" = "running" ]; then
            echo -e "${GREEN}✓${NC} $service_name: Running (Started: $uptime)"
            echo "[$(date)] $service_name: Healthy" >> "$HEALTH_LOG"
        else
            echo -e "${YELLOW}⚠${NC} $service_name: Status - $status"
            echo "[$(date)] $service_name: Warning - Status $status" >> "$HEALTH_LOG"
        fi
    else
        echo -e "${RED}✗${NC} $service_name: Not running"
        echo "[$(date)] $service_name: Down" >> "$HEALTH_LOG"
        
        # Attempt to restart if requested
        if [ "${AUTO_RESTART:-false}" = "true" ]; then
            echo "  Attempting to restart $service_name..."
            cd "$MCP_DIR" && docker-compose up -d "$service_name" 2>&1 | tee -a "$HEALTH_LOG"
        fi
    fi
}

# Function to check disk usage
check_disk_usage() {
    local docker_dir=$(docker info 2>/dev/null | grep "Docker Root Dir" | awk '{print $NF}')
    if [ -n "$docker_dir" ]; then
        local usage=$(df -h "$docker_dir" | awk 'NR==2 {print $5}' | sed 's/%//')
        if [ "$usage" -gt 80 ]; then
            echo -e "${YELLOW}⚠${NC} Docker disk usage high: ${usage}%"
            echo "[$(date)] WARNING: Docker disk usage at ${usage}%" >> "$HEALTH_LOG"
        else
            echo -e "${GREEN}✓${NC} Docker disk usage: ${usage}%"
        fi
    fi
}

# Function to check for orphaned volumes
check_orphaned_volumes() {
    local orphaned=$(docker volume ls -q -f dangling=true | wc -l)
    if [ "$orphaned" -gt 0 ]; then
        echo -e "${YELLOW}⚠${NC} Found $orphaned orphaned Docker volumes"
        echo "[$(date)] WARNING: $orphaned orphaned volumes found" >> "$HEALTH_LOG"
        
        if [ "${CLEANUP_VOLUMES:-false}" = "true" ]; then
            echo "  Cleaning up orphaned volumes..."
            docker volume prune -f 2>&1 | tee -a "$HEALTH_LOG"
        fi
    else
        echo -e "${GREEN}✓${NC} No orphaned Docker volumes"
    fi
}

# Main monitoring function
echo "======================================"
echo "Claude & MCP Service Health Check"
echo "======================================"
echo ""

# Check Claude CLI
echo "Claude CLI Status:"
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null | awk '{print $1}' || echo "unknown")
    echo -e "${GREEN}✓${NC} Claude CLI: Installed (v$CLAUDE_VERSION)"
    
    # Check for updates
    LATEST_VERSION=$(npm view @anthropic-ai/claude-code version 2>/dev/null || echo "")
    if [ -n "$LATEST_VERSION" ] && [ "$CLAUDE_VERSION" != "$LATEST_VERSION" ]; then
        echo -e "${YELLOW}⚠${NC} Update available: v$LATEST_VERSION"
    fi
else
    echo -e "${RED}✗${NC} Claude CLI: Not found"
fi

echo ""
echo "MCP Docker Services:"
check_service "filesystem" "mcp-filesystem-enhanced"
check_service "memory" "mcp-memory-enhanced"
check_service "puppeteer" "mcp-puppeteer-enhanced"
check_service "everything" "mcp-everything-enhanced"
check_service "watchtower" "mcp-watchtower"
check_service "github" "mcp-github-enhanced"
check_service "postgres" "mcp-postgres-enhanced"
check_service "redis" "mcp-redis-enhanced"
check_service "slack" "mcp-slack-enhanced"

echo ""
echo "System Health:"
check_disk_usage
check_orphaned_volumes

# Check auto-update status
echo ""
echo "Auto-Update Status:"
if launchctl list | grep -q "com.claude.autoupdate"; then
    echo -e "${GREEN}✓${NC} Auto-update LaunchAgent: Active"
else
    echo -e "${RED}✗${NC} Auto-update LaunchAgent: Not loaded"
fi

# Show recent update logs
echo ""
echo "Recent Updates:"
if [ -f "$LOG_DIR/auto-update-$(date +%Y%m%d).log" ]; then
    tail -n 5 "$LOG_DIR/auto-update-$(date +%Y%m%d).log" | sed 's/^/  /'
else
    echo "  No updates today"
fi

echo ""
echo "======================================"
echo "Health check completed. Log saved to: $HEALTH_LOG"

# Exit with appropriate code
if grep -q "Down\|ERROR" "$HEALTH_LOG" 2>/dev/null; then
    exit 1
else
    exit 0
fi