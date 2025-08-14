#!/bin/bash

#############################################################################
# CNSQ NetOps Mac Setup - Requirements Installation Script
# One-liner installation of all required tools
#############################################################################

set -uo pipefail

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

# Function to install a brew package
install_brew_package() {
    local package="$1"
    local package_name="${2:-$package}"  # Display name, defaults to package name
    
    if brew list "$package" &>/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $package_name already installed"
    else
        echo -e "Installing $package_name..."
        if brew install "$package"; then
            echo -e "${GREEN}✓${NC} $package_name installed successfully"
        else
            echo -e "${YELLOW}⚠${NC} Failed to install $package_name - continuing with other packages"
        fi
    fi
}

# Core Development Tools
echo -e "\n${BLUE}Installing Core Development Tools...${NC}"
install_brew_package "git"
install_brew_package "neovim"
install_brew_package "tmux"
install_brew_package "python@3" "Python 3"
install_brew_package "node" "Node.js"
install_brew_package "jq"
install_brew_package "ripgrep"
install_brew_package "tree"
install_brew_package "wget"
install_brew_package "curl"
install_brew_package "htop"
install_brew_package "ncdu" "ncdu (disk usage analyzer)"

# Networking Tools - Some have special names
echo -e "\n${BLUE}Installing Networking Tools...${NC}"
install_brew_package "nmap"
install_brew_package "masscan" "masscan (fast port scanner)"
install_brew_package "zmap" "zmap (internet scanner)"

# mtr needs special handling on macOS
if ! command -v mtr &>/dev/null 2>&1; then
    echo -e "Installing mtr (requires sudo)..."
    if brew install mtr 2>/dev/null; then
        # mtr needs special permissions on macOS
        if [[ -f "/opt/homebrew/sbin/mtr" ]]; then
            echo -e "${YELLOW}Note: mtr installed at /opt/homebrew/sbin/mtr${NC}"
            echo -e "${YELLOW}You may need to run: sudo chown root /opt/homebrew/sbin/mtr${NC}"
            echo -e "${YELLOW}And: sudo chmod u+s /opt/homebrew/sbin/mtr${NC}"
        fi
    else
        echo -e "${YELLOW}⚠${NC} Failed to install mtr - continuing"
    fi
else
    echo -e "${GREEN}✓${NC} mtr already installed"
fi

install_brew_package "telnet"
install_brew_package "netcat"
install_brew_package "bind" "bind (dig/nslookup)"
install_brew_package "ipcalc"  # Note: using ipcalc instead of sipcalc
install_brew_package "openssh"
install_brew_package "iperf3" "iperf3 (bandwidth testing)"
install_brew_package "speedtest-cli" "speedtest-cli"
install_brew_package "httpie" "HTTPie (HTTP client)"
install_brew_package "curl" "curl"
install_brew_package "wget" "wget"
install_brew_package "aria2" "aria2 (download accelerator)"
install_brew_package "rsync" "rsync"
install_brew_package "ngrep" "ngrep (network grep)"
install_brew_package "tcpdump" "tcpdump"
install_brew_package "wireshark" "Wireshark (CLI tools)"
install_brew_package "arp-scan" "arp-scan"
install_brew_package "fping" "fping (parallel ping)"

# Ansible - Install via pip in venv instead of brew for better compatibility
echo -e "\n${BLUE}Installing Ansible...${NC}"
if command -v ansible &>/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Ansible already installed"
else
    echo -e "Ansible will be installed via pip in virtual environment"
fi

# Security Tools
echo -e "\n${BLUE}Installing Security Tools...${NC}"
install_brew_package "gnupg" "GnuPG"
install_brew_package "pass" "pass (password manager)"
install_brew_package "pwgen" "pwgen (password generator)"
install_brew_package "oath-toolkit" "oath-toolkit (OTP tools)"

# Other automation tools
echo -e "\n${BLUE}Installing Other Automation Tools...${NC}"
install_brew_package "expect"
install_brew_package "watch"
install_brew_package "fswatch"
install_brew_package "pv" "pv (pipe viewer)"
install_brew_package "parallel" "GNU parallel"
install_brew_package "screen" "screen"
install_brew_package "ag" "The Silver Searcher"
install_brew_package "fzf" "fzf (fuzzy finder)"
install_brew_package "tldr" "tldr (simplified man pages)"
install_brew_package "direnv" "direnv (environment manager)"
install_brew_package "yq" "yq (YAML processor)"
install_brew_package "glow" "glow (markdown viewer)"

# Shell Enhancements
echo -e "\n${BLUE}Installing Shell Enhancements...${NC}"

# eza might be in a different tap or have issues, try with fallback
if ! command -v eza &>/dev/null 2>&1 && ! command -v exa &>/dev/null 2>&1; then
    echo -e "Installing eza..."
    if ! brew install eza 2>/dev/null; then
        echo -e "${YELLOW}eza not available, trying exa as fallback...${NC}"
        if ! brew install exa 2>/dev/null; then
            echo -e "${YELLOW}⚠${NC} Could not install eza or exa - continuing"
        else
            echo -e "${GREEN}✓${NC} exa installed as alternative to eza"
        fi
    else
        echo -e "${GREEN}✓${NC} eza installed successfully"
    fi
else
    command -v eza &>/dev/null && echo -e "${GREEN}✓${NC} eza already installed"
    command -v exa &>/dev/null && echo -e "${GREEN}✓${NC} exa already installed"
fi

install_brew_package "zsh-syntax-highlighting"
install_brew_package "zsh-autosuggestions"
install_brew_package "gh" "GitHub CLI"
install_brew_package "bat" "bat (better cat)"
install_brew_package "fd" "fd (better find)"
install_brew_package "duf" "duf (better df)"
install_brew_package "dust" "dust (better du)"
install_brew_package "procs" "procs (better ps)"
install_brew_package "bottom" "bottom (system monitor)"
install_brew_package "glances" "glances (system monitor)"

# Python Setup
echo -e "\n${BLUE}Setting up Python environment...${NC}"

# Ensure pip3 is available
if ! command -v pip3 &>/dev/null 2>&1; then
    echo -e "${YELLOW}Installing pip3...${NC}"
    python3 -m ensurepip --upgrade 2>/dev/null || {
        echo -e "${YELLOW}Downloading get-pip.py...${NC}"
        curl -s https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
        python3 /tmp/get-pip.py --user
        rm /tmp/get-pip.py
    }
fi

# SSH and Remote Tools
echo -e "\n${BLUE}Installing SSH and Remote Tools...${NC}"
install_brew_package "autossh" "autossh (persistent SSH)"
install_brew_package "mosh" "mosh (mobile shell)"
install_brew_package "sshuttle" "sshuttle (VPN over SSH)"
install_brew_package "pssh" "pssh (parallel SSH)"

# Create virtual environment
if [[ ! -d "$HOME/.cnsq-venv" ]]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "$HOME/.cnsq-venv"
else
    echo -e "${GREEN}✓${NC} Virtual environment already exists"
fi

# Install packages in virtual environment
echo "Installing Python packages in virtual environment..."
"$HOME/.cnsq-venv/bin/python" -m pip install --upgrade pip --quiet

PYTHON_PACKAGES=(
    "ansible"
    "ansible-core"
    "paramiko"
    "netmiko"
    "napalm"
    "textfsm"
    "pyyaml"
    "jinja2"
    "requests"
    "cryptography"
)

for package in "${PYTHON_PACKAGES[@]}"; do
    echo -e "  Installing $package..."
    "$HOME/.cnsq-venv/bin/pip" install "$package" --quiet 2>/dev/null || echo -e "${YELLOW}  Warning: Issues installing $package${NC}"
done

echo -e "${GREEN}✓${NC} Python environment configured"

# Ansible Collections
if "$HOME/.cnsq-venv/bin/ansible-galaxy" --version &>/dev/null 2>&1; then
    echo -e "\n${BLUE}Installing Ansible Collections...${NC}"
    
    # Create ansible directory
    mkdir -p "$HOME/.ansible/collections"
    
    ANSIBLE_COLLECTIONS=(
        "ansible.netcommon"
        "ansible.utils"
        "ansible.posix"
        "cisco.ios"
        "cisco.iosxr"
        "cisco.nxos"
        "junipernetworks.junos"
        "arista.eos"
    )
    
    for collection in "${ANSIBLE_COLLECTIONS[@]}"; do
        echo -e "  Installing $collection..."
        "$HOME/.cnsq-venv/bin/ansible-galaxy" collection install "$collection" --force 2>/dev/null || echo -e "${YELLOW}  Warning: Issues with $collection${NC}"
    done
else
    echo -e "${YELLOW}Ansible not found in venv, skipping collections${NC}"
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

# Modern replacements (only if tools are installed)
command -v eza &>/dev/null && alias ls='eza --icons' || alias ls='ls -G'
command -v eza &>/dev/null && alias ll='eza -lh --git --group-directories-first --icons' || alias ll='ls -lah'
command -v eza &>/dev/null && alias tree='eza --tree --icons' || alias tree='tree'
command -v bat &>/dev/null && alias cat='bat'
command -v fd &>/dev/null && alias find='fd'

# Editor
alias vi='nvim'
alias vim='nvim'

# Git shortcuts
alias gs='git status'
alias gp='git pull'
alias gc='git commit'
alias gd='git diff'
alias gl='git log --oneline --graph'

# Python
alias python='python3'
alias pip='pip3'
alias cnsq-env='source $HOME/.cnsq-venv/bin/activate'
alias cnsq-ansible='source $HOME/.cnsq-venv/bin/activate && ansible'

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
            *.tar.xz)  tar xJf "$1" ;;
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

# Show listening ports
ports() {
    if [ "$1" = "-a" ]; then
        sudo lsof -i -P -n
    else
        sudo lsof -i -P -n | grep LISTEN
    fi
}

# Network device backup
backup_device() {
    local device=$1
    local backup_dir="$HOME/network-backups/$(date +%Y%m%d)"
    mkdir -p "$backup_dir"
    
    echo "Backing up $device..."
    ssh "${SSHUSER:-admin}@$device" "show running-config" > "$backup_dir/$device.cfg"
    echo "Backup saved to $backup_dir/$device.cfg"
}
EOF

echo -e "${GREEN}✓${NC} Created shell configuration files"

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
set clipboard=unnamed
EOF

# Add to .zshrc if not already there
if [[ -f "$HOME/.zshrc" ]]; then
    if ! grep -q "CNSQ NetOps Setup" "$HOME/.zshrc"; then
        cat >> "$HOME/.zshrc" << 'EOF'

# CNSQ NetOps Setup
for config in $HOME/.zsh/*.zsh; do
    [[ -f "$config" ]] && source "$config"
done

# Add Homebrew to PATH (Apple Silicon)
[[ -d "/opt/homebrew" ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Python virtual environment
export VIRTUAL_ENV_DISABLE_PROMPT=1
EOF
        echo -e "${GREEN}✓${NC} Updated ~/.zshrc"
    else
        echo -e "${GREEN}✓${NC} ~/.zshrc already configured"
    fi
else
    echo -e "${YELLOW}Creating new ~/.zshrc${NC}"
    cat > "$HOME/.zshrc" << 'EOF'
# CNSQ NetOps Setup
for config in $HOME/.zsh/*.zsh; do
    [[ -f "$config" ]] && source "$config"
done

# Add Homebrew to PATH (Apple Silicon)
[[ -d "/opt/homebrew" ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Python virtual environment
export VIRTUAL_ENV_DISABLE_PROMPT=1
EOF
fi

# Summary
echo -e "\n${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}                    Installation Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}\n"

# Verification
echo -e "${BLUE}Installed Tools:${NC}"
command -v git &>/dev/null && echo -e "  ${GREEN}✓${NC} Git" || echo -e "  ${RED}✗${NC} Git"
command -v nvim &>/dev/null && echo -e "  ${GREEN}✓${NC} Neovim" || echo -e "  ${RED}✗${NC} Neovim"
command -v tmux &>/dev/null && echo -e "  ${GREEN}✓${NC} tmux" || echo -e "  ${RED}✗${NC} tmux"
command -v python3 &>/dev/null && echo -e "  ${GREEN}✓${NC} Python 3" || echo -e "  ${RED}✗${NC} Python 3"
command -v node &>/dev/null && echo -e "  ${GREEN}✓${NC} Node.js" || echo -e "  ${RED}✗${NC} Node.js"
command -v nmap &>/dev/null && echo -e "  ${GREEN}✓${NC} nmap" || echo -e "  ${RED}✗${NC} nmap"
command -v dig &>/dev/null && echo -e "  ${GREEN}✓${NC} dig (DNS tools)" || echo -e "  ${RED}✗${NC} dig"
command -v eza &>/dev/null && echo -e "  ${GREEN}✓${NC} eza" || echo -e "  ${RED}✗${NC} eza"
[[ -d "$HOME/.cnsq-venv" ]] && echo -e "  ${GREEN}✓${NC} Python venv" || echo -e "  ${RED}✗${NC} Python venv"
"$HOME/.cnsq-venv/bin/ansible" --version &>/dev/null 2>&1 && echo -e "  ${GREEN}✓${NC} Ansible (in venv)" || echo -e "  ${RED}✗${NC} Ansible"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "1. Restart terminal or run: ${BLUE}source ~/.zshrc${NC}"
echo -e "2. Activate Python environment: ${BLUE}cnsq-env${NC}"
echo -e "3. Test Ansible: ${BLUE}cnsq-env && ansible --version${NC}"
echo -e "4. For network tools: ${BLUE}nmap --version${NC}"
echo ""
echo -e "${GREEN}Your NetOps environment is ready!${NC}"
echo -e "${YELLOW}Note: Some tools like mtr may need sudo permissions to run properly.${NC}"