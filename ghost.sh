#!/bin/bash
set -euo pipefail

# ghost - WiFi monitor mode setup tool
# https://github.com/44ghost44/ghost

# ─── Globals ────────────────────────────────────────────────────────────────────

VERSION="2.0.0"
INTERFACE=""
CHANNEL=""
ORIGINAL_MODE=""
ORIGINAL_CHANNEL=""

# ─── Logo ───────────────────────────────────────────────────────────────────────

show_logo() {
    cat << 'LOGO'

   ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗
  ██╔════╝ ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝
  ██║  ███╗███████║██║   ██║███████╗   ██║
  ██║   ██║██╔══██║██║   ██║╚════██║   ██║
  ╚██████╔╝██║  ██║╚██████╔╝███████║   ██║
   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝
                        WiFi Monitor Mode Tool

LOGO
}

# ─── Usage ──────────────────────────────────────────────────────────────────────

usage() {
    echo "Usage: ghost.sh [OPTIONS] [CHANNEL]"
    echo ""
    echo "Put a WiFi interface into monitor mode on a given channel."
    echo ""
    echo "Options:"
    echo "  -i IFACE    Use this interface (skip auto-detection)"
    echo "  -c CHANNEL  Set channel (1-196, default: 6)"
    echo "  -l          List available WiFi interfaces and exit"
    echo "  -h          Show this help and exit"
    echo "  -v          Show version and exit"
    echo ""
    echo "Examples:"
    echo "  sudo ./ghost.sh              # channel 6, auto-detect interface"
    echo "  sudo ./ghost.sh 11           # channel 11, auto-detect interface"
    echo "  sudo ./ghost.sh -i wlan0 -c 1"
    echo ""
    echo "Requires root. Must be run with sudo or as root."
}

# ─── Helpers ────────────────────────────────────────────────────────────────────

info()  { echo "[+] $1"; }
ok()    { echo "[ok] $1"; }
warn()  { echo "[!] $1"; }
fail()  { echo "[x] $1" >&2; exit 1; }

# ─── Root check ─────────────────────────────────────────────────────────────────

check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        fail "This script must be run as root. Use: sudo ./ghost.sh"
    fi
}

# ─── Interface detection ────────────────────────────────────────────────────────

detect_interfaces() {
    local ifaces=()

    # Primary: iw dev
    if command -v iw &>/dev/null; then
        mapfile -t ifaces < <(iw dev | awk '$1=="Interface"{print $2}')
    fi

    # Fallback: iwconfig (grep wireless interfaces)
    if [[ "${#ifaces[@]}" -eq 0 ]] && command -v iwconfig &>/dev/null; then
        mapfile -t ifaces < <(iwconfig 2>/dev/null | awk '/IEEE 802.11/{print $1}')
    fi

    if [[ "${#ifaces[@]}" -eq 0 ]]; then
        fail "No WiFi interfaces detected. Connect an adapter and retry."
    fi

    echo "${ifaces[@]}"
}

select_interface() {
    local ifaces=()
    mapfile -t ifaces < <(detect_interfaces | tr ' ' '\n')

    if [[ "${#ifaces[@]}" -eq 1 ]]; then
        INTERFACE="${ifaces[0]}"
        info "Using detected interface: ${INTERFACE}"
    else
        info "Multiple WiFi interfaces found:"
        select INTERFACE in "${ifaces[@]}"; do
            [[ -n "${INTERFACE}" ]] && break
            echo "Invalid selection."
        done
    fi
}

# ─── Chipset info ───────────────────────────────────────────────────────────────

show_chipset() {
    local phy driver=""

    # Get phy name for this interface
    phy="$(iw dev "${INTERFACE}" info 2>/dev/null | awk '$1=="wiphy"{print "phy"$2}')" || true

    # Try /sys uevent for driver info
    if [[ -f "/sys/class/net/${INTERFACE}/device/uevent" ]]; then
        driver="$(grep '^DRIVER=' "/sys/class/net/${INTERFACE}/device/uevent" 2>/dev/null | cut -d= -f2)" || true
    fi

    if [[ -n "${phy}" || -n "${driver}" ]]; then
        info "Chipset info: phy=${phy:-unknown}, driver=${driver:-unknown}"
    fi
}

# ─── Channel validation ────────────────────────────────────────────────────────

validate_channel() {
    if [[ ! "${CHANNEL}" =~ ^[0-9]+$ ]]; then
        fail "Channel must be a number, got: ${CHANNEL}"
    fi
    if [[ "${CHANNEL}" -lt 1 || "${CHANNEL}" -gt 196 ]]; then
        fail "Channel out of range (1-196), got: ${CHANNEL}"
    fi
}

# ─── Save original state ───────────────────────────────────────────────────────

save_original_state() {
    ORIGINAL_MODE="$(iwconfig "${INTERFACE}" 2>/dev/null | grep -oP 'Mode:\K\S+' || echo "unknown")"
    ORIGINAL_CHANNEL="$(iw dev "${INTERFACE}" info 2>/dev/null | awk '/channel/{print $2}' || echo "unknown")"
}

# ─── Trap handler: restore on exit ─────────────────────────────────────────────

cleanup() {
    local exit_code=$?
    if [[ -n "${INTERFACE}" && -n "${ORIGINAL_MODE}" && "${ORIGINAL_MODE}" != "unknown" ]]; then
        echo ""
        warn "Caught signal, restoring interface..."
        ip link set "${INTERFACE}" down 2>/dev/null || true
        iwconfig "${INTERFACE}" mode managed 2>/dev/null || true
        ip link set "${INTERFACE}" up 2>/dev/null || true
        ok "Restored ${INTERFACE} to managed mode."
    fi
    exit "$exit_code"
}

# ─── Channel verification ──────────────────────────────────────────────────────

verify_channel() {
    local actual
    actual="$(iw dev "${INTERFACE}" info 2>/dev/null | awk '/channel/{print $2}')" || true
    if [[ "${actual}" == "${CHANNEL}" ]]; then
        ok "Channel verified: ${actual}"
    else
        warn "Channel mismatch: requested ${CHANNEL}, got ${actual:-unknown}. Check adapter support."
    fi
}

# ─── Print restore instructions ────────────────────────────────────────────────

print_restore() {
    echo ""
    info "To restore your interface to normal mode, run:"
    echo "    sudo ip link set ${INTERFACE} down"
    echo "    sudo iwconfig ${INTERFACE} mode managed"
    if [[ "${ORIGINAL_CHANNEL}" != "unknown" && -n "${ORIGINAL_CHANNEL}" ]]; then
        echo "    sudo iwconfig ${INTERFACE} channel ${ORIGINAL_CHANNEL}"
    fi
    echo "    sudo ip link set ${INTERFACE} up"
}

# ─── Main ───────────────────────────────────────────────────────────────────────

main() {
    local list_mode=false
    local opt_interface=""

    CHANNEL="6"  # default

    # Parse flags
    while getopts ":i:c:lhv" opt; do
        case "${opt}" in
            i) opt_interface="${OPTARG}" ;;
            c) CHANNEL="${OPTARG}" ;;
            l) list_mode=true ;;
            h) usage; exit 0 ;;
            v) echo "ghost ${VERSION}"; exit 0 ;;
            :) fail "Option -${OPTARG} requires an argument." ;;
            *) fail "Unknown option: -${OPTARG}. Use -h for help." ;;
        esac
    done
    shift $((OPTIND - 1))

    # Positional channel arg (overrides -c if both given)
    if [[ $# -ge 1 ]]; then
        CHANNEL="$1"
    fi

    show_logo

    # List mode
    if [[ "${list_mode}" == true ]]; then
        check_root
        info "Available WiFi interfaces:"
        detect_interfaces | tr ' ' '\n' | while read -r iface; do
            echo "    ${iface}"
        done
        exit 0
    fi

    check_root
    validate_channel

    # Select interface
    if [[ -n "${opt_interface}" ]]; then
        INTERFACE="${opt_interface}"
        info "Using specified interface: ${INTERFACE}"
    else
        select_interface
    fi

    # Show chipset
    show_chipset

    # Save state for restore
    save_original_state

    # Install trap after we know the interface
    trap cleanup SIGINT SIGTERM

    # Kill conflicting processes
    info "Killing conflicting processes..."
    airmon-ng check kill 2>/dev/null || true

    # Bring interface down
    info "Bringing interface down..."
    ip link set "${INTERFACE}" down

    # Set monitor mode
    info "Setting monitor mode..."
    iwconfig "${INTERFACE}" mode monitor 2>/dev/null

    local mode
    mode="$(iwconfig "${INTERFACE}" 2>/dev/null | grep "Mode:Monitor" || true)"
    if [[ -z "${mode}" ]]; then
        ip link set "${INTERFACE}" up 2>/dev/null || true
        fail "Could not set ${INTERFACE} to monitor mode. Does your adapter support it?"
    fi

    # Set channel
    info "Setting channel ${CHANNEL}..."
    iwconfig "${INTERFACE}" channel "${CHANNEL}"

    # Bring interface up
    info "Bringing interface up..."
    ip link set "${INTERFACE}" up

    sleep 1

    # Verify
    mode="$(iwconfig "${INTERFACE}" 2>/dev/null | grep "Mode:Monitor" || true)"
    if [[ -n "${mode}" ]]; then
        ok "${INTERFACE} is in monitor mode on channel ${CHANNEL}"
        verify_channel
    else
        fail "Something went wrong. Check manually with: iwconfig ${INTERFACE}"
    fi

    print_restore
}

main "$@"
