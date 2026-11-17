#!/usr/bin/env bash

# Run with: bash zsh/install.sh
# Only touches zsh files; bash/install.sh is independent, so you can switch back anytime.
BASEDIR="$(cd "$(dirname -- "$0")" && pwd)"

# Install zsh and plugins
if [ "$(uname)" = "Darwin" ]; then
    if command -v brew >/dev/null 2>&1; then
        brew install zsh-autosuggestions fzf fd zoxide
    else
        echo "Homebrew not found; install it from https://brew.sh, then re-run this script."
        exit 1
    fi
else
    if ! command -v zsh >/dev/null 2>&1; then
        sudo apt install -y zsh || exit 1
    fi
    if [ ! -d ~/.zsh/zsh-autosuggestions ]; then
        mkdir -p ~/.zsh
        git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
    fi
fi

# Link ~/.zshrc, keeping a backup of any existing real file
[ -f ~/.zshrc ] && [ ! -L ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.bak
ln -sf "${BASEDIR}/.zshrc" ~/.zshrc

cat <<'EOF'

Done. Try it by running: zsh

To make zsh your default shell:   chsh -s "$(command -v zsh)"
To switch back to bash:           chsh -s /bin/bash
(On WSL, restart the terminal after chsh.)
EOF
