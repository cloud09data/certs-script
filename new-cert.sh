#!/bin/bash

# Variables
server_name=$(hostname -f)
email_address="your_email@example.com"
threshold_days=30

# Function to check certificate from a keystore
check_keystore_certificate() {
    keystore_path="$1"
    keystore_pass="$2"
    # Extract the expiration date of the certificate
    expiration_date=$(keytool -list -v -keystore "$keystore_path" -storepass "$keystore_pass" | grep 'Valid from' | head -1 | awk -F 'until: ' '{print $2}')
    echo "$expiration_date"
}

# Function to check certificate from Apache server
check_apache_certificate() {
    apache_config="$1"
    # Assuming Apache config contains the path to the certificate
    cert_path=$(grep -i 'SSLCertificateFile' "$apache_config" | awk '{print $2}')
    # Extract the expiration date of the certificate
    expiration_date=$(openssl x509 -in "$cert_path" -noout -enddate | cut -d= -f2)
    echo "$expiration_date"
}

# Function to send an email report
send_email_report() {
    message="$1"
    echo "$message" | mail -s "SSL Certificate Expiry Report for $server_name" "$email_address"
}

# Main
# Placeholder for keystore and Apache paths and passwords
keystore_path="/path/to/your/keystore"
keystore_pass="your_keystore_password"
apache_config="/etc/httpd/conf/httpd.conf"

# Check certificates
keystore_cert_expiry=$(check_keystore_certificate "$keystore_path" "$keystore_pass")
apache_cert_expiry=$(check_apache_certificate "$apache_config")

# Convert expiration dates to seconds and get the current date in seconds
current_date=$(date +%s)
keystore_cert_expiry_seconds=$(date -d "$keystore_cert_expiry" +%s)
apache_cert_expiry_seconds=$(date -d "$apache_cert_expiry" +%s)

# Calculate the difference in days
keystore_diff=$(( (keystore_cert_expiry_seconds - current_date) / 86400 ))
apache_diff=$(( (apache_cert_expiry_seconds - current_date) / 86400 ))

# Prepare the email content
email_content="Hostname: $server_name\n"
email_content+="Certificate Type | Date Installed | Date Updated | Expiry Date | Days Until Expiry\n"
email_content+="--------------------------------------------------------------------------------\n"
# Assuming the installation and update dates are not readily available; placeholders are used
email_content+="JBoss Keystore | NA | NA | $keystore_cert_expiry | $keystore_diff days\n"
email_content+="Apache HTTPD | NA | NA | $apache_cert_expiry | $apache_diff days\n"

# Check if any certificate is expiring in less than threshold days and send an email
if [ "$keystore_diff" -lt "$threshold_days" ] || [ "$apache_diff" -lt "$threshold_days" ]; then
    send_email_report "$email_content"
fi