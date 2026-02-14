#!/bin/bash

# Version 4.7 - Bug Fixes.

# --- ROOT ELEVATION ---
if [[ $EUID -ne 0 ]]; then
   echo -e "\e[1;31mJATT needs sudo for framebuffer access\e[0m"
   sudo "$0" "$@"
   exit $?
fi

# --- IDENTITY ---
AUTHOR="RedbeebreadsYT"
VERSION="4.7"
cursor=0
target_fb=0

# --- NMTUI COLOR PALETTE ---
BG_GRAY='\e[48;5;250m'
FG_BLACK='\e[38;5;16m'
FG_WHITE='\e[1;37m'
BOX_BG='\e[48;5;240m' 
BOX_MAIN='\e[44m'     
NC='\e[0m'

# --- MONITOR SCANNER ---
get_monitor_names() {
    local monitors=""
    for edid in /sys/class/drm/*/edid; do
        if [ -s "$edid" ]; then
            local name=$(strings "$edid" | grep -E '^[A-Z0-9 ]{3,12}$' | head -n 1 | xargs)
            local port=$(echo "$edid" | cut -d/ -f5 | sed 's/card0-//')
            if [ -n "$name" ]; then
                monitors+="$port: [$name]  "
            else
                monitors+="$port: [Generic]  "
            fi
        fi
    done
    echo "${monitors:-No Monitors Detected}"
}

MONITOR_LIST=$(get_monitor_names)

options=(
    "MONITOR: Change Target (Current: FB$target_fb)"
    "ROTATE: 0 (Standard)"
    "ROTATE: 90 (Clockwise)"
    "ROTATE: 180 (Inverted)"
    "ROTATE: 270 (Counter-CW)"
    "COLOR: RGBW Pixel Stress"
    "COLOR: Custom Hex Flash (No #)"
    "VIEW CHANGELOG"
    "EXIT JATT"
)

# --- UI ENGINE ---
draw_ui() {
    tput cup 0 0
    COLS=$(tput cols)
    LINES=$(tput lines)

    for ((i=0; i<LINES; i++)); do
        printf "${BG_GRAY}%${COLS}s${NC}" ""
    done

    tput cup 0 0
    echo -e "${FG_BLACK} CONNECTED: $MONITOR_LIST${NC}"

    options[0]="MONITOR: Change Target (Current: FB$target_fb)"

    BOX_W=52
    BOX_H=$((${#options[@]} + 5))
    START_C=$(( (COLS - BOX_W) / 2 ))
    START_R=$(( (LINES - BOX_H) / 2 ))

    local h_line
    printf -v h_line "%*s" "$((BOX_W - 2))" ""
    h_line="${h_line// /-}"

    for ((i=1; i<=BOX_H; i++)); do
        tput cup $((START_R + i)) $((START_C + 2))
        printf "${BOX_BG}%${BOX_W}s${NC}" ""
    done

    tput cup $START_R $START_C
    printf "${BOX_MAIN}${FG_WHITE}+${h_line}+${NC}"
    tput cup $((START_R + 1)) $START_C
    printf "${BOX_MAIN}${FG_WHITE}|  %-46s  |${NC}" "JATT - (Just A Testing Tool) - $VERSION"
    tput cup $((START_R + 2)) $START_C
    printf "${BOX_MAIN}${FG_WHITE}+${h_line}+${NC}"

    for i in "${!options[@]}"; do
        tput cup $((START_R + 3 + i)) $START_C
        if [ $i -eq $cursor ]; then
            printf "${BOX_MAIN}${FG_WHITE}| \e[48;5;208m\e[38;5;16m %-46s \e[0m${BOX_MAIN}${FG_WHITE} |${NC}" "${options[$i]}"
        else
            printf "${BOX_MAIN}${FG_WHITE}|    %-44s  |${NC}" "${options[$i]}"
        fi
    done

    tput cup $((START_R + BOX_H - 1)) $START_C
    printf "${BOX_MAIN}${FG_WHITE}+${h_line}+${NC}"
}

# --- ACTIONS ---
view_changelog() {
    tput clear
    echo -e "${FG_ORANGE}=== JATT SYSTEM CHANGELOG ===${NC}\n"
    echo -e "${FG_WHITE}v4.7${NC} - Updated The Version Title So It Would Now Just Say Version Number And Wont Clip Anything."
	echo -e "${FG_WHITE}v4.6${NC} - Updated The Title JATT - (Just A Testing Tool)."
    echo -e "${FG_WHITE}v4.5${NC} - Added Changelog Viewer & UI cleanup and bug fixes."
    echo -e "${FG_WHITE}v4.2${NC} - Enhanced DisplayScan & multi-monitor sysfs routing."
    echo -e "${FG_WHITE}v4.0${NC} - Initial Multi-Monitor support (Targeting FB0-FB2)."
    echo -e "${FG_WHITE}v3.2${NC} - Fixed box alignment and bottom-line breakage."
    echo -e "${FG_WHITE}v3.0${NC} - Introduced NMTUI-style centered dialog & shadows."
    echo -e "${FG_WHITE}v2.0${NC} - Implemented Alternate Screen Buffer (smcup) for TUI feel."
    echo -e "${FG_WHITE}v1.0${NC} - Basic rotation and color stress logic."
    echo -e "\n${FG_RED}Press any key to return...${NC}"
    read -n 1 -s
    tput clear
}

change_monitor() {
    tput cnorm; tput cup $((START_R + BOX_H + 1)) $START_C
    echo -e -n "${FG_BLACK}Enter FB ID (0, 1, 2): ${NC}"
    read -r new_fb
    [[ "$new_fb" =~ ^[0-9]+$ ]] && target_fb=$new_fb
    tput civis
}

apply_rotation() {
    local target_path="/sys/class/graphics/fb$target_fb/rotate"
    [ ! -f "$target_path" ] && target_path="/sys/class/graphics/fbcon/rotate"
    echo "$1" > "$target_path" 2>/dev/null
    tput clear
    echo -e "\n\e[1;34m [ ACTION ]\e[0m FB$target_fb set to $1"
    read -n 1 -s -p " Press any key to return..."
}

# --- STARTUP ---
tput smcup; tput civis; tput clear
cleanup() { tput cnorm; tput rmcup; exit; }
trap cleanup EXIT

while true; do
    draw_ui
    read -rsn1 key
    case "$key" in
        $'\x1b')
            read -rsn2 -t 0.01 key
            [[ "$key" == "[A" ]] && ((cursor--))
            [[ "$key" == "[B" ]] && ((cursor++))
            ;;
        "") 
            case $cursor in
                0) change_monitor ;;
                1|2|3|4) apply_rotation $((cursor - 1)) ;;
                5) for c in "41" "42" "44" "107"; do echo -e "\e[${c}m"; tput clear; sleep 0.5; done ;;
                6) tput cnorm; tput cup $((START_R + BOX_H + 1)) $START_C; 
                   echo -n "HEX: "; read -r HX; tput civis
                   if [[ $HX =~ ^[0-9a-fA-F]{6}$ ]]; then
                       R=$(printf "%d" "0x${HX:0:2}"); G=$(printf "%d" "0x${HX:2:2}"); B=$(printf "%d" "0x${HX:4:2}")
                       echo -e "\e[48;2;${R};${G};${B}m"; tput clear; sleep 1
                   fi ;;
                7) view_changelog ;;
                8) exit 0 ;;
            esac
            ;;
        [Qq]) exit 0 ;;
    esac

    [[ $cursor -lt 0 ]] && cursor=$((${#options[@]} - 1))
    [[ $cursor -ge ${#options[@]} ]] && cursor=0
done