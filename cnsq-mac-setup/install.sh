#!/bin/bash

#############################################################################
# CNSQ NetOps Mac Setup - Requirements Installation Script
# One-liner installation of all required tools
#############################################################################

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     CNSQ NetOps Mac Setup - Requirements Installer${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
    echo -e "${RED}Error: Homebrew is not installed!${NC}"
    echo -e "Please install Homebrew first:"
    echo -e "${YELLOW}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Homebrew detected\n"

# Update Homebrew
echo -e "${YELLOW}Updating Homebrew...${NC}"
brew update

# Core Development Tools
echo -e "\n${BLUE}Installing Core Development Tools...${NC}"
CORE_TOOLS=(
    "git"
    "neovim"
    "tmux"
    "python@3"
    "node"
    "jq"
    "ripgrep"
    "tree"
    "wget"
    "curl"
)

for tool in "${CORE_TOOLS[@]}"; do
    if brew list "$tool" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $tool already installed"
    else
        echo -e "Installing $tool..."
        brew install "$tool"
    fi
done

# Networking Tools
echo -e "\n${BLUE}Installing Networking Tools...${NC}"
NETWORK_TOOLS=(
    "nmap"
    "mtr"
    "telnet"
    "netcat"
    "bind"  # for dig/nslookup
    "sipcalc"
    "openssh"
)

for tool in "${NETWORK_TOOLS[@]}"; do
    if brew list "$tool" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $tool already installed"
    else
        echo -e "Installing $tool..."
        brew install "$tool"
    fi
done

# Automation Tools
echo -e "\n${BLUE}Installing Automation Tools...${NC}"
AUTOMATION_TOOLS=(
    "ansible"
    "expect"
    "watch"
    "fswatch"
)

for tool in "${AUTOMATION_TOOLS[@]}"; do
    if brew list "$tool" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $tool already installed"
    else
        echo -e "Installing $tool..."
        brew install "$tool"
    fi
done

# Shell Enhancements
echo -e "\n${BLUE}Installing Shell Enhancements...${NC}"
SHELL_TOOLS=(
    "eza"
    "zsh-syntax-highlighting"
    "zsh-autosuggestions"
    "gh"  # GitHub CLI
    "htop"
)

for tool in "${SHELL_TOOLS[@]}"; do
    if brew list "$tool" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $tool already installed"
    else
        echo -e "Installing $tool..."
        brew install "$tool"
    fi
done

# Special case: sshpass (different tap)
echo -e "\n${BLUE}Installing sshpass...${NC}"
if brew list sshpass &>/dev/null; then
    echo -e "${GREEN}✓${NC} sshpass already installed"
else
    brew install hudochenkov/sshpass/sshpass
fi

# Python Virtual Environment Setup
echo -e "\n${BLUE}Setting up Python environment...${NC}"
if [[ ! -d "$HOME/.cnsq-venv" ]]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "$HOME/.cnsq-venv"
fi

echo "Installing Python packages..."
"$HOME/.cnsq-venv/bin/pip" install --quiet --upgrade pip
"$HOME/.cnsq-venv/bin/pip" install --quiet \
    paramiko \
    netmiko \
    napalm \
    textfsm \
    pyyaml \
    jinja2 \
    requests \
    cryptography \
    ansible-core

echo -e "${GREEN}✓${NC} Python environment configured"

# Ansible Collections
echo -e "\n${BLUE}Installing Ansible Collections...${NC}"
ansible-galaxy collection install ansible.netcommon --force
ansible-galaxy collection install ansible.utils --force
ansible-galaxy collection install ansible.posix --force
ansible-galaxy collection install cisco.ios --force
ansible-galaxy collection install cisco.iosxr --force
ansible-galaxy collection install junipernetworks.junos --force
ansible-galaxy collection install arista.eos --force

# Shell Configuration
echo -e "\n${BLUE}Configuring shell environment...${NC}"

# Create directories
mkdir -p "$HOME/.zsh"
mkdir -p "$HOME/.config/nvim"
mkdir -p "$HOME/.ansible/roles"

# Create aliases file
cat > "$HOME/.zsh/aliases.zsh" << 'EOF'
# CNSQ NetOps Aliases
alias ll='eza -lh --git --group-directories-first --icons'
alias ls='eza --icons'
alias tree='eza --tree --icons'
alias vi='nvim'
alias vim='nvim'

# Git shortcuts
alias gs='git status'
alias gp='git pull'
alias gc='git commit'
alias gd='git diff'
alias gl='git log --oneline --graph'

# Python environment
alias cnsq-env='source $HOME/.cnsq-venv/bin/activate'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
EOF

# Create functions file
cat > "$HOME/.zsh/functions.zsh" << 'EOF'
# CNSQ NetOps Functions

# Quick SSH
sshto() {
    ssh admin@"$1"
}

# Ping multiple hosts
pingall() {
    for host in "$@"; do
        echo -n "$host: "
        ping -c 1 -W 1 "$host" &>/dev/null && echo "✓ UP" || echo "✗ DOWN"
    done
}

# Show IP addresses
myip() {
    echo "Local:    $(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1)"
    echo "External: $(curl -s ifconfig.me)"
}

# Extract archives
extract() {
    case $1 in
        *.tar.gz)  tar xzf "$1" ;;
        *.tar.bz2) tar xjf "$1" ;;
        *.zip)     unzip "$1" ;;
        *.7z)      7z x "$1" ;;
        *)         echo "Unknown archive type" ;;
    esac
}

# Make directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}
EOF

# Create basic Neovim config
cat > "$HOME/.config/nvim/init.vim" << 'EOF'
" CNSQ NetOps Neovim Configuration
set number
set relativenumber
set expandtab
set tabstop=2
set shiftwidth=2
set autoindent
set smartindent
EOF

# Add to .zshrc if not already there
if [[ -f "$HOME/.zshrc" ]]; then
    if ! grep -q "CNSQ NetOps Setup" "$HOME/.zshrc"; then
        cat >> "$HOME/.zshrc" << 'EOF'

# CNSQ NetOps Setup
for config in $HOME/.zsh/*.zsh; do
    [[ -f "$config" ]] && source "$config"
done
EOF
    fi
fi

echo -e "${GREEN}✓${NC} Shell configuration complete"

# Summary
echo -e "\n${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}                    Installation Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}Next Steps:${NC}"
echo -e "1. Restart your terminal or run: ${BLUE}source ~/.zshrc${NC}"
echo -e "2. Activate Python environment: ${BLUE}cnsq-env${NC}"
echo -e "3. Test installations: ${BLUE}ansible --version${NC}"
echo ""
echo -e "${GREEN}Your NetOps environment is ready!${NC}"