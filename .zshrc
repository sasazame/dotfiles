# If not running interactively, don't do anything
[[ -o interactive ]] || return

# History
HISTSIZE=100000
SAVEHIST=200000
HISTFILE="$HOME/.zsh_history"
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt share_history

# Use emacs keybindings even if EDITOR is set to vi
bindkey -e

# Completion
autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
if command -v dircolors >/dev/null 2>&1; then
    eval "$(dircolors -b)"
fi
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Git new branch with auto-reset
gnb() {
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    # Create new branch
    git checkout -b "$1"

    # If we were on main or develop, reset it to origin
    if [[ "$current_branch" == "main" ]] || [[ "$current_branch" == "develop" ]]; then
        if git rev-parse --verify "origin/$current_branch" >/dev/null 2>&1; then
            local behind_ahead
            local behind_count
            local ahead_count
            behind_ahead=$(git rev-list --left-right --count "origin/$current_branch...$current_branch" 2>/dev/null || echo "0 0")
            behind_count=${behind_ahead%% *}
            ahead_count=${behind_ahead##* }

            if [ "$ahead_count" -gt 0 ]; then
                echo "⚠️  $current_branch has $ahead_count local commit(s) not on origin/$current_branch."
                echo "    Skipping reset to avoid losing local commits."
            else
                git branch -f "$current_branch" "origin/$current_branch"
                echo "✅ Created branch $1 and reset $current_branch to origin/$current_branch"
            fi
        else
            echo "⚠️  origin/$current_branch not found; skipping reset."
        fi
    fi
}

# mise activation (for direnv + tool shims)
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi

# Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
