get_wifi_password() {
    if ! command -v nmcli &>/dev/null; then
        echo "[-] nmcli is not installed."
        return 1
    fi

    CONNECTION=$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null |
        awk -F: -v dev="$INTERFACE" '$2==dev{print $1; exit}')

    if [[ -z "$CONNECTION" ]]; then
        echo "[-] Could not determine active Wi-Fi connection."
        return 1
    fi

    PASSWORD=$(nmcli -s -g 802-11-wireless-security.psk \
        connection show "$CONNECTION" 2>/dev/null)

    if [[ -z "$PASSWORD" ]]; then
        echo "[-] Could not retrieve the stored Wi-Fi password."
        return 1
    fi
    #PASSWORD="o4gN2muW\99C9|qo%R:?VY}!mM_,iSJWbcmd*z/jf*Ta"
    return 0
}


calculate_password_entropy() {
    local length="${#PASSWORD}"
    local charset=0

    [[ -z "$PASSWORD" ]] && { echo "0.0"; return 0; }

    # Character set evaluation
    [[ "$PASSWORD" =~ [a-z] ]] && ((charset += 26))
    [[ "$PASSWORD" =~ [A-Z] ]] && ((charset += 26))
    [[ "$PASSWORD" =~ [0-9] ]] && ((charset += 10))
    # Matches printable special ASCII characters safely
    [[ "$PASSWORD" =~ [^a-zA-Z0-9] ]] && ((charset += 33))

    (( charset == 0 )) && { echo "0.0"; return 0; }

    PASSWORD_ENTROPY=$(bc -l <<< "scale=1; $length * (l($charset) / l(2))")

    # Extrae solo la parte entera para hacer la comparación aritmética en Bash
    local entropy_int="${PASSWORD_ENTROPY%.*}"
    entropy_int="${entropy_int:-0}"

    if (( entropy_int < 28 )); then
        PASSWORD_STRENGTH="Very weak"
        NOTESSTRENGTH="- 50"
        OBSERVATIONSSTRENGTH="Change the password to a more complex one."
    elif (( entropy_int < 36 )); then
        PASSWORD_STRENGTH="Weak"
        NOTESSTRENGTH="- 30"
        OBSERVATIONSSTRENGTH="Change the password to a more complex one."
    elif (( entropy_int < 60 )); then
        PASSWORD_STRENGTH="Normal"
        NOTESSTRENGTH="- 10"
        OBSERVATIONSSTRENGTH="Change the password to a more complex one."
    elif (( entropy_int < 80 )); then
        PASSWORD_STRENGTH="Strong"
        NOTESSTRENGTH="- 5"
    else
        PASSWORD_STRENGTH="Very strong"
    fi
}




check_password_breach() {
    if ! command -v curl &>/dev/null; then
        PASSWORD_BREACHED="UNKNOWN"
        return
    fi

    local HASH
    local PREFIX
    local SUFFIX
    local RESPONSE

    HASH=$(printf '%s' "$PASSWORD" |
        sha1sum |
        awk '{print toupper($1)}')

    PREFIX="${HASH:0:5}"
    SUFFIX="${HASH:5}"

    RESPONSE=$(curl -fsS \
        --max-time 5 \
        "https://api.pwnedpasswords.com/range/$PREFIX" 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        PASSWORD_BREACHED="UNKNOWN"
        return
    fi

    if echo "$RESPONSE" | grep -q "^${SUFFIX}:"; then
        PASSWORD_BREACHED="YES"
        NOTESBREACHED="- 100"
        OBSERVATIONSBREACHED="The password has been found in a data breach. Chante it to a new one."
        SCORE=$((SCORE - 100))
    else
        PASSWORD_BREACHED="NO"
    fi
}


run_password_audit() {

    if ! get_wifi_password; then
        return
    fi

    calculate_password_entropy
    check_password_breach
}