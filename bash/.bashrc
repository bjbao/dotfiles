# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
# HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
# shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
# HISTSIZE=1000
# HISTFILESIZE=2000
HISTSIZE=9000
HISTFILESIZE=$HISTSIZE
HISTCONTROL=ignorespace:ignoredups
_bash_history_sync() {
    builtin history -a
    HISTFILESIZE=$HISTSIZE
}
history() {
    _bash_history_sync
    builtin history "$@"
}
PROMPT_COMMAND=_bash_history_sync
 
if [[ "$-" =~ "i" ]] # Don't do this on non-interactive shells
then
    # Add MATLAB-style up-arrow, so if you type "ca[UP ARROW]" you'll get
    # completions for only things that start with "ca" like "cat abc.txt"
    bind '"\e[A":history-search-backward'
    bind '"\e[B":history-search-forward'
fi

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/bao4/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/bao4/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/bao4/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/bao4/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH=$PATH:/home/bao4/Projects/moos-ivp/bin
export PATH="/home/bao4/.local/bin:$PATH"
# Plotly and RVIZ crash in WSL
export LIBGL_ALWAYS_SOFTWARE=true

# Built in Git in Bash
# https://ezprompt.net/
# get current branch in git repo
function parse_git_branch() {
	BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
	if [ ! "${BRANCH}" == "" ]
	then
		# STAT=`parse_git_dirty`
		# echo "[${BRANCH}${STAT}]"
		echo "[${BRANCH}]"
	else
		echo ""
	fi
}

# get current status of git repo, slow
function parse_git_dirty {
	status=`git status 2>&1 | tee`
	dirty=`echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?"`
	untracked=`echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?"`
	ahead=`echo -n "${status}" 2> /dev/null | grep "Your branch is ahead of" &> /dev/null; echo "$?"`
	newfile=`echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?"`
	renamed=`echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?"`
	deleted=`echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?"`
	bits=''
	if [ "${renamed}" == "0" ]; then
		bits=">${bits}"
	fi
	if [ "${ahead}" == "0" ]; then
		bits="*${bits}"
	fi
	if [ "${newfile}" == "0" ]; then
		bits="+${bits}"
	fi
	if [ "${untracked}" == "0" ]; then
		bits="?${bits}"
	fi
	if [ "${deleted}" == "0" ]; then
		bits="x${bits}"
	fi
	if [ "${dirty}" == "0" ]; then
		bits="!${bits}"
	fi
	if [ ! "${bits}" == "" ]; then
		echo " ${bits}"
	else
		echo ""
	fi
}
export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_SHOWDIRTYSTATE=1
export PS1="\[\e[32m\]\u\[\e[m\]\[\e[32m\]@\[\e[m\]\[\e[32m\]\h\[\e[m\]\[\e[36m\]\`parse_git_branch\`\[\e[m\]:\[\e[34m\]\w\[\e[m\]\\$ "

# Add z jump https://github.com/rupa/z.git
# . ~/src/z/z.sh
. "$HOME/.cargo/env"

# Direnv for Nix
eval "$(direnv hook bash)"

# zoxide and fzf
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --exclude .git' 
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND" 
export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --exclude .git' 
[ -f ~/.fzf.bash ] && source ~/.fzf.bash 
eval "$(zoxide init bash)"

# Function to fetch zoxide paths into fzf and paste to command line
_z_path_widget() {
    # Get the path from zoxide and fzf
    local selected_path=$(zoxide query -l | fzf --height 40% --reverse --header="Insert Z-Path")
    
    # If a path was selected, insert it into the current command line
    if [ -n "$selected_path" ]; then 
        READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}$selected_path${READLINE_LINE:$READLINE_POINT}" 
        READLINE_POINT=$((READLINE_POINT + ${#selected_path}))
    fi
}

# Bind the function to Alt-z (\ez)
bind -x '"\ez": _z_path_widget'

if [[ -n "$BASH_VERSION" ]]; then 
    WIN_HOME=$(powershell.exe -c 'Write-Host -NoNewLine $env:userprofile' | xargs -0 wslpath)
    # Custom search that looks in both WSL home and Windows User folder Replace 'YourWindowsName' with your actual 
    # Windows username
    find_both() {
    local selected=$(
        fd . ~ "$WIN_HOME" --max-depth 4 \
        | fzf --height 40% --layout=reverse \
              --header="Searching WSL + Windows"
    )

    if [ -n "$selected" ]; then
        if [ -d "$selected" ]; then
            cd "$selected"
        else
            local left="${READLINE_LINE:0:READLINE_POINT}"
            local right="${READLINE_LINE:READLINE_POINT}"
            READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}$selected${READLINE_LINE:$READLINE_POINT}"
            READLINE_POINT=$((READLINE_POINT + ${#selected}))
        fi
    fi
    }
    bind -x '"\ew": find_both' # Mapped to Alt+w
fi
