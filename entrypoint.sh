#!/bin/bash
B1='\033[1;34m'    
B2='\033[1;94m'   
P1='\033[1;35m'   
P2='\033[1;95m'    
RESET='\033[0m'   

CLOUD_NAME=${CLOUD_NAME:-"Nueva - Inc"}

get_info() {
    result=$(eval "$1" 2>/dev/null) || result="Unknown"
    echo "$result"
}

clear

echo -e "${B1}  ┌─────────────────┐      ${P1}╔═══════════════════╗${RESET}"
echo -e "${B1}  │  ${P2}● ${B1}${P1}● ${B1}${B2}●        ${B1}│      ${P1}  ║  ${P2}$CLOUD_NAME${P1}      ║${RESET}"
echo -e "${B1}  ├─────────────────┤      ${P1}╚═══════════════════╝${RESET}"
echo -e "${B2}  │ ${P2}▀▀▀▀▀▀▀▀▀▀▀▀▀ ${B2}│      ${B1}-------------------------${RESET}"
echo -e "${B2}  │ ${P2}▀▀▀▀▀▀▀▀▀▀▀▀▀ ${B2}│      ${B2}HOST:${RESET} $(get_info hostname)"
echo -e "${B2}  ├─────────────────┤    ${P1}OS:${RESET}   $(get_info "cat /etc/os-release | grep PRETTY_NAME | cut -d '\"' -f2")"
echo -e "${P2}  │ ${B1}▓▓▓▓▓▓▓▓▓▓▓▓▓ ${P2}│      ${B2}CPU:${RESET}  $(get_info "grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^[ \t]*//' | cut -c-40")"
echo -e "${P2}  │ ${B1}▓▓▓▓▓▓▓▓▓▓▓▓▓ ${P2}│      ${P1}MEM:${RESET}  $(get_info "free -h | grep Mem | awk '{print \$3\"/\"\$2}'")"
echo -e "${P2}  ├─────────────────┤    ${B1}DISK:${RESET} $(get_info "df -h / | awk 'NR==2 {print \$3\"/\"\$2, \"(\"\$5\")\"}'")"
echo -e "${P1}  │ ${B2}░░░░░░░░░░░░░ ${P1}│      ${P2}IP:${RESET}   $(get_info "hostname -I | awk '{print \$1}'")"
echo -e "${P1}  │ ${B2}░░░░░░░░░░░░░ ${P1}│      ${B2}TIME:${RESET} $(get_info date)"
echo -e "${P1}  ├─────────────────┤    ${P2}UP:${RESET}   $(get_info "uptime -p | sed 's/up //'")"
echo -e "${B1}  │  ${P1}▄ ${B1}${B2}▄ ${B1}${P2}▄        ${B1}│      ${RESET}"
echo -e "${B1}  └─────────────────┘      ${RESET}"
echo -e "${B1}▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄${P1}▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄${RESET}"
echo

exec "$@"