#!/bin/bash

# Parallel Coordinator Script
# Manages multi-agent task distribution across Git worktrees

set -euo pipefail

# Configuration
CLAUDE_DIR=".claude"
PROJECT_NAME="DR-SETUP-DEV-ClaudeSDKEnvironment-v1.0-20250708"
WORKTREE_DIR="../${PROJECT_NAME}-worktrees"
COORDINATOR_CONFIG="$CLAUDE_DIR/settings/parallel-coordinator.json"
AGENT_LOG="$CLAUDE_DIR/logs/parallel-agents.log"
COMMUNICATION_DIR="$CLAUDE_DIR/communication"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_message() {
    echo -e "${BLUE}[parallel-coordinator] $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[parallel-coordinator] $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}[parallel-coordinator] $1${NC}" >&2
}

log_error() {
    echo -e "${RED}[parallel-coordinator] $1${NC}" >&2
}

# Initialize coordinator configuration
init_coordinator_config() {
    if [[ ! -f "$COORDINATOR_CONFIG" ]]; then
        mkdir -p "$(dirname "$COORDINATOR_CONFIG")"
        cat > "$COORDINATOR_CONFIG" <<EOF
{
  "max_parallel_agents": 3,
  "default_timeout": 3600,
  "communication_enabled": true,
  "progress_tracking": true,
  "auto_merge": false,
  "conflict_resolution": "interactive",
  "agent_templates": {
    "coding": {
      "branch_prefix": "feature/",
      "timeout": 7200,
      "priority": "high"
    },
    "testing": {
      "branch_prefix": "test/",
      "timeout": 1800,
      "priority": "medium"
    },
    "documentation": {
      "branch_prefix": "docs/",
      "timeout": 1800,
      "priority": "low"
    }
  },
  "last_updated": "$TIMESTAMP"
}
EOF
    fi
}

# Initialize communication system
init_communication() {
    mkdir -p "$COMMUNICATION_DIR"/{messages,status,results}
    
    # Create communication lock file
    touch "$COMMUNICATION_DIR/coordinator.lock"
}

# Create new agent session
create_agent_session() {
    local task_name="$1"
    local task_type="${2:-coding}"
    local task_description="$3"
    local priority="${4:-medium}"
    
    log_message "Creating agent session: $task_name"
    
    # Generate unique agent ID
    local agent_id="${task_name}-$(date +%s)"
    local worktree_name="$task_name"
    local branch_prefix=$(jq -r ".agent_templates.\"$task_type\".branch_prefix // \"feature/\"" "$COORDINATOR_CONFIG" 2>/dev/null)
    local branch_name="${branch_prefix}${task_name}"
    
    # Create worktree using existing worktree manager
    if ! ./.claude/scripts/worktree-manager.sh create "$worktree_name"; then
        log_error "Failed to create worktree for agent: $agent_id"
        return 1
    fi
    
    # Create agent configuration
    local agent_config="$COMMUNICATION_DIR/agents/$agent_id.json"
    mkdir -p "$(dirname "$agent_config")"
    
    cat > "$agent_config" <<EOF
{
  "agent_id": "$agent_id",
  "task_name": "$task_name",
  "task_type": "$task_type",
  "task_description": "$task_description",
  "priority": "$priority",
  "worktree_path": "$WORKTREE_DIR/$worktree_name",
  "branch_name": "$branch_name",
  "status": "created",
  "created_at": "$TIMESTAMP",
  "started_at": null,
  "completed_at": null,
  "progress": 0,
  "messages": [],
  "results": {}
}
EOF
    
    # Create agent communication channel
    mkdir -p "$COMMUNICATION_DIR/channels/$agent_id"
    
    # Log agent creation
    log_agent_activity "$agent_id" "created" "Agent session created for task: $task_name"
    
    log_success "Agent session created: $agent_id"
    echo "$agent_id"
}

# Start agent in background
start_agent() {
    local agent_id="$1"
    local agent_config="$COMMUNICATION_DIR/agents/$agent_id.json"
    
    if [[ ! -f "$agent_config" ]]; then
        log_error "Agent configuration not found: $agent_id"
        return 1
    fi
    
    local worktree_path=$(jq -r '.worktree_path' "$agent_config")
    local task_description=$(jq -r '.task_description' "$agent_config")
    
    log_message "Starting agent: $agent_id"
    
    # Update agent status
    jq ".status = \"running\" | .started_at = \"$TIMESTAMP\"" "$agent_config" > "$agent_config.tmp" && mv "$agent_config.tmp" "$agent_config"
    
    # Create agent startup script
    local agent_script="$COMMUNICATION_DIR/scripts/agent-$agent_id.sh"
    mkdir -p "$(dirname "$agent_script")"
    
    cat > "$agent_script" <<EOF
#!/bin/bash
set -euo pipefail

cd "$worktree_path"

# Agent task execution
echo "Agent $agent_id starting task..."
echo "Task: $task_description"

# Update progress
echo '{"agent_id": "$agent_id", "progress": 10, "status": "initializing", "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"}' > "$COMMUNICATION_DIR/status/$agent_id.json"

# Simulate agent work (replace with actual Claude Code integration)
sleep 2

# Update progress
echo '{"agent_id": "$agent_id", "progress": 50, "status": "working", "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"}' > "$COMMUNICATION_DIR/status/$agent_id.json"

# More work simulation
sleep 3

# Complete task
echo '{"agent_id": "$agent_id", "progress": 100, "status": "completed", "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"}' > "$COMMUNICATION_DIR/status/$agent_id.json"

echo "Agent $agent_id task completed"
EOF
    
    chmod +x "$agent_script"
    
    # Start agent in background
    nohup "$agent_script" > "$COMMUNICATION_DIR/logs/agent-$agent_id.log" 2>&1 &
    local agent_pid=$!
    
    # Store PID
    echo "$agent_pid" > "$COMMUNICATION_DIR/pids/$agent_id.pid"
    mkdir -p "$(dirname "$COMMUNICATION_DIR/pids/$agent_id.pid")"
    
    log_agent_activity "$agent_id" "started" "Agent started with PID: $agent_pid"
    
    log_success "Agent started: $agent_id (PID: $agent_pid)"
}

# Monitor agent progress
monitor_agent() {
    local agent_id="$1"
    local status_file="$COMMUNICATION_DIR/status/$agent_id.json"
    
    if [[ -f "$status_file" ]]; then
        local status=$(jq -r '.status' "$status_file" 2>/dev/null || echo "unknown")
        local progress=$(jq -r '.progress' "$status_file" 2>/dev/null || echo "0")
        
        echo "Agent $agent_id: $status ($progress%)"
        return 0
    else
        echo "Agent $agent_id: No status available"
        return 1
    fi
}

# List all active agents
list_agents() {
    local agents_dir="$COMMUNICATION_DIR/agents"
    
    if [[ ! -d "$agents_dir" ]]; then
        log_warning "No agents directory found"
        return 0
    fi
    
    echo -e "${PURPLE}🤖 Active Parallel Agents${NC}"
    echo -e "${CYAN}──────────────────────────────────${NC}"
    
    local agent_count=0
    
    for agent_config in "$agents_dir"/*.json; do
        if [[ -f "$agent_config" ]]; then
            local agent_id=$(jq -r '.agent_id' "$agent_config")
            local task_name=$(jq -r '.task_name' "$agent_config")
            local status=$(jq -r '.status' "$agent_config")
            local priority=$(jq -r '.priority' "$agent_config")
            
            # Get current progress if available
            local progress_info=""
            local status_file="$COMMUNICATION_DIR/status/$agent_id.json"
            if [[ -f "$status_file" ]]; then
                local progress=$(jq -r '.progress' "$status_file" 2>/dev/null || echo "0")
                progress_info=" ($progress%)"
            fi
            
            # Color code by status
            local status_color=$CYAN
            case "$status" in
                "running") status_color=$GREEN ;;
                "completed") status_color=$BLUE ;;
                "failed") status_color=$RED ;;
                "created") status_color=$YELLOW ;;
            esac
            
            echo -e "${status_color}• $task_name${NC} - ${status}${progress_info} [${priority}]"
            echo -e "  ${CYAN}ID: $agent_id${NC}"
            
            ((agent_count++))
        fi
    done
    
    if [[ $agent_count -eq 0 ]]; then
        echo -e "${YELLOW}No active agents${NC}"
    else
        echo -e "${CYAN}──────────────────────────────────${NC}"
        echo -e "${GREEN}Total agents: $agent_count${NC}"
    fi
}

# Send message between agents
send_agent_message() {
    local from_agent="$1"
    local to_agent="$2"
    local message="$3"
    
    local message_file="$COMMUNICATION_DIR/messages/${to_agent}-$(date +%s).json"
    
    cat > "$message_file" <<EOF
{
  "from": "$from_agent",
  "to": "$to_agent",
  "message": "$message",
  "timestamp": "$TIMESTAMP",
  "read": false
}
EOF
    
    log_message "Message sent from $from_agent to $to_agent"
}

# Check for agent messages
check_agent_messages() {
    local agent_id="$1"
    local messages_dir="$COMMUNICATION_DIR/messages"
    
    if [[ ! -d "$messages_dir" ]]; then
        return 0
    fi
    
    local message_count=0
    
    for message_file in "$messages_dir"/${agent_id}-*.json; do
        if [[ -f "$message_file" ]] && [[ $(jq -r '.read' "$message_file" 2>/dev/null) == "false" ]]; then
            local from=$(jq -r '.from' "$message_file")
            local message=$(jq -r '.message' "$message_file")
            local timestamp=$(jq -r '.timestamp' "$message_file")
            
            echo -e "${CYAN}[$timestamp] From $from: $message${NC}"
            
            # Mark as read
            jq '.read = true' "$message_file" > "$message_file.tmp" && mv "$message_file.tmp" "$message_file"
            
            ((message_count++))
        fi
    done
    
    if [[ $message_count -gt 0 ]]; then
        log_success "Displayed $message_count new messages for $agent_id"
    fi
}

# Stop agent
stop_agent() {
    local agent_id="$1"
    local pid_file="$COMMUNICATION_DIR/pids/$agent_id.pid"
    
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_success "Agent stopped: $agent_id (PID: $pid)"
        else
            log_warning "Agent process not running: $agent_id"
        fi
        
        rm -f "$pid_file"
    else
        log_warning "No PID file found for agent: $agent_id"
    fi
    
    # Update agent status
    local agent_config="$COMMUNICATION_DIR/agents/$agent_id.json"
    if [[ -f "$agent_config" ]]; then
        jq ".status = \"stopped\" | .completed_at = \"$TIMESTAMP\"" "$agent_config" > "$agent_config.tmp" && mv "$agent_config.tmp" "$agent_config"
    fi
    
    log_agent_activity "$agent_id" "stopped" "Agent manually stopped"
}

# Log agent activity
log_agent_activity() {
    local agent_id="$1"
    local action="$2"
    local details="$3"
    
    mkdir -p "$(dirname "$AGENT_LOG")"
    
    local log_entry="{\"timestamp\": \"$TIMESTAMP\", \"agent_id\": \"$agent_id\", \"action\": \"$action\", \"details\": \"$details\"}"
    echo "$log_entry" >> "$AGENT_LOG"
}

# Clean up completed agents
cleanup_agents() {
    local cleanup_count=0
    
    log_message "Cleaning up completed agents..."
    
    for agent_config in "$COMMUNICATION_DIR/agents"/*.json; do
        if [[ -f "$agent_config" ]]; then
            local agent_id=$(jq -r '.agent_id' "$agent_config")
            local status=$(jq -r '.status' "$agent_config")
            
            if [[ "$status" == "completed" ]] || [[ "$status" == "stopped" ]]; then
                # Clean up agent files
                rm -f "$COMMUNICATION_DIR/pids/$agent_id.pid"
                rm -f "$COMMUNICATION_DIR/status/$agent_id.json"
                rm -rf "$COMMUNICATION_DIR/channels/$agent_id"
                rm -f "$COMMUNICATION_DIR/scripts/agent-$agent_id.sh"
                rm -f "$COMMUNICATION_DIR/logs/agent-$agent_id.log"
                
                # Archive agent config
                mkdir -p "$COMMUNICATION_DIR/archive"
                mv "$agent_config" "$COMMUNICATION_DIR/archive/"
                
                ((cleanup_count++))
                log_agent_activity "$agent_id" "cleaned_up" "Agent files cleaned up and archived"
            fi
        fi
    done
    
    log_success "Cleaned up $cleanup_count completed agents"
}

# Main command handling
main() {
    local action=${1:-"help"}
    
    case "$action" in
        "init")
            init_coordinator_config
            init_communication
            log_success "Parallel coordinator initialized"
            ;;
        "create")
            local task_name=${2:-""}
            local task_type=${3:-"coding"}
            local task_description=${4:-"Generic task"}
            local priority=${5:-"medium"}
            
            if [[ -z "$task_name" ]]; then
                log_error "Please provide a task name"
                return 1
            fi
            
            create_agent_session "$task_name" "$task_type" "$task_description" "$priority"
            ;;
        "start")
            local agent_id=${2:-""}
            
            if [[ -z "$agent_id" ]]; then
                log_error "Please provide an agent ID"
                return 1
            fi
            
            start_agent "$agent_id"
            ;;
        "monitor")
            local agent_id=${2:-""}
            
            if [[ -z "$agent_id" ]]; then
                log_error "Please provide an agent ID"
                return 1
            fi
            
            monitor_agent "$agent_id"
            ;;
        "list")
            list_agents
            ;;
        "message")
            local from_agent=${2:-"coordinator"}
            local to_agent=${3:-""}
            local message=${4:-""}
            
            if [[ -z "$to_agent" ]] || [[ -z "$message" ]]; then
                log_error "Usage: $0 message <from_agent> <to_agent> <message>"
                return 1
            fi
            
            send_agent_message "$from_agent" "$to_agent" "$message"
            ;;
        "check-messages")
            local agent_id=${2:-""}
            
            if [[ -z "$agent_id" ]]; then
                log_error "Please provide an agent ID"
                return 1
            fi
            
            check_agent_messages "$agent_id"
            ;;
        "stop")
            local agent_id=${2:-""}
            
            if [[ -z "$agent_id" ]]; then
                log_error "Please provide an agent ID"
                return 1
            fi
            
            stop_agent "$agent_id"
            ;;
        "cleanup")
            cleanup_agents
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [init|create|start|monitor|list|message|check-messages|stop|cleanup]"
            echo ""
            echo "Commands:"
            echo "  init                                    Initialize parallel coordinator"
            echo "  create <name> [type] [desc] [priority]  Create new agent session"
            echo "  start <agent_id>                        Start agent in background"
            echo "  monitor <agent_id>                      Monitor agent progress"
            echo "  list                                    List all active agents"
            echo "  message <from> <to> <message>           Send message between agents"
            echo "  check-messages <agent_id>               Check messages for agent"
            echo "  stop <agent_id>                         Stop running agent"
            echo "  cleanup                                 Clean up completed agents"
            ;;
        *)
            log_error "Unknown action: $action"
            echo "Use '$0 help' for usage information"
            return 1
            ;;
    esac
}

# Execute main function
main "$@"