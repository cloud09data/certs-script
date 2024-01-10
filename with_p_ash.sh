#!/bin/bash

echo "---------------------------------------------------------------------"
echo "|     FQDN        |   Cert Creation Date   |   Cert Expiry Date   |"
echo "---------------------------------------------------------------------"

# Extract certificates from keystore and list them
keystore_file="/path/to/your/keystore.jks"

# Read the keystore password from the environment variable
keystore_password="$KEYSTORE_PASSWORD"

certificates=$(keytool -list -v -keystore "$keystore_file" -storepass "$keystore_password" | grep "Alias name")

# Loop through each certificate in the keystore
while read -r line; do
    alias_name=$(echo "$line" | awk -F': ' '{print $2}')
    cert_info=$(openssl x509 -in <(keytool -printcert -rfc -alias "$alias_name" -keystore "$keystore_file" -storepass "$keystore_password") -noout -dates)
    
    creation_date=$(echo "$cert_info" | grep "notBefore" | awk -F'=' '{print $2}')
    expiry_date=$(echo "$cert_info" | grep "notAfter" | awk -F'=' '{print $2}')
    
    echo "| $alias_name | $creation_date | $expiry_date |"
    echo "---------------------------------------------------------------------"
done <<< "$certificates"
