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
    case "$SECURITY" in
        "WEP")
            SCORE=$((SCORE - 50))
            NOTESSECURITY="- 50"
            OBSERVATIONSSECURITY="Change Encryption protocol to WPA3."
            ;;

        ""|"--"|"Unknown")
            SCORE=$((SCORE - 50))
            ;;

        *WPA1*)
            SCORE=$((SCORE - 35))
            NOTESSECURITY="- 35"
            OBSERVATIONSSECURITY="Change Encryption protocol to WPA3."
            ;;

        *"WPA1 WPA2"*)
            SCORE=$((SCORE - 35))
            NOTESSECURITY="- 35"
            OBSERVATIONSSECURITY="Change Encryption protocol to WPA3."
            ;;

        *WPA2*)
            SCORE=$((SCORE - 10))
            NOTESSECURITY="- 10"
            OBSERVATIONSSECURITY="Change Encryption protocol to WPA2."
            ;;

        *WPA3*)
            SCORE=$((SCORE + 0))
            ;;

    esac

    # Red abierta
    if [[ "$SECURITY" == "--" || -z "$SECURITY" ]]; then
        SCORE=$((SCORE - 100))
    fi

    # Señal
    if [[ "$SIGNAL_STATUS" == "Poor" ]]; then
        SCORE=$((SCORE - 20))
    elif [[ "$SIGNAL_STATUS" == "Fair" ]]; then
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
    echo "║          WIFI AUDITOR v0.2           ║"
    echo "╚══════════════════════════════════════╝"

    print_header "WIFI INFORMATION"

    echo "SSID         : ${SSID:-N/A}"
    echo "BSSID        : ${BSSID:-N/A}"
    echo "Interface    : $INTERFACE"
    echo "Band         : ${BAND:-N/A}"
    echo "Frequency    : ${FREQUENCY:-N/A} MHz"
    echo "Channel      : ${CHANNEL:-N/A}"
    echo "Signal       : ${SIGNAL_DBM:-N/A} ${SIGNAL_UNIT:-dBm}"
    echo "Signal       : ${SIGNAL_STATUS:-N/A}"
    echo "TX bitrate   : ${BITRATE:-N/A}"

    echo -en "${RESET}"

    print_header "NETWORK & CONNECTIVITY"

    echo "Local IP     : ${IP_ADDRESS:-N/A}"
    echo "Gateway      : ${GATEWAY:-N/A} - $GATEWAY_STATUS"
    echo "DNS          : ${DNS:-N/A}"
    echo "Internet     : $INTERNET_STATUS"

    print_header "SECURITY AUDIT"

    if (( SCORE >= 80 )); then
        echo -e "Status       : ${GREEN}GOOD${RESET}"
    elif (( SCORE >= 60 )); then
        echo -e "Status       : ${YELLOW}WARNING${RESET}"
    else
        echo -e "Status       : ${RED}CRITICAL${RESET}"
    fi
    echo -e "Encryption   : ${SECURITY:-Unknown} ${RED} ${NOTESSECURITY} ${RESET}"
    echo -e "PMF          : ${PMF:-Unknown} ${RED} ${PMFNOTES} ${RESET}"

    if [[ ${PASSWORD} == "" ]]; then

        echo "Status       : Unable to analyze"
        return
    fi
    echo "Password     : $PASSWORD"
    case "$PASSWORD_STRENGTH" in
        *"Very weak"|"Weak"*)
            echo -e "Strength     : ${RED}$PASSWORD_STRENGTH $NOTESSTRENGTH${RESET}"
            ;;

        *"Normal"*)
            echo -e "Strength     : ${YELLOW}$PASSWORD_STRENGTH$ ${RED}$NOTESSTRENGTH${RESET}"
            ;;

        "Stong"|"Very strong"*)
            echo -e "Strength     : ${GREEN}$PASSWORD_STRENGTH$ ${RED}$NOTESSTRENGTH${RESET}"
            ;;
    esac

    echo "Entropy      : $PASSWORD_ENTROPY bits"

    case "$PASSWORD_BREACHED" in

        YES)
            echo -e "Breach status: ${RED}FOUND $NOTESBREACHED${RESET}"
            ;;

        NO)
            echo -e "Breach status: ${GREEN}Not found${RESET}"
            ;;

        *)
            echo -e "Breach status: ${YELLOW}Unknown${RESET}"
            ;;
    esac

    printf "\nSecurity Score: ${SCORE}/100"

    printf "\n\nObservations:"
    #Poner opciones de mejora
    echo -e "${RED}"
    echo "${OBSERVATIONSBREACHED}"
    echo "${OBSERVATIONSSTRENGTH}"
    echo "${OBSERVATIONSPMF}"
    echo "${OBSERVATIONSSECURITY}"
    echo -e "${RESET}"
}