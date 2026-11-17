# If not running interactively, don't do anything
[[ -o interactive ]] || return

# ---------- History ----------
HISTFILE=~/.zsh_history
HISTSIZE=9000
SAVEHIST=9000
setopt SHARE_HISTORY          # share and append history across terminals
setopt HIST_IGNORE_DUPS       # no consecutive duplicates
setopt HIST_IGNORE_SPACE      # lines starting with a space aren't saved

# MATLAB-style up-arrow: type "ca[UP]" to cycle only commands starting with "ca"
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
bindkey '^[OA' history-beginning-search-backward
bindkey '^[OB' history-beginning-search-forward

# ---------- Completion ----------
# Homebrew (Apple Silicon: /opt/homebrew, Intel: /usr/local); sets PATH and HOMEBREW_PREFIX
if ! command -v brew >/dev/null 2>&1; then
    for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        [[ -x $_brew ]] && eval "$($_brew shellenv)" && break
    done
    unset _brew
fi
# Add brew's completions to fpath before compinit
[[ -n $HOMEBREW_PREFIX && -d $HOMEBREW_PREFIX/share/zsh/site-functions ]] \
    && fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
[[ -n $LS_COLORS ]] && zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ---------- Autosuggestions ----------
# Linux: git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
# macOS: brew install zsh-autosuggestions
for f in \
    ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
    if [[ -f $f ]]; then
        source "$f"
        break
    fi
done
unset f
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
bindkey '^[[Z' autosuggest-accept   # Shift-Tab accepts the suggestion (Right arrow / End also work)

# ---------- Aliases ----------
if [[ $OSTYPE == darwin* ]]; then
    export CLICOLOR=1
    alias ls='ls -G'
else
    alias ls='ls --color=auto'
fi
alias grep='grep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

if [[ $OSTYPE == darwin* ]]; then
    alias alert='osascript -e "display notification \"$(fc -ln -1 | sed "s/[\"\\\\]/ /g")\" with title \"Done\""'
elif command -v notify-send >/dev/null 2>&1; then
    alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(fc -ln -1)"'
fi

if [[ -n $WSL_DISTRO_NAME ]]; then
    alias wcode="/mnt/c/Users/$USER/AppData/Local/Programs/Microsoft\ VS\ Code/Code.exe"
    alias npp='/mnt/c/Program\ Files/Notepad++/notepad++.exe'
    export LIBGL_ALWAYS_SOFTWARE=true   # Plotly and RVIZ crash in WSL
fi

# ---------- Prompt: user@host[branch]:path$ ----------
setopt PROMPT_SUBST
_git_branch() {
    local b
    b=$(git symbolic-ref --short HEAD 2>/dev/null) || b=$(git rev-parse --short HEAD 2>/dev/null) || return
    echo "[$b]"
}
PROMPT='%F{green}%n@%m%f%F{cyan}$(_git_branch)%f:%F{blue}%~%f%(!.#.$) '

# ---------- PATH and tool setup ----------
[[ -d ~/Projects/moos-ivp/bin ]] && export PATH="$PATH:$HOME/Projects/moos-ivp/bin"
[[ -d ~/.local/bin ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d ~/.opencode/bin ]] && export PATH="$HOME/.opencode/bin:$PATH"
[[ -f ~/.cargo/env ]] && . ~/.cargo/env

# >>> conda initialize >>>
for _conda in ~/anaconda3 ~/miniconda3 /opt/homebrew/Caskroom/miniconda/base; do
    if [[ -x $_conda/bin/conda ]]; then
        __conda_setup="$("$_conda/bin/conda" 'shell.zsh' 'hook' 2>/dev/null)"
        if [[ $? -eq 0 ]]; then
            eval "$__conda_setup"
        elif [[ -f $_conda/etc/profile.d/conda.sh ]]; then
            . "$_conda/etc/profile.d/conda.sh"
        else
            export PATH="$_conda/bin:$PATH"
        fi
        unset __conda_setup
        break
    fi
done
unset _conda
# <<< conda initialize <<<

command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# ---------- fzf and zoxide ----------
if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --exclude .git'
fi
if [[ -f ~/.fzf.zsh ]]; then
    source ~/.fzf.zsh
elif command -v fzf >/dev/null 2>&1 && fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
fi
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# Alt-z: pick a zoxide path with fzf and insert it at the cursor
_z_path_widget() {
    local selected_path
    selected_path=$(zoxide query -l | fzf --height 40% --reverse --header="Insert Z-Path")
    [[ -n $selected_path ]] && LBUFFER+="${(q)selected_path}"
    zle reset-prompt
}
zle -N _z_path_widget
bindkey '^[z' _z_path_widget
# macOS Terminal sends special characters for Option+key unless "Use Option as Meta" is on
[[ $OSTYPE == darwin* ]] && bindkey 'Ω' _z_path_widget

# Alt-w: search WSL home + Windows user folder (WSL only)
if [[ -n $WSL_DISTRO_NAME ]]; then
    _find_both_widget() {
        if [[ -z $WIN_HOME ]]; then
            WIN_HOME=$(powershell.exe -c 'Write-Host -NoNewLine $env:userprofile' | xargs -0 wslpath)
        fi
        local selected
        selected=$(fd . ~ "$WIN_HOME" --max-depth 4 \
            | fzf --height 40% --layout=reverse --header="Searching WSL + Windows")
        if [[ -n $selected ]]; then
            if [[ -d $selected ]]; then
                cd "$selected"
            else
                LBUFFER+="${(q)selected}"
            fi
        fi
        zle reset-prompt
    }
    zle -N _find_both_widget
    bindkey '^[w' _find_both_widget
fi
