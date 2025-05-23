#!/bin/bash

# Exit on any error
set -e

# Set colors for better readability
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
ORANGE='\033[0;33m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Load NVM properly
export NVM_DIR="/home/container/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Banner for Nueva Panel
clear
echo -e "${RED}"
echo -e "╔═══════════════════════════════════╗"
echo -e "║    ${MAGENTA}Welcome to Nueva Developer${NC}${RED}    ║"
echo -e "╚═══════════════════════════════════╝"
echo -e "${NC}"
sleep 1

# Loading animation
echo -e "${CYAN}Loading system information...${NC}"
sleep 0.5

# Fancy loading bar
BAR_SIZE=30
for ((i=0; i<=$BAR_SIZE; i++)); do
    progress=$((i * 100 / BAR_SIZE))
    filled=$((i * BAR_SIZE / BAR_SIZE))
    bar=$(printf "%-${BAR_SIZE}s" $(printf "%0.s█" $(seq 1 $filled)))
    echo -ne "\r[${GREEN}${bar// /.}${NC}] ${WHITE}${progress}%${NC}"
    sleep 0.03
done
echo -e "\n"

# System information collection with error handling
OS=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo "Ubuntu 22.04")
IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "Not available")
CPU=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | awk -F': ' '{print $2}' || echo "Not available")
CORES=$(grep -c processor /proc/cpuinfo 2>/dev/null || echo "Not available")
RAM=$(awk '/MemTotal/ {printf "%.2f GB", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo "Not available")
DISK=$(df -h / 2>/dev/null | awk '/\/$/ {print $2}' || echo "Not available")
USED_DISK=$(df -h / 2>/dev/null | awk '/\/$/ {print $3}' || echo "Not available")
FREE_DISK=$(df -h / 2>/dev/null | awk '/\/$/ {print $4}' || echo "Not available")
TIMEZONE=$(cat /etc/timezone 2>/dev/null || echo "UTC")
DATE=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "Not available")
UPTIME=$(uptime -p 2>/dev/null || echo "Not available")

# Get Node.js and NPM versions with error handling
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node -v)
else
    NODE_VERSION="Not installed"
fi

if command -v npm >/dev/null 2>&1; then
    NPM_VERSION=$(npm -v)
else
    NPM_VERSION="Not installed"
fi

# Function to print system info with fancy formatting
print_system_info() {
    local label="$1"
    local value="$2"
    local color="$3"
    
    printf "${color}%-12s${NC}: ${CYAN}%s${NC}\n" "$label" "$value"
}

# Display system information in a fancy table
echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║${WHITE}                    SYSTEM INFORMATION                  ${YELLOW}║${NC}"
echo -e "${YELLOW}╠════════════════════════════════════════════════════════╣${NC}"
print_system_info "OS" "$OS" "${BLUE}"
print_system_info "IP Address" "$IP" "${YELLOW}"
print_system_info "CPU" "$CPU" "${MAGENTA}"
print_system_info "CPU Cores" "$CORES" "${GREEN}"
print_system_info "RAM" "$RAM" "${RED}"
print_system_info "Disk Total" "$DISK" "${ORANGE}"
print_system_info "Disk Used" "$USED_DISK" "${PURPLE}"
print_system_info "Disk Free" "$FREE_DISK" "${GREEN}"
print_system_info "Timezone" "$TIMEZONE" "${MAGENTA}"
print_system_info "Date" "$DATE" "${CYAN}"
print_system_info "Node.js" "$NODE_VERSION" "${GREEN}"
print_system_info "NPM" "$NPM_VERSION" "${BLUE}"
print_system_info "Uptime" "$UPTIME" "${YELLOW}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
sleep 1

# Change to working directory
cd /home/container

# Make internal Docker IP address available to processes
INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}' || echo "127.0.0.1")
export INTERNAL_IP

# Check and setup Node.js version if specified
if [ -n "${NODE_VERSION}" ] && [ "${NODE_VERSION}" != "Not installed" ]; then
    echo -e "\n${CYAN}Setting up Node.js version: ${NODE_VERSION}${NC}"
    if command -v nvm >/dev/null 2>&1; then
        nvm use "${NODE_VERSION}" 2>/dev/null || {
            echo -e "${YELLOW}Warning: Node.js version ${NODE_VERSION} not found. Using default version.${NC}"
            nvm use default 2>/dev/null || echo -e "${RED}Error: Could not set Node.js version${NC}"
        }
    else
        echo -e "${YELLOW}Warning: NVM not available, using system Node.js${NC}"
    fi
fi

# Get updated versions after potential version switch
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node -v)
    NPM_VERSION=$(npm -v 2>/dev/null || echo "Not available")
    PM2_VERSION=$(pm2 -v 2>/dev/null || echo "Not available")
else
    echo -e "${RED}Error: Node.js is not available!${NC}"
    exit 1
fi

# Display environment information
echo -e "\n${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${WHITE}                 ENVIRONMENT DETAILS                   ${GREEN}║${NC}"
echo -e "${GREEN}╠════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║${NC} ${CYAN}Node.js Version${NC}: ${NODE_VERSION}"
echo -e "${GREEN}║${NC} ${CYAN}NPM Version${NC}: ${NPM_VERSION}"
echo -e "${GREEN}║${NC} ${CYAN}PM2 Version${NC}: ${PM2_VERSION}"
echo -e "${GREEN}║${NC} ${CYAN}Working Directory${NC}: $(pwd)"
echo -e "${GREEN}║${NC} ${CYAN}Internal IP${NC}: ${INTERNAL_IP}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
sleep 1

# Validate startup command exists
if [ -z "${STARTUP}" ]; then
    echo -e "${RED}Error: STARTUP command is not defined!${NC}"
    exit 1
fi

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e "\n${CYAN}▶ Modified Startup Command:${NC}"
echo -e "${YELLOW}:/home/container$ ${WHITE}${MODIFIED_STARTUP}${NC}"

# Check if the JS_FILE exists and provide helpful information
if [ ! -z "$JS_FILE" ]; then
    if [ ! -f "$JS_FILE" ]; then
        echo -e "\n${RED}Warning: $JS_FILE does not exist in the current directory!${NC}"
        echo -e "${YELLOW}Available JavaScript files:${NC}"
        if ls *.js >/dev/null 2>&1; then
            find . -maxdepth 1 -name "*.js" | sort | while read file; do
                echo -e "${CYAN}- ${file:2}${NC}"
            done
        else
            echo -e "${CYAN}No JavaScript files found in current directory.${NC}"
        fi
        echo -e "${YELLOW}Available files:${NC}"
        ls -la | head -10
        echo ""
    else
        echo -e "\n${GREEN}✓ Main file found: ${JS_FILE}${NC}"
    fi
fi

# Check if package.json exists
if [ -f "package.json" ]; then
    echo -e "${GREEN}✓ package.json found${NC}"
    # Show package.json main script if available
    MAIN_SCRIPT=$(grep -o '"main"[[:space:]]*:[[:space:]]*"[^"]*"' package.json 2>/dev/null | cut -d'"' -f4)
    if [ ! -z "$MAIN_SCRIPT" ]; then
        echo -e "${CYAN}Package.json main script: ${MAIN_SCRIPT}${NC}"
    fi
else
    echo -e "${YELLOW}Note: No package.json found${NC}"
fi

# Start the server with visual feedback
echo -e "\n${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${WHITE}             STARTING SERVER PROCESS                  ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"

# Add a brief loader animation
for i in {1..5}; do
    echo -ne "${YELLOW}Starting${NC}"
    for j in {1..3}; do
        echo -ne "${YELLOW}.${NC}"
        sleep 0.2
    done
    echo -ne "\r\033[K"
    sleep 0.2
done

# Ensure PM2 is available
if ! command -v pm2 >/dev/null 2>&1; then
    echo -e "${RED}Error: PM2 is not available!${NC}"
    echo -e "${YELLOW}Installing PM2...${NC}"
    npm install -g pm2@latest || {
        echo -e "${RED}Failed to install PM2!${NC}"
        exit 1
    }
fi

# Run the modified startup command with error handling
echo -e "${YELLOW}Server is now starting...${NC}\n"

# Execute the startup command
eval "${MODIFIED_STARTUP}" || {
    echo -e "\n${RED}Error: Startup command failed!${NC}"
    echo -e "${YELLOW}Command that failed: ${MODIFIED_STARTUP}${NC}"
    exit 1
}