# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

print_header() {
    echo
    echo "──────────────────────────────────────"
    echo " $1"
    echo "──────────────────────────────────────"
}
print_status() {

    if [[ "$1" == "OK" ]]; then
        echo -e "${GREEN}✓ OK${RESET}"
    else
        echo -e "${RED}✗ FAIL${RESET}"
    fi
}
calculate_score() {

    # Seguridad Wi-Fi
    case "$SECURITY" in
        *WEP*|*WEP*)
            SCORE=$((SCORE - 50))
            ;;

        ""|"--"|"Unknown")
            SCORE=$((SCORE - 50))
            ;;

        *WPA1*)
            SCORE=$((SCORE - 35))
            ;;

        *WPA2*)
            SCORE=$((SCORE - 10))
            ;;

        *WPA3*)
            SCORE=$((SCORE + 0))
            ;;

    esac

    # Red abierta
    if [[ "$SECURITY" == "--" || -z "$SECURITY" ]]; then
        SCORE=$((SCORE - 20))
    fi

    # PMF
    if [[ "$PMF" == "Disabled" ]]; then
        SCORE=$((SCORE - 10))
    elif [[ "$PMF" == "Required" ]]; then
        SCORE=$((SCORE + 5))
    fi

    # Señal
    if [[ "$SIGNAL_STATUS" == "Poor" ]]; then
        SCORE=$((SCORE - 20))
    elif [[ "$SIGNAL_STATUS" == "Fair" ]]; then
        SCORE=$((SCORE - 10))
    fi

    # Conectividad
    if [[ "$GATEWAY_STATUS" == "FAIL" ]]; then
        SCORE=$((SCORE - 20))
    fi

    if [[ "$INTERNET_STATUS" == "FAIL" ]]; then
        SCORE=$((SCORE - 10))
    fi

    # Límites
    if (( SCORE > 100 )); then
        SCORE=100
    fi
    if (( SCORE < 0 )); then
        SCORE=0
    fi
}
print_report() {

    clear

    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║          WIFI AUDITOR v0.1           ║"
    echo "╚══════════════════════════════════════╝"

    print_header "WIFI INFORMATION"

    echo "SSID       : ${SSID:-N/A}"
    echo "BSSID      : ${BSSID:-N/A}"
    echo "Interface  : $INTERFACE"
    echo "Band       : ${BAND:-N/A}"
    echo "Frequency  : ${FREQUENCY:-N/A} MHz"
    echo "Channel    : ${CHANNEL:-N/A}"
    echo "Signal     : ${SIGNAL_DBM:-N/A} ${SIGNAL_UNIT:-dBm}"
    echo "Signal     : ${SIGNAL_STATUS:-N/A}"
    echo "TX bitrate : ${BITRATE:-N/A}"

    echo -e "${RESET}"

    print_header "NETWORK & CONNECTIVITY"

    echo "IP         : ${IP_ADDRESS:-N/A}"
    echo "Gateway    : ${GATEWAY:-N/A}"
    echo "DNS        : ${DNS:-N/A}"
    echo -n "Gateway    : "
    print_status "$GATEWAY_STATUS"

    echo -n "Internet   : "
    print_status "$INTERNET_STATUS"

    print_header "SECURITY AUDIT"

    echo "Score      : ${SCORE}/100"

    if (( SCORE >= 80 )); then
        echo -e "Status     : ${GREEN}GOOD${RESET}"
    elif (( SCORE >= 60 )); then
        echo -e "Status     : ${YELLOW}WARNING${RESET}"
    else
        echo -e "Status     : ${RED}CRITICAL${RESET}"
    fi
    echo "Encryption : ${SECURITY:-Unknown}"
    echo "PMF        : ${PMF:-Unknown}"
    printf "\nSecurity Score: ${SCORE}/100"

    printf "\n\nObservations:\n"
    #Poner opciones de mejora
    

    printf "\nAudit completed.\n"
}