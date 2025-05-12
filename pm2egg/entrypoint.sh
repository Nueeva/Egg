#!/bin/bash

# Set colors
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
PURPLE='\033[0;35m'
ORANGE='\033[0;33m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Banner function with animated text
print_animated_text() {
    local text=$1
    local color=$2
    for (( i=0; i<${#text}; i++ )); do
        echo -ne "${color}${text:$i:1}${NC}"
        sleep 0.01
    done
    echo
}

# Generate ASCII art banner
generate_banner() {
    echo -e "${BLUE}"
    echo -e " _   _ "
    echo -e "| \ | |                     "
    echo -e "|  \| |_   _  _____   ____ _"
    echo -e "| . \` | | | |/ _ \ \ / / _\`"
    echo -e "| |\  | |_| |  __/\ V / (_| |"
    echo -e "\_| \_/\__,_|\___| \_/ \__,_|"
    echo -e "${NC}"
}

# Banner Nueva
clear
generate_banner
print_animated_text "=============================================" "${RED}"
print_animated_text "           Welcome to Nueva             " "${MAGENTA}"
print_animated_text "=============================================" "${RED}"
sleep 0.5

# Animated loading
echo -ne "${CYAN}Initializing system components${NC}"
for i in {1..5}; do
    echo -ne "${YELLOW}.${NC}"
    sleep 0.3
done
echo -e "\n"

# System information
OS=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d '"' -f 2)
IP=$(hostname -I | awk '{print $1}')
CPU=$(grep -m1 'model name' /proc/cpuinfo | awk -F': ' '{print $2}')
CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
RAM_TOTAL=$(awk '/MemTotal/ {printf "%.2f GB", $2/1024/1024}' /proc/meminfo)
RAM_FREE=$(awk '/MemFree/ {printf "%.2f GB", $2/1024/1024}' /proc/meminfo)
DISK_TOTAL=$(df -h / | awk '/\/$/ {print $2}')
DISK_FREE=$(df -h / | awk '/\/$/ {print $4}')
TIMEZONE=$(cat /etc/timezone 2>/dev/null || timedatectl | grep "Time zone" | awk '{print $3}')
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Get Node.js versions
NODE_CURRENT=$(node -v)
NPM_VERSION=$(npm -v)
PM2_VERSION=$(pm2 -v 2>/dev/null || echo "Not installed")

# Display system info with progress bar
display_progress_bar() {
    local width=50
    for ((i=0; i<=width; i++)); do
        sleep 0.02
        percent=$((i * 100 / width))
        filled=$((i * width / width))
        remaining=$((width - filled))
        progress=$(printf "%${filled}s" | tr ' ' '█')
        spaces=$(printf "%${remaining}s")
        echo -ne "\r${BLUE}[${GREEN}${progress}${spaces}${BLUE}] ${percent}%${NC}"
    done
    echo -e "\n"
}

echo -e "${GREEN}Analyzing system capabilities...${NC}"
display_progress_bar

# Display system information with animated sections
print_info() {
    local label=$1
    local value=$2
    local color1=$3
    local color2=$4
    echo -e "${color1}${label}: ${color2}${value}${NC}"
    sleep 0.1
}

echo -e "\n${WHITE}╔════════════ SYSTEM INFORMATION ════════════╗${NC}"
print_info "  OS" "$OS" "${BLUE}" "${CYAN}"
print_info "  IP Address" "$IP" "${YELLOW}" "${CYAN}"
print_info "  CPU" "$CPU" "${MAGENTA}" "${CYAN}"
print_info "  CPU Cores" "$CPU_CORES" "${ORANGE}" "${CYAN}"
print_info "  RAM (Total)" "$RAM_TOTAL" "${GREEN}" "${CYAN}"
print_info "  RAM (Free)" "$RAM_FREE" "${GREEN}" "${CYAN}"
print_info "  SSD (Total)" "$DISK_TOTAL" "${YELLOW}" "${CYAN}"
print_info "  SSD (Free)" "$DISK_FREE" "${YELLOW}" "${CYAN}"
print_info "  Timezone" "$TIMEZONE" "${PURPLE}" "${CYAN}"
print_info "  Date" "$DATE" "${CYAN}" "${WHITE}"
echo -e "${WHITE}╚═════════════════════════════════════════════╝${NC}"

echo -e "\n${WHITE}╔════════════ RUNTIME ENVIRONMENT ════════════╗${NC}"
print_info "  Node.js" "$NODE_CURRENT" "${GREEN}" "${CYAN}"
print_info "  NPM" "$NPM_VERSION" "${GREEN}" "${CYAN}"
print_info "  PM2" "$PM2_VERSION" "${GREEN}" "${CYAN}"
echo -e "${WHITE}╚═════════════════════════════════════════════╝${NC}"
sleep 0.5

# Banner closing
print_animated_text "=============================================" "${RED}"
sleep 0.5

# Change to container directory
cd /home/container

# Make internal Docker IP address available to processes
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Set Node.js version if specified
if [ ! -z "$NODE_VERSION" ]; then
    echo -e "${YELLOW}Switching to Node.js version: ${CYAN}$NODE_VERSION${NC}"
    if command -v nvm &> /dev/null; then
        source $NVM_DIR/nvm.sh
        nvm use $NODE_VERSION || nvm install $NODE_VERSION
        echo -e "${GREEN}Active Node.js version: ${NC}$(node -v)"
    else
        echo -e "${RED}NVM not installed. Using default Node.js version.${NC}"
    fi
fi

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e "\n${CYAN}Startup Command:${NC}"
echo -e "${YELLOW}:/home/container$ ${WHITE}${MODIFIED_STARTUP}${NC}"

# Run the server
echo -e "\n${GREEN}Launching server...${NC}"
print_animated_text "=============================================" "${RED}"
sleep 0.5

# Execute the startup command
eval ${MODIFIED_STARTUP}

# Run default container command
exec "$@"