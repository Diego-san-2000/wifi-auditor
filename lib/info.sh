detect_interface() {
    INTERFACE=$(iw dev 2>/dev/null |
        awk '$1=="Interface"{print $2}' |
        head -n 1)

    #Si no se está conectado a una red WiFi salimos del programa.
    if [[ -z "$INTERFACE" ]]; then
        echo -e "${RED}[!] No se ha encontrado ninguna interfaz Wi-Fi.${RESET}"
        exit 1
    fi
}
get_wifi_info() {
    WIFI_INFO=$(iw dev "$INTERFACE" link 2>/dev/null)

    SSID=$(echo "$WIFI_INFO" |
        awk -F': ' '/SSID:/{print $2}')

    BSSID=$(echo "$WIFI_INFO" |
        awk '/Connected to/{print $3}')

    SIGNAL_DBM=$(echo "$WIFI_INFO" |
        awk '/signal:/{print $2}')

    SIGNAL_UNIT=$(echo "$WIFI_INFO" |
        awk '/signal:/{print $3}')

    FREQUENCY=$(echo "$WIFI_INFO" |
        awk '/freq:/{print $2}')

    BITRATE=$(echo "$WIFI_INFO" |
        awk -F': ' '/tx bitrate:/{print $2}')

    CHANNEL=$(iw dev "$INTERFACE" info 2>/dev/null |
        awk '/channel/{print $2; exit}')
}

get_network_info() {
    IP_ADDRESS=$(ip -4 addr show "$INTERFACE" |
        awk '/inet /{print $2}' |
        head -n 1)

    GATEWAY=$(ip route |
        awk '/default/{print $3; exit}')

    DNS=$(resolvectl status "$INTERFACE" 2>/dev/null |
        awk '/DNS Servers:/{flag=1; next}
             flag && /^[[:space:]]+[0-9]/{
                 print $1;
                 exit
             }')

    if [[ -z "$DNS" ]]; then
        DNS=$(nmcli dev show "$INTERFACE" 2>/dev/null |
            awk '/IP4.DNS\[1\]/{print $2}')
    fi
}
detect_band() {
    if [[ -z "${FREQUENCY:-}" ]]; then
        BAND="Unknown"
    elif (( FREQUENCY >= 2400 && FREQUENCY < 2500 )); then
        BAND="2.4 GHz"
    elif (( FREQUENCY >= 4900 && FREQUENCY < 5900 )); then
        BAND="5 GHz"
    elif (( FREQUENCY >= 5900 && FREQUENCY < 7200 )); then
        BAND="6 GHz"
    else
        BAND="Unknown"
    fi
}

evaluate_signal() {
    if [[ -z "${SIGNAL_DBM:-}" ]]; then
        SIGNAL_STATUS="Unknown"
        return
    fi

    if (( SIGNAL_DBM >= -50 )); then
        SIGNAL_STATUS="Excellent"
    elif (( SIGNAL_DBM >= -60 )); then
        SIGNAL_STATUS="Good"
    elif (( SIGNAL_DBM >= -70 )); then
        SIGNAL_STATUS="Fair"
    else
        SIGNAL_STATUS="Poor"
    fi
}

check_connectivity() {
    if [[ -n "$GATEWAY" ]]; then
        if ping -c 1 -W 1 "$GATEWAY" &>/dev/null; then
            GATEWAY_STATUS="OK"
        fi
    fi

    if ping -c 1 -W 2 1.1.1.1 &>/dev/null; then
        INTERNET_STATUS="OK"
    fi
}