#!/bin/bash

# Email parameters
email_recipient="recipient@example.com"
email_subject="SSL Certificate Expiry Notification"
email_body="Certificate for server %s was %s on %s and will expire on %s."

# SSL certificate warning periods (in days)
warning_periods=(60 30)

# Function to send email notification
send_email() {
    local body="$1"
    echo "$body" | mail -s "$email_subject" "$email_recipient"
}

# Function to extract certificate dates from a file
extract_certificate_dates() {
    local cert_file="$1"
    local installed_date=$(openssl x509 -noout -startdate -in "$cert_file" | awk -F= '{print $2}')
    local expiry_date=$(openssl x509 -noout -enddate -in "$cert_file" | awk -F= '{print $2}')
    echo "$installed_date" "$expiry_date"
}

# Function to calculate expiry date
calculate_expiry_date() {
    local expiry_date="$1"
    local warning_period="$2"
    local today=$(date +%s)
    local expiry=$(date -d "$expiry_date" +%s)
    local expiry_warning=$((expiry - (warning_period * 86400)))
    echo $(( (expiry_warning - today) / 86400 ))
}

# Loop through each server in the list
while IFS= read -r server; do
    hostname=$(basename "$server")
    echo "Checking server: $hostname"

    # Check if JBoss keystore file exists
    if [ -f "$server/jboss/standalone/configuration/keystore.jks" ]; then
        # Extract certificate dates from JBoss keystore
        cert_dates=$(keytool -list -v -storepass '' -keystore "$server/jboss/standalone/configuration/keystore.jks" 2>/dev/null | grep 'Alias name' | head -n 1)
        if [ -n "$cert_dates" ]; then
            installed_date=$(echo "$cert_dates" | awk '{print $NF}')
            expiry_date=$(echo "$cert_dates" | awk '{print $NF}')
            expiry_days=$(calculate_expiry_date "$expiry_date" "${warning_periods[0]}")
            if [ "$expiry_days" -lt 0 ]; then
                send_email "$(printf "$email_body" "$hostname" "renewed" "$installed_date" "$expiry_date")"
            elif [ "$expiry_days" -lt "${warning_periods[1]}" ]; then
                send_email "$(printf "$email_body" "$hostname" "renewed" "$installed_date" "$expiry_date")"
            fi
        fi
    fi

    # Check if Apache default certificate file exists
    if [ -f "$server/etc/pki/tls/certs/localhost.crt" ]; then
        # Extract certificate dates from the default Apache certificate file
        cert_dates=$(extract_certificate_dates "$server/etc/pki/tls/certs/localhost.crt")
        installed_date=$(echo "$cert_dates" | awk '{print $1}')
        expiry_date=$(echo "$cert_dates" | awk '{print $2}')
        expiry_days=$(calculate_expiry_date "$expiry_date" "${warning_periods[0]}")
        if [ "$expiry_days" -lt 0 ]; then
            send_email "$(printf "$email_body" "$hostname" "renewed" "$installed_date" "$expiry_date")"
        elif [ "$expiry_days" -lt "${warning_periods[1]}" ]; then
            send_email "$(printf "$email_body" "$hostname" "renewed" "$installed_date" "$expiry_date")"
        fi
    fi
done < server_list.txt
