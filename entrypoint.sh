#!/bin/bash

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
    bar=$(printf '%-'$BAR_SIZE's' $(printf '%0.s█' $(seq 1 $filled)))
    echo -ne "\r[${GREEN}${bar// /.}${NC}] ${WHITE}${progress}%${NC}"
    sleep 0.03
done
echo -e "\n"

# System information collection
OS=$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
IP=$(hostname -I | awk '{print $1}')
CPU=$(grep -m1 'model name' /proc/cpuinfo | awk -F': ' '{print $2}')
CORES=$(grep -c processor /proc/cpuinfo)
RAM=$(awk '/MemTotal/ {printf "%.2f GB", $2/1024/1024}' /proc/meminfo)
DISK=$(df -h / | awk '/\/$/ {print $2}')
USED_DISK=$(df -h / | awk '/\/$/ {print $3}')
FREE_DISK=$(df -h / | awk '/\/$/ {print $4}')
TIMEZONE=$(cat /etc/timezone 2>/dev/null || echo "Not available")
DATE=$(date '+%Y-%m-%d %H:%M:%S')
NODE_VERSION=$(node -v)
NPM_VERSION=$(npm -v)
UPTIME=$(uptime -p)

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

# Script to run the server
cd /home/container

# Make internal Docker IP address available to processes
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Display additional environment information
echo -e "\n${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${WHITE}                 ENVIRONMENT DETAILS                   ${GREEN}║${NC}"
echo -e "${GREEN}╠════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║${NC} ${CYAN}Node.js Version${NC}: $(node -v)"
echo -e "${GREEN}║${NC} ${CYAN}NPM Version${NC}: $(npm -v)"
echo -e "${GREEN}║${NC} ${CYAN}PM2 Version${NC}: $(pm2 -v)"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
sleep 1

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e "\n${CYAN}▶ Modified Startup Command:${NC}"
echo -e "${YELLOW}:/home/container$ ${WHITE}${MODIFIED_STARTUP}${NC}"

# Check if the JS_FILE exists
if [ ! -z "$JS_FILE" ] && [ ! -f "$JS_FILE" ]; then
    echo -e "${RED}Warning: $JS_FILE does not exist in the current directory!${NC}"
    echo -e "${YELLOW}Available JavaScript files:${NC}"
    find . -maxdepth 1 -name "*.js" | sort | while read file; do
        echo -e "${CYAN}- ${file:2}${NC}"
    done
    echo ""
fi

# Start the server with visual feedback
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
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

# Run the modified startup command
echo -e "${YELLOW}Server is now starting...${NC}\n"
eval ${MODIFIED_STARTUP}

# Run any additional commands passed to the script
exec "$@"