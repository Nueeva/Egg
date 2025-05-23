#!/bin/bash

# Exit on any error
set -e

# Color definitions untuk output yang indah
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function untuk print colored text
print_color() {
    local color=$1
    local text=$2
    echo -e "${color}${text}${NC}"
}

# Function untuk membuat loading animation
loading_animation() {
    local text="$1"
    local duration=${2:-3}
    
    echo -ne "${CYAN}${text}${NC}"
    for ((i=0; i<duration; i++)); do
        for dot in "." ".." "..."; do
            echo -ne "\r${CYAN}${text}${dot}${NC}"
            sleep 0.3
        done
    done
    echo -e "\r${GREEN}${text}... Done!${NC}"
}

# Load NVM environment
export NVM_DIR="/home/container/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Clear screen dan show banner
clear
print_color $RED "╔═══════════════════════════════════════╗"
print_color $RED "║    ${MAGENTA}Nueva Developer Panel v2.0${NC}${RED}     ║"
print_color $RED "║         ${WHITE}Starting Your Server${NC}${RED}         ║"
print_color $RED "║     ${CYAN}github.com/nueeva/egg:main${NC}${RED}     ║"
print_color $RED "╚═══════════════════════════════════════╝"
echo ""

# Loading system information
loading_animation "Loading system information" 2

# Collect system information dengan error handling
get_system_info() {
    OS=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo "Ubuntu 22.04")
    IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1")
    CPU=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | awk -F': ' '{print $2}' | cut -c1-30 || echo "Unknown CPU")
    CORES=$(nproc 2>/dev/null || echo "Unknown")
    RAM=$(awk '/MemTotal/ {printf "%.1f GB", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo "Unknown")
    DISK_TOTAL=$(df -h / 2>/dev/null | awk '/\/$/ {print $2}' || echo "Unknown")
    DISK_USED=$(df -h / 2>/dev/null | awk '/\/$/ {print $3}' || echo "Unknown")
    UPTIME=$(uptime -p 2>/dev/null || echo "Unknown")
    
    # Get Node.js version
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION_CURRENT=$(node -v)
        NPM_VERSION=$(npm -v)
    else
        NODE_VERSION_CURRENT="Not available"
        NPM_VERSION="Not available"
    fi
    
    # Get PM2 version
    if command -v pm2 >/dev/null 2>&1; then
        PM2_VERSION=$(pm2 -v)
    else
        PM2_VERSION="Not available"
    fi
}

get_system_info

# Display system information
print_color $YELLOW "╔══════════════════════════════════════════════════╗"
print_color $YELLOW "║${WHITE}                SYSTEM OVERVIEW                  ${YELLOW}║"
print_color $YELLOW "╠══════════════════════════════════════════════════╣"
printf "${BLUE}%-12s${NC}: ${CYAN}%s${NC}\n" "OS" "$OS"
printf "${BLUE}%-12s${NC}: ${CYAN}%s${NC}\n" "IP Address" "$IP"
printf "${BLUE}%-12s${NC}: ${CYAN}%s${NC}\n" "CPU" "$CPU"
printf "${BLUE}%-12s${NC}: ${CYAN}%s cores${NC}\n" "CPU Cores" "$CORES"
printf "${BLUE}%-12s${NC}: ${CYAN}%s${NC}\n" "Memory" "$RAM"
printf "${BLUE}%-12s${NC}: ${CYAN}%s${NC}\n" "Disk Total" "$DISK_TOTAL"
printf "${BLUE}%-12s${NC}: ${CYAN}%s${NC}\n" "Disk Used" "$DISK_USED"
printf "${BLUE}%-12s${NC}: ${CYAN}%s${NC}\n" "Uptime" "$UPTIME"
printf "${BLUE}%-12s${NC}: ${GREEN}%s${NC}\n" "Node.js" "$NODE_VERSION_CURRENT"
printf "${BLUE}%-12s${NC}: ${GREEN}%s${NC}\n" "NPM" "$NPM_VERSION"
printf "${BLUE}%-12s${NC}: ${GREEN}%s${NC}\n" "PM2" "$PM2_VERSION"
printf "${BLUE}%-12s${NC}: ${MAGENTA}%s${NC}\n" "Repository" "nueeva/egg:main"
print_color $YELLOW "╚══════════════════════════════════════════════════╝"
echo ""

# Change ke working directory
cd /home/container

# Set up internal IP untuk Docker
INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}' || echo "127.0.0.1")
export INTERNAL_IP

# Handle Node.js version switching
if [ -n "${NODE_VERSION}" ] && [ "${NODE_VERSION}" != "Not available" ]; then
    print_color $CYAN "Setting up Node.js environment..."
    
    if command -v nvm >/dev/null 2>&1; then
        if nvm use "${NODE_VERSION}" 2>/dev/null; then
            print_color $GREEN "✓ Successfully switched to Node.js ${NODE_VERSION}"
        else
            print_color $YELLOW "⚠ Could not switch to Node.js ${NODE_VERSION}, using default"
            nvm use default 2>/dev/null || true
        fi
    else
        print_color $YELLOW "⚠ NVM not available, using system Node.js"
    fi
    
    # Update versions setelah potential switch
    if command -v node >/dev/null 2>&1; then
        CURRENT_NODE=$(node -v)
        print_color $GREEN "Current Node.js version: ${CURRENT_NODE}"
    fi
fi

# Handle auto-update dari Git
if [ "${AUTO_UPDATE}" == "1" ] && [ -d .git ]; then
    print_color $CYAN "Auto-update enabled. Checking for updates..."
    if git pull 2>/dev/null; then
        print_color $GREEN "✓ Repository updated successfully"
    else
        print_color $YELLOW "⚠ Could not update repository"
    fi
fi

# Install additional packages jika specified
if [ -n "${NODE_PACKAGES}" ]; then
    print_color $CYAN "Installing additional packages: ${NODE_PACKAGES}"
    if npm install ${NODE_PACKAGES}; then
        print_color $GREEN "✓ Additional packages installed"
    else
        print_color $YELLOW "⚠ Some packages may have failed to install"
    fi
fi

# Install dependencies dari package.json
if [ -f "package.json" ]; then
    print_color $CYAN "Installing dependencies from package.json..."
    if npm install; then
        print_color $GREEN "✓ Dependencies installed successfully"
    else
        print_color $YELLOW "⚠ Some dependencies may have failed to install"
    fi
else
    print_color $YELLOW "ℹ No package.json found"
fi

# Validate startup command
if [ -z "${STARTUP_CMD}" ]; then
    print_color $RED "✗ Error: No startup command specified!"
    print_color $YELLOW "Please set the STARTUP_CMD environment variable"
    exit 1
fi

# Replace variables dalam startup command
MODIFIED_STARTUP=$(echo "${STARTUP_CMD}" | sed -e 's/{{/${/g' -e 's/}}/}/g')

# Display startup information
print_color $GREEN "╔══════════════════════════════════════════════════╗"
print_color $GREEN "║${WHITE}              STARTING APPLICATION               ${GREEN}║"
print_color $GREEN "╚══════════════════════════════════════════════════╝"
echo ""
print_color $CYAN "Working Directory: $(pwd)"
print_color $CYAN "Startup Command: ${WHITE}${MODIFIED_STARTUP}"
print_color $CYAN "Docker Image: ${WHITE}ghcr.io/nueeva/egg:main"
echo ""

# Check untuk main application file
if [[ "${MODIFIED_STARTUP}" =~ node[[:space:]]+([^[:space:]]+\.js) ]]; then
    MAIN_FILE="${BASH_REMATCH[1]}"
    if [ -f "${MAIN_FILE}" ]; then
        print_color $GREEN "✓ Main file found: ${MAIN_FILE}"
    else
        print_color $YELLOW "⚠ Warning: ${MAIN_FILE} not found"
        print_color $CYAN "Available JavaScript files:"
        find . -maxdepth 2 -name "*.js" | head -5 | while read file; do
            echo "  - ${file#./}"
        done
    fi
fi

# Ensure PM2 is available
if ! command -v pm2 >/dev/null 2>&1; then
    print_color $YELLOW "Installing PM2..."
    npm install -g pm2@latest
fi

# Final startup sequence
print_color $YELLOW "Starting application..."
sleep 1

# Execute startup command dengan proper error handling
eval "${MODIFIED_STARTUP}" || {
    print_color $RED "✗ Startup command failed!"
    print_color $YELLOW "Command: ${MODIFIED_STARTUP}"
    print_color $CYAN "Attempting alternative startup methods..."
    
    # Try alternative startup methods
    if [ -f "package.json" ]; then
        if npm start 2>/dev/null; then
            print_color $GREEN "✓ Started using npm start"
        elif [ -f "index.js" ]; then
            node index.js || exit 1
        elif [ -f "app.js" ]; then
            node app.js || exit 1
        else
            print_color $RED "✗ No suitable startup method found"
            exit 1
        fi
    else
        exit 1
    fi
}

print_color $GREEN "✓ Application started successfully!"
print_color $CYAN "Using Nueva Developer Panel from github.com/nueeva/egg:main"