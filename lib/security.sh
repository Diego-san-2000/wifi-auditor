get_security_info() {

    SECURITY="Unknown"
    PMF="Unknown"

    # Obtener seguridad de la red actualmente conectada
    WIFI_SECURITY=$(nmcli -t -f ACTIVE,SSID,SECURITY dev wifi 2>/dev/null |
        awk -F: '$1=="yes"{print $3; exit}')

    if [[ -n "$WIFI_SECURITY" ]]; then
        SECURITY="$WIFI_SECURITY"
    fi

    # Obtener el nombre de la conexión activa
    CONNECTION=$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null |
        awk -F: -v dev="$INTERFACE" '$2==dev{print $1; exit}')

    # PMF configurado en el perfil local
    if [[ -n "${CONNECTION:-}" ]]; then
        PMF_VALUE=$(nmcli -g 802-11-wireless-security.pmf \
            connection show "$CONNECTION" 2>/dev/null)

        case "$PMF_VALUE" in
            0)
                PMF="Disabled"
                ;;
            1)
                PMF="Optional"
                ;;
            2)
                PMF="Required"
                ;;
            *)
                PMF="Unknown"
                ;;
        esac
    fi
}