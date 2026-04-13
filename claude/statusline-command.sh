#!/bin/sh
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
rl_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_5h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl_7d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Shorten home directory to ~
home=$(echo "$HOME" | sed 's|/|\\/|g')
short_cwd=$(echo "$cwd" | sed "s|^$HOME|~|")

# Shorten model name (remove "claude-" prefix)
short_model=$(echo "$model" | sed 's/^claude-//')

# Git branch
git_branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" -c core.fsmonitor=false symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" -c core.fsmonitor=false rev-parse --short HEAD 2>/dev/null)
  [ -n "$branch" ] && git_branch=$(printf " \033[33m(%s)\033[0m" "$branch")
fi

# Separator
sep=$(printf " \033[37m·\033[0m")

# Model info
model_info=""
[ -n "$short_model" ] && model_info=$(printf "%s \033[92m%s\033[0m" "$sep" "$short_model")

# Context usage
ctx_info=""
[ -n "$used" ] && ctx_info=$(printf "%s \033[36mctx:%.0f%%\033[0m" "$sep" "$used")

# Rate limits
rl_5h_info=""
if [ -n "$rl_5h" ]; then
  rl_5h_time=""
  [ -n "$rl_5h_reset" ] && rl_5h_time=$(date -d "@$rl_5h_reset" "+%H:%M" 2>/dev/null)
  if [ -n "$rl_5h_time" ]; then
    rl_5h_info=$(printf "%s \033[33m5h:%.0f%%(%s)\033[0m" "$sep" "$rl_5h" "$rl_5h_time")
  else
    rl_5h_info=$(printf "%s \033[33m5h:%.0f%%\033[0m" "$sep" "$rl_5h")
  fi
fi

rl_7d_info=""
if [ -n "$rl_7d" ]; then
  rl_7d_day=""
  [ -n "$rl_7d_reset" ] && rl_7d_day=$(date -d "@$rl_7d_reset" "+%a" 2>/dev/null)
  if [ -n "$rl_7d_day" ]; then
    rl_7d_info=$(printf "%s \033[33m7d:%.0f%%(%s)\033[0m" "$sep" "$rl_7d" "$rl_7d_day")
  else
    rl_7d_info=$(printf "%s \033[33m7d:%.0f%%\033[0m" "$sep" "$rl_7d")
  fi
fi

printf "\033[96m%s\033[0m%s%s%s%s%s\n" "$short_cwd" "$git_branch" "$model_info" "$ctx_info" "$rl_5h_info" "$rl_7d_info"
