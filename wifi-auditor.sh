#!/bin/bash

source lib/info.sh
source lib/output.sh
source lib/security.sh
source config.sh
source "lib/password.sh"
set -u

detect_interface
get_wifi_info
get_network_info
detect_band
evaluate_signal
check_connectivity
get_security_info
run_password_audit
calculate_score
print_report