#!/bin/bash

# Programming Joke API Script
# Fetches programming jokes from various sources or uses offline fallbacks

set -euo pipefail

# Configuration
JOKE_CATEGORY=${1:-"random"}
SAFE_MODE=${2:-"true"}
OFFLINE_JOKES=(
    "Why do programmers prefer dark mode? Because light attracts bugs!"
    "A SQL query goes into a bar, walks up to two tables and asks: 'Can I join you?'"
    "Why don't programmers like nature? It has too many bugs."
    "How many programmers does it take to change a light bulb? None, that's a hardware problem."
    "Why did the programmer quit his job? He didn't get arrays!"
    "What's the object-oriented way to become wealthy? Inheritance."
    "Why do Java developers wear glasses? Because they can't C#!"
    "A programmer is told to 'go to hell'. He finds the worst part of that statement is the 'go to'."
    "Why did the developer go broke? Because he used up all his cache!"
    "What do you call a programmer from Finland? Nerdic!"
    "Why do programmers hate nature? It has too many bugs and not enough documentation."
    "How do you comfort a JavaScript bug? You console it!"
    "Why did the programmer break up with the internet? There was no connection."
    "What's a programmer's favorite hangout place? Foo Bar!"
    "Why don't programmers like to go outside? The sun causes too many reflections."
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_message() {
    echo -e "${BLUE}[joke-api] $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[joke-api] $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}[joke-api] $1${NC}" >&2
}

log_error() {
    echo -e "${RED}[joke-api] $1${NC}" >&2
}

# Get random offline joke
get_offline_joke() {
    local random_index=$((RANDOM % ${#OFFLINE_JOKES[@]}))
    echo "${OFFLINE_JOKES[$random_index]}"
}

# Get category-specific joke
get_category_joke() {
    local category=$1
    
    case "$category" in
        "programming")
            local programming_jokes=(
                "Why do programmers prefer dark mode? Because light attracts bugs!"
                "What's the object-oriented way to become wealthy? Inheritance."
                "Why did the programmer quit his job? He didn't get arrays!"
                "A programmer is told to 'go to hell'. He finds the worst part of that statement is the 'go to'."
                "Why don't programmers like to go outside? The sun causes too many reflections."
            )
            local random_index=$((RANDOM % ${#programming_jokes[@]}))
            echo "${programming_jokes[$random_index]}"
            ;;
        "debugging")
            local debugging_jokes=(
                "Why don't programmers like nature? It has too many bugs."
                "99 little bugs in the code, 99 little bugs. Take one down, patch it around, 117 little bugs in the code."
                "A QA engineer walks into a bar. Orders a beer. Orders 0 beers. Orders 999999999 beers. Orders a lizard. Orders -1 beers. Orders a ueicbksjdhd. First real customer walks in and asks where the bathroom is. The bar bursts into flames, killing everyone."
                "Why do programmers hate nature? It has too many bugs and not enough documentation."
                "How do you comfort a JavaScript bug? You console it!"
            )
            local random_index=$((RANDOM % ${#debugging_jokes[@]}))
            echo "${debugging_jokes[$random_index]}"
            ;;
        "git")
            local git_jokes=(
                "I have a joke about Git, but I'm still working on it in another branch."
                "Why did the git commit go to therapy? It had too many conflicts."
                "Git commit -m 'Fixed everything' // Famous last words"
                "I told a Git joke about branching, but it didn't merge well with the audience."
                "Why don't Git repositories ever get lonely? They always have their origin."
            )
            local random_index=$((RANDOM % ${#git_jokes[@]}))
            echo "${git_jokes[$random_index]}"
            ;;
        "ai")
            local ai_jokes=(
                "Why did the AI go to therapy? It had too many neural networks and not enough real connections."
                "What did the machine learning algorithm say to the data? 'You complete me... statistically.'"
                "Why don't AI models ever get tired? They always have enough epochs to sleep."
                "What's an AI's favorite type of music? Deep learning beats."
                "Why did the neural network break up with the decision tree? It said their relationship wasn't deep enough."
            )
            local random_index=$((RANDOM % ${#ai_jokes[@]}))
            echo "${ai_jokes[$random_index]}"
            ;;
        *)
            get_offline_joke
            ;;
    esac
}

# Try to fetch joke from online API
fetch_online_joke() {
    local category=$1
    local safe_flag=""
    
    if [[ "$SAFE_MODE" == "true" ]]; then
        safe_flag="&safe-mode"
    fi
    
    # Try JokeAPI first
    if command -v curl >/dev/null 2>&1; then
        local api_url="https://v2.jokeapi.dev/joke/Programming"
        
        if [[ "$category" != "random" ]]; then
            case "$category" in
                "programming"|"debugging")
                    api_url="https://v2.jokeapi.dev/joke/Programming"
                    ;;
                *)
                    api_url="https://v2.jokeapi.dev/joke/Programming"
                    ;;
            esac
        fi
        
        local response=$(curl -s -m 5 "${api_url}${safe_flag}" 2>/dev/null || echo "")
        
        if [[ -n "$response" ]]; then
            # Check if it's a single joke or setup/delivery
            if echo "$response" | jq -e '.type == "single"' >/dev/null 2>&1; then
                local joke=$(echo "$response" | jq -r '.joke' 2>/dev/null)
                if [[ -n "$joke" && "$joke" != "null" ]]; then
                    echo "$joke"
                    return 0
                fi
            elif echo "$response" | jq -e '.type == "twopart"' >/dev/null 2>&1; then
                local setup=$(echo "$response" | jq -r '.setup' 2>/dev/null)
                local delivery=$(echo "$response" | jq -r '.delivery' 2>/dev/null)
                if [[ -n "$setup" && -n "$delivery" && "$setup" != "null" && "$delivery" != "null" ]]; then
                    echo "$setup"
                    echo "$delivery"
                    return 0
                fi
            fi
        fi
    fi
    
    # Fallback to offline jokes
    return 1
}

# Display joke with formatting
display_joke() {
    local joke="$1"
    
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}  ${CYAN}😄 Programming Humor Break${NC}                                                    ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠══════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC}                                                                                  ${PURPLE}║${NC}"
    
    # Word wrap the joke
    local wrapped_joke=$(echo "$joke" | fold -w 76 -s)
    
    while IFS= read -r line; do
        printf "${PURPLE}║${NC}  %-76s ${PURPLE}║${NC}\n" "$line"
    done <<< "$wrapped_joke"
    
    echo -e "${PURPLE}║${NC}                                                                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}Hope that brightened your coding session! 🚀${NC}"
}

# Main execution
main() {
    log_message "Fetching programming joke (category: $JOKE_CATEGORY, safe: $SAFE_MODE)..."
    
    local joke=""
    
    # Try online API first
    if joke=$(fetch_online_joke "$JOKE_CATEGORY" 2>/dev/null); then
        log_success "Fetched joke from online API"
    else
        log_warning "Online API unavailable, using offline jokes"
        joke=$(get_category_joke "$JOKE_CATEGORY")
    fi
    
    # Display the joke
    display_joke "$joke"
    
    # Log to joke history
    local joke_log=".claude/logs/joke-history.log"
    mkdir -p "$(dirname "$joke_log")"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Category: $JOKE_CATEGORY | $joke" >> "$joke_log"
    
    log_success "Joke delivered successfully!"
}

# Execute main function
main "$@"