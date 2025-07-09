#!/bin/bash
#
# Sub-Agent Stop Hook - Handles parallel sub-agent completion
# Triggered when a sub-agent completes its task
#

set -euo pipefail

# Configuration
LOG_DIR="$HOME/.config/claude/logs"
SUBAGENT_LOG_DIR="$LOG_DIR/sub-agents"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
SUBAGENT_LOG="$SUBAGENT_LOG_DIR/subagent-$(date +%Y%m%d).log"

# Ensure directories exist
mkdir -p "$SUBAGENT_LOG_DIR"

# Get sub-agent information
AGENT_ID="${CLAUDE_AGENT_ID:-${1:-unknown}}"
AGENT_TASK="${CLAUDE_AGENT_TASK:-${2:-No task description}}"
AGENT_STATUS="${CLAUDE_AGENT_STATUS:-${3:-completed}}"
AGENT_RESULT="${CLAUDE_AGENT_RESULT:-}"
AGENT_DURATION="${CLAUDE_AGENT_DURATION:-}"
PARENT_AGENT="${CLAUDE_PARENT_AGENT:-main}"

# Function to sanitize output
sanitize_output() {
    local content="$1"
    # Remove sensitive data
    content=$(echo "$content" | sed -E 's/(sk-[a-zA-Z0-9-]+|ghp_[a-zA-Z0-9]+|xoxb-[a-zA-Z0-9-]+)/[REDACTED]/g')
    content=$(echo "$content" | sed -E 's/([A-Z_]+_KEY|TOKEN|SECRET|PASSWORD)=["'\''"]?[^"'\'' ]+["'\''"]?/\1=[REDACTED]/g')
    echo "$content"
}

# Log sub-agent completion
{
    echo "[$TIMESTAMP] SUB-AGENT COMPLETION"
    echo "  Agent ID: $AGENT_ID"
    echo "  Parent Agent: $PARENT_AGENT"
    echo "  Task: $AGENT_TASK"
    echo "  Status: $AGENT_STATUS"
    if [ -n "$AGENT_DURATION" ]; then
        echo "  Duration: $AGENT_DURATION"
    fi
    if [ -n "$AGENT_RESULT" ]; then
        echo "  Result Summary: $(echo "$AGENT_RESULT" | head -5)"
    fi
    echo "  ----------------------------------------"
} >> "$SUBAGENT_LOG"

# Save detailed result to individual file
if [ -n "$AGENT_RESULT" ]; then
    RESULT_FILE="$SUBAGENT_LOG_DIR/agent-${AGENT_ID}-$(date +%Y%m%d-%H%M%S).log"
    {
        echo "Sub-Agent Task: $AGENT_TASK"
        echo "Status: $AGENT_STATUS"
        echo "Duration: $AGENT_DURATION"
        echo "Parent: $PARENT_AGENT"
        echo ""
        echo "=== RESULT ==="
        sanitize_output "$AGENT_RESULT"
    } > "$RESULT_FILE"
fi

# Update parent agent status file (for coordination)
PARENT_STATUS_FILE="$SUBAGENT_LOG_DIR/parent-${PARENT_AGENT}-status.json"
if [ -f "$PARENT_STATUS_FILE" ]; then
    # Update existing status
    CURRENT_COMPLETED=$(jq -r '.completed_agents // 0' "$PARENT_STATUS_FILE" 2>/dev/null || echo "0")
    CURRENT_TOTAL=$(jq -r '.total_agents // 0' "$PARENT_STATUS_FILE" 2>/dev/null || echo "0")
    NEW_COMPLETED=$((CURRENT_COMPLETED + 1))
    
    jq --arg id "$AGENT_ID" \
       --arg task "$AGENT_TASK" \
       --arg status "$AGENT_STATUS" \
       --arg completed "$NEW_COMPLETED" \
       '.completed_agents = ($completed | tonumber) | 
        .agents[$id] = {"task": $task, "status": $status, "completed_at": now}' \
       "$PARENT_STATUS_FILE" > "$PARENT_STATUS_FILE.tmp" && \
       mv "$PARENT_STATUS_FILE.tmp" "$PARENT_STATUS_FILE"
else
    # Create new status file
    cat > "$PARENT_STATUS_FILE" <<EOF
{
    "parent_agent": "$PARENT_AGENT",
    "started_at": "$TIMESTAMP",
    "total_agents": 1,
    "completed_agents": 1,
    "agents": {
        "$AGENT_ID": {
            "task": "$AGENT_TASK",
            "status": "$AGENT_STATUS",
            "completed_at": "$TIMESTAMP"
        }
    }
}
EOF
fi

# Enhanced notification and coordination for sub-agents
if [ -f "$PARENT_STATUS_FILE" ]; then
    COMPLETED=$(jq -r '.completed_agents // 0' "$PARENT_STATUS_FILE")
    TOTAL=$(jq -r '.total_agents // 0' "$PARENT_STATUS_FILE")
    
    # Send individual agent completion notification
    echo "agent_complete" | CLAUDE_NOTIFICATION_TYPE="agent_complete" \
        CLAUDE_NOTIFICATION_MESSAGE="Agent $AGENT_ID completed: $AGENT_TASK" \
        CLAUDE_NOTIFICATION_CONTEXT="$COMPLETED of $TOTAL agents finished" \
        ~/.config/claude/hooks/notification-hook.sh &
    
    if [ "$COMPLETED" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
        # All sub-agents complete - enhanced reporting
        
        # Send comprehensive notification
        echo "all_agents_complete" | CLAUDE_NOTIFICATION_TYPE="all_agents_complete" \
            CLAUDE_NOTIFICATION_MESSAGE="All $TOTAL parallel agents completed successfully" \
            CLAUDE_NOTIFICATION_CONTEXT="Parallel execution finished" \
            ~/.config/claude/hooks/notification-hook.sh &
        
        # System notification
        if command -v osascript &>/dev/null; then
            osascript -e "display notification \"All $TOTAL sub-agents completed\" with title \"Claude Code - Parallel Tasks Complete\" sound name \"Hero\""
        fi
        
        # Generate comprehensive summary report
        SUMMARY_FILE="$SUBAGENT_LOG_DIR/summary-${PARENT_AGENT}-$(date +%Y%m%d-%H%M%S).md"
        SUMMARY_JSON="$SUBAGENT_LOG_DIR/summary-${PARENT_AGENT}-$(date +%Y%m%d-%H%M%S).json"
        
        # Calculate execution statistics
        TOTAL_DURATION=$(jq -r '[.agents[] | (.completed_at | strptime("%Y-%m-%d %H:%M:%S") | mktime)] | max - min' "$PARENT_STATUS_FILE" 2>/dev/null || echo "0")
        SUCCESS_COUNT=$(jq -r '[.agents[] | select(.status == "completed")] | length' "$PARENT_STATUS_FILE" 2>/dev/null || echo "0")
        
        # Markdown report
        {
            echo "# Sub-Agent Execution Summary"
            echo ""
            echo "**Parent Agent**: $PARENT_AGENT"
            echo "**Total Agents**: $TOTAL"
            echo "**Completed**: $COMPLETED"
            echo "**Success Rate**: $(echo "scale=1; $SUCCESS_COUNT * 100 / $TOTAL" | bc 2>/dev/null || echo "100")%"
            echo "**Total Duration**: ${TOTAL_DURATION}s"
            echo "**Generated**: $(date '+%Y-%m-%d %H:%M:%S')"
            echo ""
            echo "## Agent Results"
            echo ""
            jq -r '.agents | to_entries[] | "### Agent: \(.key)\n- **Task**: \(.value.task)\n- **Status**: \(.value.status)\n- **Completed**: \(.value.completed_at)\n"' "$PARENT_STATUS_FILE"
            echo ""
            echo "## Execution Timeline"
            echo ""
            jq -r '.agents | to_entries[] | "- \(.value.completed_at): \(.key) - \(.value.task)"' "$PARENT_STATUS_FILE" | sort
        } > "$SUMMARY_FILE"
        
        # JSON report for programmatic access
        jq --arg total_duration "$TOTAL_DURATION" \
           --arg success_rate "$(echo "scale=2; $SUCCESS_COUNT * 100 / $TOTAL" | bc 2>/dev/null || echo "100")" \
           '. + {
               "summary": {
                   "total_duration_seconds": ($total_duration | tonumber),
                   "success_rate_percent": ($success_rate | tonumber),
                   "generated_at": now
               }
           }' "$PARENT_STATUS_FILE" > "$SUMMARY_JSON"
        
        # Generate TypeScript interfaces for the summary data
        if [ -x ~/.config/claude/hooks/generate-log-interfaces.ts ]; then
            (
                sleep 2
                ~/.config/claude/hooks/generate-log-interfaces.ts "$SUMMARY_JSON" 2>/dev/null || true
            ) &
        fi
        
        # Log completion to main hooks log
        echo "[$TIMESTAMP] All $TOTAL sub-agents completed for parent: $PARENT_AGENT (success rate: $(echo "scale=1; $SUCCESS_COUNT * 100 / $TOTAL" | bc 2>/dev/null || echo "100")%)" >> "$LOG_DIR/hooks.log"
        
        # Clean up old status files (keep last 10)
        find "$SUBAGENT_LOG_DIR" -name "parent-*-status.json" -type f | head -n -10 | xargs rm -f 2>/dev/null || true
    fi
fi

# Log to hooks log
echo "[$TIMESTAMP] Sub-agent stop hook executed for agent: $AGENT_ID (status: $AGENT_STATUS)" >> "$LOG_DIR/hooks.log"