#!/bin/bash

# Function to send an email notification
send_email() {
    local recipient="your_email@example.com"
    local subject="Certificate Expiry Notification"
    local message="Your certificate with FQDN $1 will expire in $2 days. Plan to renew your certificate."
    
    # Use a command or tool like 'mail' or 'sendmail' to send the email
    # Example using 'mail':
    # echo "$message" | mail -s "$subject" "$recipient"
    
    # Modify the above line to send emails using your preferred email tool
}

# Function to check certificate expiry
check_certificate_expiry() {
    local keystore_file="/path/to/your/keystore.jks"
    local keystore_password=""
    local httpd_config="/path/to/your/httpd.conf"

    if [ -e "$keystore_file" ]; then
        certificates=$(keytool -list -v -keystore "$keystore_file" -storepass "$keystore_password" | grep "Alias name")

        while read -r line; do
            alias_name=$(echo "$line" | awk -F': ' '{print $2}')
            cert_info=$(openssl x509 -in <(keytool -printcert -rfc -alias "$alias_name" -keystore "$keystore_file" -storepass "$keystore_password") -noout -dates)
            
            creation_date=$(echo "$cert_info" | grep "notBefore" | awk -F'=' '{print $2}')
            expiry_date=$(echo "$cert_info" | grep "notAfter" | awk -F'=' '{print $2}')
            fqdn="$alias_name"  # Use alias name as FQDN (modify as needed)

            # Calculate the number of days until certificate expiry
            current_date=$(date +%s)
            expiry_epoch=$(date -d "$expiry_date" +%s)
            days_until_expiry=$(( (expiry_epoch - current_date) / 86400 ))

            # Check if the certificate will expire in less than 60 days
            if [ "$days_until_expiry" -lt 60 ]; then
                send_email "$fqdn" "$days_until_expiry"
            fi

            # Print certificate information in table format
            echo "| $fqdn | $creation_date | $expiry_date |"

        done <<< "$certificates"
    else
        echo "Keystore file does not exist."
    fi

    # Extract certificates from Apache HTTPD configuration and list them
    if [ -e "$httpd_config" ]; then
        cert_files=$(awk -F= '/SSLCertificateFile/ {print $2}' "$httpd_config")
        key_files=$(awk -F= '/SSLCertificateKeyFile/ {print $2}' "$httpd_config")

        for cert_file in $cert_files; do
            key_file=$(grep -A1 "SSLCertificateFile $cert_file" "$httpd_config" | awk '/SSLCertificateKeyFile/ {print $2}')
            fqdn=$(grep -A1 "SSLCertificateFile $cert_file" "$httpd_config" | awk '/ServerName/ {print $2}')
            
            cert_info=$(openssl x509 -in "$cert_file" -noout -dates)
            creation_date=$(echo "$cert_info" | grep "notBefore" | awk -F'=' '{print $2}')
            expiry_date=$(echo "$cert_info" | grep "notAfter" | awk -F'=' '{print $2}')

            # Calculate the number of days until certificate expiry
            current_date=$(date +%s)
            expiry_epoch=$(date -d "$expiry_date" +%s)
            days_until_expiry=$(( (expiry_epoch - current_date) / 86400 ))

            # Check if the certificate will expire in less than 60 days
            if [ "$days_until_expiry" -lt 60 ]; then
                send_email "$fqdn" "$days_until_expiry"
            fi

            # Print certificate information in table format
            echo "| $fqdn | $creation_date | $expiry_date |"
        done
    else
        echo "HTTPD configuration file does not exist."
    fi
}

# Run the certificate expiry check
check_certificate_expiry
