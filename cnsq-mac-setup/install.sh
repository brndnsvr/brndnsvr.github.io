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
    if brew list "$tool" &>/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $tool already installed"
    else
        echo -e "Installing $tool..."
        brew install "$tool" || echo -e "${YELLOW}Warning: Failed to install $tool${NC}"
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
    if brew list "$tool" &>/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $tool already installed"
    else
        echo -e "Installing $tool..."
        brew install "$tool" || echo -e "${YELLOW}Warning: Failed to install $tool${NC}"
    fi
done

# Automation Tools - Ansible needs special handling
echo -e "\n${BLUE}Installing Automation Tools...${NC}"

# Install Ansible (requires Python)
if brew list ansible &>/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} ansible already installed"
else
    echo -e "Installing ansible..."
    brew install ansible || echo -e "${YELLOW}Warning: Failed to install ansible via brew${NC}"
fi

# Other automation tools
AUTOMATION_TOOLS=(
    "expect"
    "watch"
    "fswatch"
)

for tool in "${AUTOMATION_TOOLS[@]}"; do
    if brew list "$tool" &>/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $tool already installed"
    else
        echo -e "Installing $tool..."
        brew install "$tool" || echo -e "${YELLOW}Warning: Failed to install $tool${NC}"
    fi
done

# Shell Enhancements - Fix eza installation
echo -e "\n${BLUE}Installing Shell Enhancements...${NC}"

# Install eza separately (sometimes needs updating taps)
if brew list eza &>/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} eza already installed"
else
    echo -e "Installing eza..."
    brew install eza || {
        echo -e "${YELLOW}Trying alternative eza installation...${NC}"
        brew tap homebrew/core
        brew install eza
    }
fi

# Other shell tools
SHELL_TOOLS=(
    "zsh-syntax-highlighting"
    "zsh-autosuggestions"
    "gh"  # GitHub CLI
    "htop"
)

for tool in "${SHELL_TOOLS[@]}"; do
    if brew list "$tool" &>/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $tool already installed"
    else
        echo -e "Installing $tool..."
        brew install "$tool" || echo -e "${YELLOW}Warning: Failed to install $tool${NC}"
    fi
done

# Special case: sshpass (different tap, may be blocked by macOS)
echo -e "\n${BLUE}Installing sshpass...${NC}"
if brew list sshpass &>/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} sshpass already installed"
else
    echo -e "${YELLOW}Note: sshpass may be blocked by macOS security. Attempting install...${NC}"
    brew tap hudochenkov/sshpass 2>/dev/null || true
    brew install hudochenkov/sshpass/sshpass 2>/dev/null || {
        echo -e "${YELLOW}sshpass installation blocked by macOS. This is normal.${NC}"
        echo -e "${YELLOW}You can install it manually later if needed.${NC}"
    }
fi

# Python Setup - Ensure pip is available
echo -e "\n${BLUE}Setting up Python environment...${NC}"

# First ensure pip is installed
if ! python3 -m pip --version &>/dev/null 2>&1; then
    echo -e "${YELLOW}pip not found, installing...${NC}"
    python3 -m ensurepip 2>/dev/null || {
        echo -e "${YELLOW}Installing pip via get-pip.py...${NC}"
        curl -s https://bootstrap.pypa.io/get-pip.py | python3
    }
fi

# Create virtual environment
if [[ ! -d "$HOME/.cnsq-venv" ]]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "$HOME/.cnsq-venv"
else
    echo -e "${GREEN}✓${NC} Virtual environment already exists"
fi

# Upgrade pip in virtual environment
echo "Upgrading pip in virtual environment..."
"$HOME/.cnsq-venv/bin/python" -m pip install --quiet --upgrade pip

# Install Python packages
echo "Installing Python packages..."
PYTHON_PACKAGES=(
    "paramiko"
    "netmiko"
    "napalm"
    "textfsm"
    "pyyaml"
    "jinja2"
    "requests"
    "cryptography"
    "ansible-core"
)

for package in "${PYTHON_PACKAGES[@]}"; do
    echo -e "  Installing $package..."
    "$HOME/.cnsq-venv/bin/pip" install --quiet "$package" || echo -e "${YELLOW}  Warning: Failed to install $package${NC}"
done

echo -e "${GREEN}✓${NC} Python environment configured"

# Ansible Collections - Only if ansible is available
if command -v ansible-galaxy &>/dev/null 2>&1; then
    echo -e "\n${BLUE}Installing Ansible Collections...${NC}"
    
    ANSIBLE_COLLECTIONS=(
        "ansible.netcommon"
        "ansible.utils"
        "ansible.posix"
        "cisco.ios"
        "cisco.iosxr"
        "junipernetworks.junos"
        "arista.eos"
    )
    
    for collection in "${ANSIBLE_COLLECTIONS[@]}"; do
        echo -e "  Installing $collection..."
        ansible-galaxy collection install "$collection" --force 2>/dev/null || echo -e "${YELLOW}  Warning: Failed to install $collection${NC}"
    done
else
    echo -e "${YELLOW}Ansible not found, skipping collections installation${NC}"
fi

# Shell Configuration
echo -e "\n${BLUE}Configuring shell environment...${NC}"

# Create directories
mkdir -p "$HOME/.zsh"
mkdir -p "$HOME/.config/nvim"
mkdir -p "$HOME/.ansible/roles"

# Create aliases file
cat > "$HOME/.zsh/aliases.zsh" << 'EOF'
# CNSQ NetOps Aliases

# Modern replacements (only if eza is installed)
if command -v eza &>/dev/null; then
    alias ll='eza -lh --git --group-directories-first --icons'
    alias ls='eza --icons'
    alias tree='eza --tree --icons'
else
    alias ll='ls -lah'
fi

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
alias pip='pip3'
alias python='python3'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
EOF

# Create functions file
cat > "$HOME/.zsh/functions.zsh" << 'EOF'
# CNSQ NetOps Functions

# Quick SSH
sshto() {
    if [ -z "$1" ]; then
        echo "Usage: sshto <hostname or IP>"
        return 1
    fi
    ssh "${SSHUSER:-admin}@$1"
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
    echo "Local:    $(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo 'Not found')"
    echo "External: $(curl -s ifconfig.me 2>/dev/null || echo 'Unable to determine')"
}

# Extract archives
extract() {
    if [ -f "$1" ]; then
        case $1 in
            *.tar.gz)  tar xzf "$1" ;;
            *.tar.bz2) tar xjf "$1" ;;
            *.zip)     unzip "$1" ;;
            *.7z)      7z x "$1" ;;
            *)         echo "Unknown archive type: $1" ;;
        esac
    else
        echo "File not found: $1"
    fi
}

# Make directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Weather function
weather() {
    case $1 in
        nyc)     curl "wttr.in/New+York+NY?u" ;;
        dallas)  curl "wttr.in/Dallas+TX?u" ;;
        la)      curl "wttr.in/Los+Angeles+CA?u" ;;
        chicago) curl "wttr.in/Chicago+IL?u" ;;
        *)       echo "Usage: weather {nyc|dallas|la|chicago}" ;;
    esac
}

# Initialize SSH agent
init_ssh_agent() {
    if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)"
    fi
    
    if [ -f "$SSHKEYPATH" ]; then
        ssh-add "$SSHKEYPATH"
    else
        echo "SSH key not found at $SSHKEYPATH"
    fi
}

# Show listening ports
ports() {
    if [ "$1" = "-a" ]; then
        sudo lsof -i -P -n
    else
        sudo lsof -i -P -n | grep LISTEN
    fi
}
EOF

echo -e "${GREEN}✓${NC} Created ~/.zsh/functions.zsh"

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
        echo -e "${GREEN}✓${NC} Added sourcing to ~/.zshrc"
    else
        echo -e "${GREEN}✓${NC} ~/.zshrc already configured"
    fi
else
    echo -e "${YELLOW}Note: ~/.zshrc not found. You may need to create it.${NC}"
fi

echo -e "${GREEN}✓${NC} Shell configuration complete"

# Summary
echo -e "\n${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}                    Installation Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}\n"

# Check what actually got installed
echo -e "${BLUE}Verification:${NC}"
command -v ansible &>/dev/null && echo -e "  ${GREEN}✓${NC} Ansible installed" || echo -e "  ${YELLOW}✗${NC} Ansible not found"
command -v eza &>/dev/null && echo -e "  ${GREEN}✓${NC} eza installed" || echo -e "  ${YELLOW}✗${NC} eza not found"
[[ -f "$HOME/.zsh/functions.zsh" ]] && echo -e "  ${GREEN}✓${NC} functions.zsh created" || echo -e "  ${YELLOW}✗${NC} functions.zsh missing"
[[ -d "$HOME/.cnsq-venv" ]] && echo -e "  ${GREEN}✓${NC} Python venv created" || echo -e "  ${YELLOW}✗${NC} Python venv missing"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "1. Restart your terminal or run: ${BLUE}source ~/.zshrc${NC}"
echo -e "2. Activate Python environment: ${BLUE}cnsq-env${NC}"
echo -e "3. Test installations: ${BLUE}ansible --version${NC}"
echo ""
echo -e "${GREEN}Your NetOps environment is ready!${NC}"