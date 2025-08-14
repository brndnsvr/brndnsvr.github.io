#!/bin/bash

#############################################################################
# CNSQ NetOps Mac Setup Script
# Version: 1.0.0
# Purpose: Automated setup for NetOps team member macOS workstations
# Author: CNSQ NetOps Team
# Date: 2025
#############################################################################

set -euo pipefail  # Exit on error, undefined variables, pipe failures

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Global variables
SCRIPT_VERSION="1.0.0"
LOG_FILE="$HOME/cnsq-setup.log"
BACKUP_DIR="$HOME/.cnsq-backup-$(date +%Y%m%d-%H%M%S)"
REQUIRED_DISK_SPACE_GB=5
TIMEOUT_SECONDS=60

# Architecture detection
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
else
    HOMEBREW_PREFIX="/usr/local"
fi

#############################################################################
# Logging Functions
#############################################################################

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Display to user based on level
    case "$level" in
        ERROR)
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        SUCCESS)
            echo -e "${GREEN}[✓]${NC} $message"
            ;;
        WARNING)
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        INFO)
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        STEP)
            echo -e "\n${CYAN}==>${NC} ${BOLD}$message${NC}"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

#############################################################################
# Helper Functions
#############################################################################

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_internet() {
    log INFO "Checking internet connectivity..."
    if ping -c 1 8.8.8.8 &> /dev/null; then
        log SUCCESS "Internet connection available"
        return 0
    else
        log ERROR "No internet connection detected"
        return 1
    fi
}

check_disk_space() {
    log INFO "Checking available disk space..."
    local available_gb=$(df -g / | awk 'NR==2 {print $4}')
    
    if [[ $available_gb -lt $REQUIRED_DISK_SPACE_GB ]]; then
        log ERROR "Insufficient disk space. Required: ${REQUIRED_DISK_SPACE_GB}GB, Available: ${available_gb}GB"
        return 1
    fi
    
    log SUCCESS "Sufficient disk space available (${available_gb}GB)"
    return 0
}

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        mkdir -p "$BACKUP_DIR"
        local backup_path="$BACKUP_DIR/$(basename "$file").backup"
        cp "$file" "$backup_path"
        log INFO "Backed up $file to $backup_path"
    fi
}

secure_read_password() {
    local prompt="$1"
    local var_name="$2"
    local password
    
    echo -n "$prompt"
    read -s password
    echo  # New line after password input
    
    eval "$var_name='$password'"
}

prompt_with_timeout() {
    local prompt="$1"
    local default="$2"
    local timeout="${3:-$TIMEOUT_SECONDS}"
    local response=""
    
    echo -e "${prompt} (${timeout}s timeout, default: ${default})"
    
    if read -t "$timeout" response; then
        echo "${response:-$default}"
    else
        echo -e "\n${YELLOW}Timeout reached, using default: ${default}${NC}"
        echo "$default"
    fi
}

#############################################################################
# Introduction and Confirmation
#############################################################################

show_introduction() {
    clear
    cat << EOF
${CYAN}========================================
CNSQ NetOps Mac Setup Script v${SCRIPT_VERSION}
========================================${NC}

This script will configure your Mac for NetOps team development.

${YELLOW}INSTALLATION MODES:${NC}
- ${GREEN}Required tools${NC}: Will be installed automatically
- ${BLUE}Optional tools${NC}: You'll be prompted for each (${TIMEOUT_SECONDS}s timeout = skip)

${YELLOW}If you walk away, you'll get all required tools and NO optional tools.${NC}

The script will:
1. Install Homebrew (if needed)
2. Install required packages and tools
3. Configure shell environment
4. Setup Python and Ansible
5. Prompt for optional tools (${TIMEOUT_SECONDS}s timeout each)

${RED}IMPORTANT:${NC} This script will modify your system configuration.
Backups will be created in: ${BACKUP_DIR}

EOF

    echo -n "${BOLD}Do you want to proceed? (y/n):${NC} "
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log INFO "Installation cancelled by user"
        exit 0
    fi
    
    log STEP "Starting CNSQ NetOps Mac Setup..."
    echo "Logging to: $LOG_FILE"
    echo
}

#############################################################################
# Prerequisite Checks
#############################################################################

check_prerequisites() {
    log STEP "Checking prerequisites..."
    
    # Check macOS version
    local macos_version=$(sw_vers -productVersion)
    log INFO "macOS version: $macos_version"
    
    # Check architecture
    log INFO "Architecture: $ARCH"
    
    # Check internet
    check_internet || exit 1
    
    # Check disk space
    check_disk_space || exit 1
    
    # Check and install Xcode Command Line Tools
    if ! xcode-select -p &> /dev/null; then
        log WARNING "Xcode Command Line Tools not found. Installing..."
        xcode-select --install
        
        echo "${YELLOW}Please complete the Xcode Command Line Tools installation in the popup window.${NC}"
        echo "Press Enter when installation is complete..."
        read -r
        
        if ! xcode-select -p &> /dev/null; then
            log ERROR "Xcode Command Line Tools installation failed or was cancelled"
            exit 1
        fi
    fi
    log SUCCESS "Xcode Command Line Tools installed"
    
    log SUCCESS "All prerequisites met"
}

#############################################################################
# Homebrew Installation
#############################################################################

install_homebrew() {
    log STEP "Setting up Homebrew..."
    
    if ! command_exists brew; then
        log INFO "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for this session
        eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
    else
        log SUCCESS "Homebrew already installed"
    fi
    
    log INFO "Updating Homebrew..."
    brew update
    
    log SUCCESS "Homebrew ready"
}

#############################################################################
# Required Package Installation
#############################################################################

install_required_packages() {
    log STEP "Installing required packages..."
    
    # Define required packages
    local cli_packages=(
        "git"
        "neovim"
        "tmux"
        "eza"
        "powerlevel10k"
        "tree"
        "ripgrep"
        "jq"
        "bc"
        "curl"
        "telnet"
        "sipcalc"
        "netcat"
        "bind"
        "openssh"
        "sshpass"
        "ansible"
        "expect"
        "python@3"
    )
    
    local cask_packages=(
        "iterm2"
    )
    
    # Install CLI packages
    for package in "${cli_packages[@]}"; do
        if brew list "$package" &>/dev/null; then
            log INFO "$package already installed"
        else
            log INFO "Installing $package..."
            brew install "$package" || log WARNING "Failed to install $package"
        fi
    done
    
    # Install GUI applications
    for cask in "${cask_packages[@]}"; do
        if brew list --cask "$cask" &>/dev/null; then
            log INFO "$cask already installed"
        else
            log INFO "Installing $cask..."
            brew install --cask "$cask" || log WARNING "Failed to install $cask"
        fi
    done
    
    log SUCCESS "Required packages installed"
}

#############################################################################
# Python Setup
#############################################################################

setup_python() {
    log STEP "Setting up Python environment..."
    
    # Ensure pip is upgraded
    log INFO "Upgrading pip..."
    python3 -m pip install --upgrade pip
    
    # Required Python packages
    local python_packages=(
        "paramiko"
        "cryptography"
        "bcrypt"
        "pycparser"
        "cffi"
        "pyyaml"
        "jinja2"
        "requests"
    )
    
    log INFO "Installing required Python packages..."
    for package in "${python_packages[@]}"; do
        python3 -m pip install "$package" || log WARNING "Failed to install $package"
    done
    
    log SUCCESS "Python environment configured"
}

#############################################################################
# Ansible Setup
#############################################################################

setup_ansible() {
    log STEP "Setting up Ansible..."
    
    # Create Ansible directories
    mkdir -p "$HOME/.ansible/roles"
    mkdir -p "$HOME/.ansible/collections"
    mkdir -p "$HOME/.ansible/plugins/modules"
    
    # Required Ansible collections
    local required_collections=(
        "ansible.netcommon"
        "ansible.utils"
        "ansible.posix"
        "cisco.ios"
        "cisco.iosxr"
        "junipernetworks.junos"
    )
    
    log INFO "Installing required Ansible collections..."
    for collection in "${required_collections[@]}"; do
        ansible-galaxy collection install "$collection" --force || log WARNING "Failed to install $collection"
    done
    
    log SUCCESS "Ansible configured"
}

#############################################################################
# Shell Configuration
#############################################################################

setup_shell_config() {
    log STEP "Configuring shell environment..."
    
    # Create .zsh directory
    mkdir -p "$HOME/.zsh"
    
    # Backup existing .zshrc
    backup_file "$HOME/.zshrc"
    
    # Create/update .zshrc
    cat > "$HOME/.zshrc.cnsq" << 'EOF'
# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Initialize Homebrew environment
EOF
    
    echo "eval \"\$($HOMEBREW_PREFIX/bin/brew shellenv)\"" >> "$HOME/.zshrc.cnsq"
    
    cat >> "$HOME/.zshrc.cnsq" << 'EOF'

# History settings
export HISTSIZE=10000
export SAVEHIST=20000
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
export HISTFILE=~/.zsh_history

# Source custom configurations from ~/.zsh directory
if [ -d "$HOME/.zsh" ]; then
  for config_file in "$HOME/.zsh/"*.zsh; do
    [[ -f "$config_file" ]] && source "$config_file"
  done
fi

# Source SSH agent info if available
if [ -f /tmp/.ssh-agent-info ]; then
  source /tmp/.ssh-agent-info
fi

# Update PATH
export PATH="$HOME/bin:$PATH"
export PATH="$PATH:$HOME/.local/bin"

# iTerm2 integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Powerlevel10k theme
source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF
    
    # Create aliases file
    cat > "$HOME/.zsh/aliases.zsh" << 'EOF'
# ~/.zsh/aliases.zsh

# Modern replacements
alias ll='eza -lh --git --group-directories-first -s extension --icons'
alias ls='eza'
alias vi='nvim'

# Navigation shortcuts
alias gohome='cd ~'

# Git shortcuts
alias gs='git status'
alias gp='git pull'
alias gc='git commit'
EOF
    
    # Create functions file
    cat > "$HOME/.zsh/functions.zsh" << 'EOF'
# ~/.zsh/functions.zsh

# Initialize SSH Agent
init_ssh_agent() {
  if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
  fi
  
  local unlock_script="$HOME/unlock_key.sh"
  if [ ! -f "$unlock_script" ]; then
    echo "Warning: unlock_key.sh script not found at $unlock_script"
    return 1
  fi
  
  if ! ssh-add -l | grep -q "$(ssh-keygen -lf "$SSHKEYPATH" 2>/dev/null | awk '{print $2}')" ; then
    "$unlock_script"
  else
    echo "SSH key is already added to the agent."
  fi
}

# Weather Function
weather() {
  case $1 in
    nyc)     curl "wttr.in/New+York+NY?u" ;;
    dallas)  curl "wttr.in/Dallas+TX?u" ;;
    la)      curl "wttr.in/Los+Angeles+CA?u" ;;
    chicago) curl "wttr.in/Chicago+IL?u" ;;
    *)       echo "Usage: weather {nyc|dallas|la|chicago}" ;;
  esac
}
EOF
    
    # Create env.zsh placeholder (will be populated later)
    touch "$HOME/.zsh/env.zsh"
    chmod 600 "$HOME/.zsh/env.zsh"
    
    # Merge with existing .zshrc if it exists
    if [[ -f "$HOME/.zshrc" ]]; then
        # Check if our config is already sourced
        if ! grep -q "CNSQ NetOps Setup" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# CNSQ NetOps Setup" >> "$HOME/.zshrc"
            echo "source $HOME/.zshrc.cnsq" >> "$HOME/.zshrc"
        fi
    else
        mv "$HOME/.zshrc.cnsq" "$HOME/.zshrc"
    fi
    
    log SUCCESS "Shell configuration complete"
}

#############################################################################
# Neovim Configuration
#############################################################################

setup_neovim() {
    log STEP "Configuring Neovim..."
    
    mkdir -p "$HOME/.config/nvim"
    
    cat > "$HOME/.config/nvim/init.vim" << 'EOF'
" ~/.config/nvim/init.vim
" Disable nvim clipboard hijacking - use system clipboard normally
set clipboard=
" Make nvim behave like traditional vi for clipboard
set mouse=
EOF
    
    log SUCCESS "Neovim configured"
}

#############################################################################
# iTerm2 Configuration
#############################################################################

setup_iterm2() {
    log STEP "Configuring iTerm2..."
    
    # Download iTerm2 shell integration
    curl -L https://iterm2.com/shell_integration/zsh -o "$HOME/.iterm2_shell_integration.zsh" 2>/dev/null
    
    # Set iTerm2 as default terminal (requires user action)
    log INFO "To set iTerm2 as default terminal:"
    log INFO "  1. Open iTerm2"
    log INFO "  2. Go to iTerm2 > Make iTerm2 Default Term"
    
    log SUCCESS "iTerm2 configuration complete"
}

#############################################################################
# SSH Configuration
#############################################################################

setup_ssh() {
    log STEP "Setting up SSH configuration..."
    
    # Create SSH directories with proper permissions
    mkdir -p "$HOME/.ssh/keys"
    chmod 700 "$HOME/.ssh"
    chmod 1700 "$HOME/.ssh/keys"  # Sticky bit for inheritance
    
    # Get SSH key prefix preference
    echo -e "\n${CYAN}==> SSH Key Naming Configuration${NC}"
    echo "Enter prefix for SSH keys (default: 'ssh'):"
    echo "Example: 'ssh' will create ~/.ssh/keys/ssh-username"
    echo -n "Prefix (or press Enter for 'ssh'): "
    read -r ssh_prefix
    ssh_prefix="${ssh_prefix:-ssh}"
    
    # Generate SSH key path based on username
    local username_clean="${USER//./}"  # Remove dots from username
    local ssh_key_path="$HOME/.ssh/keys/${ssh_prefix}-${username_clean}"
    
    log SUCCESS "SSH directory structure created"
    log INFO "SSH key will be: $ssh_key_path"
    
    # Store for later use
    echo "export SSH_KEY_PREFIX=\"$ssh_prefix\"" >> "$HOME/.zsh/env.zsh"
    echo "export SSHKEYPATH=\"$ssh_key_path\"" >> "$HOME/.zsh/env.zsh"
}

#############################################################################
# Environment Variables Setup
#############################################################################

setup_environment_variables() {
    log STEP "Setting up environment variables..."
    
    local env_file="$HOME/.zsh/env.zsh"
    
    # Ensure file has secure permissions
    touch "$env_file"
    chmod 600 "$env_file"
    
    echo "# Environment Variables - CNSQ NetOps" > "$env_file"
    echo "# Generated: $(date)" >> "$env_file"
    echo "" >> "$env_file"
    
    # Required SSH credentials
    echo -e "\n${CYAN}==> SSH Credentials Setup${NC}"
    echo -n "Enter SSH username: "
    read -r ssh_user
    secure_read_password "Enter SSH password: " ssh_pass
    
    echo "export SSHUSER=\"$ssh_user\"" >> "$env_file"
    echo "export SSHPASS=\"$ssh_pass\"" >> "$env_file"
    
    # Ansible credentials
    echo -e "\n${CYAN}==> Ansible Credentials Setup${NC}"
    echo -n "Use SSH credentials for Ansible? (y/n): "
    read -r use_ssh_for_ansible
    
    if [[ "$use_ssh_for_ansible" =~ ^[Yy]$ ]]; then
        echo "export ANSIBLE_USERNAME=\"$ssh_user\"" >> "$env_file"
        echo "export ANSIBLE_PASSWORD=\"$ssh_pass\"" >> "$env_file"
    else
        echo -n "Enter Ansible username: "
        read -r ansible_user
        secure_read_password "Enter Ansible password: " ansible_pass
        echo "export ANSIBLE_USERNAME=\"$ansible_user\"" >> "$env_file"
        echo "export ANSIBLE_PASSWORD=\"$ansible_pass\"" >> "$env_file"
    fi
    
    # Ansible vault password
    echo -e "\n${CYAN}==> Ansible Vault Setup${NC}"
    secure_read_password "Enter Ansible vault password: " vault_pass
    
    echo "$vault_pass" > "$HOME/.avpf"
    chmod 600 "$HOME/.avpf"
    echo "export ANSIBLE_VAULT_PASSWORD_FILE=\"$HOME/.avpf\"" >> "$env_file"
    
    # SSH key path (already added in setup_ssh, just noting here for reference)
    # SSHKEYPATH already exported in setup_ssh function
    
    # Optional custom variables
    echo -e "\n${CYAN}==> Optional Environment Variables${NC}"
    echo "Would you like to set up additional environment variables?"
    echo "Suggestions: NETCONF_USER/PASS, ADTEST01_USER/PASS, LAB_USER/PASS"
    echo -n "Add optional variables? (y/n): "
    read -r add_optional
    
    if [[ "$add_optional" =~ ^[Yy]$ ]]; then
        while true; do
            echo -n "Enter variable name (or 'done' to finish): "
            read -r var_name
            
            [[ "$var_name" == "done" ]] && break
            
            if [[ "$var_name" =~ (PASS|PASSWORD|SECRET|KEY)$ ]]; then
                secure_read_password "Enter value for $var_name: " var_value
            else
                echo -n "Enter value for $var_name: "
                read -r var_value
            fi
            
            echo "export $var_name=\"$var_value\"" >> "$env_file"
        done
    fi
    
    # Clear sensitive variables from memory
    unset ssh_pass ansible_pass vault_pass var_value
    
    log SUCCESS "Environment variables configured"
}

#############################################################################
# Optional Tools Installation
#############################################################################

install_optional_tools() {
    log STEP "Optional tools installation..."
    
    echo -e "\n${YELLOW}You will be prompted for each optional tool.${NC}"
    echo -e "${YELLOW}Each prompt has a ${TIMEOUT_SECONDS} second timeout (default: skip).${NC}\n"
    
    # Optional CLI tools
    local optional_cli=(
        "lazygit:Git UI"
        "gh:GitHub CLI"
        "htop:Process viewer"
        "watch:File watcher"
        "fswatch:File system watcher"
        "python@3.12:Python 3.12"
        "node:Node.js"
        "yq:YAML processor"
        "unzip:Archive tool"
        "p7zip:7-Zip"
        "ssh-audit:SSH auditing"
        "nmap:Network scanner"
        "mtr:Network diagnostic"
        "wget:HTTP downloader"
    )
    
    for tool_desc in "${optional_cli[@]}"; do
        IFS=':' read -r tool description <<< "$tool_desc"
        response=$(prompt_with_timeout "Install $tool ($description)? (y/n)" "n")
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            log INFO "Installing $tool..."
            brew install "$tool" || log WARNING "Failed to install $tool"
        else
            log INFO "Skipping $tool"
        fi
    done
    
    # Optional GUI applications
    local optional_casks=(
        "visual-studio-code:Code editor"
        "sublime-text:Text editor"
        "coteditor:Plain text editor"
        "boop:Scriptable scratchpad"
        "warp:Modern terminal"
        "orbstack:Container management"
        "cyberduck:File transfer"
        "wireshark:Network analyzer"
        "keeper-password-manager:Password manager"
        "macdown:Markdown editor"
        "appcleaner:App uninstaller"
    )
    
    for cask_desc in "${optional_casks[@]}"; do
        IFS=':' read -r cask description <<< "$cask_desc"
        response=$(prompt_with_timeout "Install $cask ($description)? (y/n)" "n")
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            log INFO "Installing $cask..."
            brew install --cask "$cask" || log WARNING "Failed to install $cask"
        else
            log INFO "Skipping $cask"
        fi
    done
    
    # Optional Python packages
    echo -e "\n${CYAN}==> Optional Python Packages${NC}"
    local optional_python=(
        "netmiko:Network device connections"
        "napalm:Network automation"
        "pandas:Data analysis"
        "openpyxl:Excel handling"
        "textfsm:Text parsing"
    )
    
    for pkg_desc in "${optional_python[@]}"; do
        IFS=':' read -r package description <<< "$pkg_desc"
        response=$(prompt_with_timeout "Install Python package $package ($description)? (y/n)" "n")
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            log INFO "Installing $package..."
            python3 -m pip install "$package" || log WARNING "Failed to install $package"
        else
            log INFO "Skipping $package"
        fi
    done
    
    # Optional Ansible collections
    echo -e "\n${CYAN}==> Optional Ansible Collections${NC}"
    local optional_ansible=(
        "arista.eos:Arista switches"
        "cisco.nxos:Cisco Nexus"
        "cisco.asa:Cisco ASA"
        "cisco.dnac:Cisco DNA Center"
        "cisco.ise:Cisco ISE"
        "cisco.meraki:Meraki"
        "amazon.aws:AWS"
        "azure.azcollection:Azure"
        "community.aws:Community AWS"
        "ansible.windows:Windows"
    )
    
    for collection_desc in "${optional_ansible[@]}"; do
        IFS=':' read -r collection description <<< "$collection_desc"
        response=$(prompt_with_timeout "Install Ansible collection $collection ($description)? (y/n)" "n")
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            log INFO "Installing $collection..."
            ansible-galaxy collection install "$collection" --force || log WARNING "Failed to install $collection"
        else
            log INFO "Skipping $collection"
        fi
    done
    
    log SUCCESS "Optional tools installation complete"
}

#############################################################################
# Post-Installation Setup
#############################################################################

post_installation() {
    log STEP "Post-installation setup..."
    
    # Git configuration
    echo -e "\n${CYAN}==> Git Configuration${NC}"
    echo -n "Configure Git? (y/n): "
    read -r configure_git
    
    if [[ "$configure_git" =~ ^[Yy]$ ]]; then
        echo -n "Enter your name for Git commits: "
        read -r git_name
        echo -n "Enter your email for Git commits: "
        read -r git_email
        
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        log SUCCESS "Git configured"
    fi
    
    # SSH key generation
    echo -e "\n${CYAN}==> SSH Key Generation${NC}"
    
    # Get the SSH key path from environment
    source "$HOME/.zsh/env.zsh" 2>/dev/null
    local ssh_key_path="${SSHKEYPATH}"
    
    if [[ -z "$ssh_key_path" ]]; then
        # Fallback if env not loaded
        local username_clean="${USER//./}"
        ssh_key_path="$HOME/.ssh/keys/ssh-${username_clean}"
    fi
    
    if [[ ! -f "$ssh_key_path" ]]; then
        echo -n "Generate SSH key? (y/n): "
        read -r generate_key
        
        if [[ "$generate_key" =~ ^[Yy]$ ]]; then
            echo "Generating SSH key (Ed25519)..."
            echo "You will be prompted for a passphrase (required)."
            ssh-keygen -t ed25519 -f "$ssh_key_path" -C "${USER}@centersquaredc.com"
            chmod 600 "$ssh_key_path"
            chmod 644 "${ssh_key_path}.pub"
            log SUCCESS "SSH key generated at $ssh_key_path"
        fi
    else
        log INFO "SSH key already exists at $ssh_key_path"
    fi
    
    log SUCCESS "Post-installation complete"
}

#############################################################################
# Verification and Testing
#############################################################################

verify_installation() {
    log STEP "Verifying installation..."
    
    local failed_checks=0
    
    # Check required commands
    local required_commands=(
        "brew" "git" "nvim" "tmux" "eza" "tree" "rg" "jq" "bc"
        "curl" "telnet" "nc" "dig" "ssh" "sshpass" "ansible" "expect"
        "python3" "pip3"
    )
    
    for cmd in "${required_commands[@]}"; do
        if command_exists "$cmd"; then
            log SUCCESS "$cmd is available"
        else
            log ERROR "$cmd is not available"
            ((failed_checks++))
        fi
    done
    
    # Test Python imports
    log INFO "Testing Python packages..."
    python3 -c "import paramiko, cryptography, bcrypt, pyyaml, jinja2, requests" 2>/dev/null
    if [[ $? -eq 0 ]]; then
        log SUCCESS "Python packages imported successfully"
    else
        log ERROR "Some Python packages failed to import"
        ((failed_checks++))
    fi
    
    # Test Ansible
    log INFO "Testing Ansible..."
    if ansible --version &>/dev/null; then
        log SUCCESS "Ansible is functional"
    else
        log ERROR "Ansible test failed"
        ((failed_checks++))
    fi
    
    # Connectivity test
    log INFO "Testing network connectivity..."
    if ping -c 1 8.8.8.8 &>/dev/null; then
        log SUCCESS "Network connectivity verified"
    else
        log WARNING "Network connectivity test failed"
    fi
    
    if [[ $failed_checks -eq 0 ]]; then
        log SUCCESS "All verification checks passed!"
    else
        log WARNING "$failed_checks verification checks failed"
    fi
}

#############################################################################
# Installation Summary
#############################################################################

show_summary() {
    log STEP "Installation Summary"
    
    cat << EOF

${GREEN}========================================
Installation Complete!
========================================${NC}

${CYAN}Log file:${NC} $LOG_FILE
${CYAN}Backup directory:${NC} $BACKUP_DIR

${YELLOW}Next Steps:${NC}
1. Restart your terminal or run: source ~/.zshrc
2. Open iTerm2 and set as default terminal
3. Run 'p10k configure' to customize your prompt
4. Review ~/.zsh/env.zsh for your environment variables

${YELLOW}Important Files:${NC}
- Shell config: ~/.zshrc, ~/.zsh/
- Environment vars: ~/.zsh/env.zsh (mode 600)
- Ansible vault: ~/.avpf (mode 600)
- SSH keys: ~/.ssh/keys/

${GREEN}Your NetOps environment is ready!${NC}

EOF
}

#############################################################################
# Main Execution
#############################################################################

main() {
    # Initialize log
    echo "CNSQ NetOps Mac Setup - Started at $(date)" > "$LOG_FILE"
    
    # Show introduction and get confirmation
    show_introduction
    
    # Run installation steps
    check_prerequisites
    install_homebrew
    install_required_packages
    setup_python
    setup_ansible
    setup_shell_config
    setup_neovim
    setup_iterm2
    setup_ssh
    setup_environment_variables
    
    # Optional installations
    install_optional_tools
    
    # Post-installation
    post_installation
    
    # Verification
    verify_installation
    
    # Show summary
    show_summary
    
    log INFO "Installation completed at $(date)"
}

# Run main function
main "$@"

