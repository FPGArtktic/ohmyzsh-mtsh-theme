
# mtsh.zsh-theme
# A custom Zsh theme that displays detailed information in the prompt,
# including date/time, IP address, Git status, current directory, RAM usage,
# and elapsed time for the last command.
# Mateusz Okulanis <FPGArtktic@outlook.com>
# License: GNU GPL v3

preexec_mtsh() {
    # Save the start time of the command (for elapsed time calculation)
    export MTSH_CMD_START_TIME=$(date +%s%N)
}

precmd_mtsh() {
    # Colors (bright, good for dark backgrounds)
    local C_BLUE='%F{117}'      # bright blue
    local C_MAGENTA='%F{213}'   # bright magenta/pink
    local C_YELLOW='%F{228}'    # bright yellow
    local C_GREEN='%F{121}'     # bright green
    local C_RED='%F{210}'       # bright red/coral
    local C_CYAN='%F{159}'      # bright cyan
    local C_WHITE='%F{255}'     # white
    local C_RESET='%f'

    # Date and time
    local current_time=$(date '+%H:%M:%S')
    local current_date=$(date '+%Y-%m-%d')

    # IPv4 address
    local ip_addr=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7}')
    [[ -z "$ip_addr" ]] && ip_addr="N/A"

    # Processing time (elapsed time for last command)
    local elapsed=""
    if [[ -n "$MTSH_CMD_START_TIME" ]]; then
        local end_time=$(date +%s%N)
        local diff_ns=$((end_time - MTSH_CMD_START_TIME))
        local diff_s=$(awk "BEGIN {printf \"%.3f\", $diff_ns/1000000000}")
        elapsed="${C_RED} Elapsed time: ${diff_s}s${C_RESET} | "
        unset MTSH_CMD_START_TIME
    fi

    # Git info (branch, hash, status, sync)
    local git_info=""
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local git_hash=$(git rev-parse --short HEAD 2>/dev/null)
        local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        local git_status=""
        # Show DIRTY in red if there are changes, CLEAN in green otherwise
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            git_status="${C_RED}DIRTY${C_RESET}"
        else
            git_status="${C_GREEN}CLEAN${C_RESET}"
        fi
        local git_sync=""
        local remote_branch="origin/${branch}"
        # Show sync status: behind, ahead, both, synced, or no remote
        if git rev-parse --verify "$remote_branch" &>/dev/null; then
            # Check if remote info is older than 5 minutes, if so, suggest fetch
            local remote_ref=".git/refs/remotes/origin/${branch}"
            local fetch_needed=""
            if [[ -f "$remote_ref" ]] && [[ $(($(date +%s) - $(stat -c %Y "$remote_ref" 2>/dev/null || echo 0))) -gt 300 ]]; then
                fetch_needed="${C_YELLOW}⚡${C_RESET}"
            fi
            
            local behind=$(git rev-list --count ${branch}..${remote_branch} 2>/dev/null)
            local ahead=$(git rev-list --count ${remote_branch}..${branch} 2>/dev/null)
            if [[ "$behind" -gt 0 && "$ahead" -gt 0 ]]; then
                git_sync="${C_YELLOW}⇣${behind} ⇡${ahead}${C_RESET}${fetch_needed}"
            elif [[ "$behind" -gt 0 ]]; then
                git_sync="${C_RED}⇣${behind} behind${C_RESET}${fetch_needed}"
            elif [[ "$ahead" -gt 0 ]]; then
                git_sync="${C_GREEN}⇡${ahead} ahead${C_RESET}${fetch_needed}"
            else
                git_sync="${C_BLUE}✔ synced${C_RESET}${fetch_needed}"
            fi
        else
            git_sync="${C_YELLOW}⚠ no remote${C_RESET}"
        fi
        git_info="${C_CYAN}Git${C_RESET}:${C_MAGENTA}${branch}${C_RESET} #${git_hash} ${git_status} ${git_sync}"
    else
        git_info="${C_RED}No Git Repo ${C_RESET}"
    fi

    # Directory (shortened: /a/b/c/.../_/x/y)
    local current_pwd="$PWD"
    [[ "$current_pwd" == "$HOME"* ]] && current_pwd="~${current_pwd#$HOME}"
    # Shorten long paths: /a/b/c/.../x/y
    if [[ $(echo "$current_pwd" | tr -cd '/' | wc -c) -gt 5 ]]; then
        current_pwd=$(echo "$current_pwd" | sed 's#\(/[^/]\{1,\}/[^/]\{1,\}/[^/]\{1,\}/\).*\(/[^/]\{1,\}/[^/]\{1,\}\)$#\1...\2#g')
    fi

    # RAM info (used/total)
    local ram_info=$(free -h | awk '/^Mem:/ {print $3"/"$2}')

    # Frame (visual separator)
    local line="───────────────────────────────────────────────────────────────────────────"
    print -P "┌${line}┐"
    print -P "│ ${elapsed}${C_BLUE}${current_date} ${current_time}${C_RESET} | ${C_MAGENTA}IPv4: ${ip_addr}${C_RESET}"
    print -P "│ ${C_YELLOW}${current_pwd}${C_RESET} | ${C_GREEN}RAM: ${ram_info}${C_RESET} | ${git_info}"
    print -P "└${line}┘"
}

preexec_functions+=(preexec_mtsh)  # Add preexec hook for command timing
precmd_functions+=(precmd_mtsh)    # Add precmd hook for prompt display

PROMPT='%F{121}%n%F{255}@%F{213}%m%f %F{228}>>>%f '
RPROMPT=''  # No right prompt

ZSH_THEME_GIT_PROMPT_PREFIX="git:(%F{red}"  # Git prompt prefix
ZSH_THEME_GIT_PROMPT_SUFFIX="%f)"           # Git prompt suffix
ZSH_THEME_GIT_PROMPT_DIRTY=" %F{yellow}✗(DIRTY)%f"  # Git prompt for dirty state
ZSH_THEME_GIT_PROMPT_CLEAN=" %F{green}✓%f"          # Git prompt for clean state
