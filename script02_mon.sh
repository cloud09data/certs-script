#!/bin/bash

echo "---------------------------------------------------------------------"
echo "|     FQDN        |   Cert Creation Date   |   Cert Expiry Date   |"
echo "---------------------------------------------------------------------"

# Extract certificates from keystore and list them
keystore_file="/path/to/your/keystore.jks"

# Read the hashed keystore password from the environment variable
hashed_keystore_password="$HASHED_KEYSTORE_PASSWORD"

# Prompt the user for the password and hash it
read -s -p "Enter keystore password: " entered_password
hashed_entered_password=$(echo -n "$entered_password" | sha256sum | awk '{print $1}')
echo

# Compare the entered hashed password with the stored hashed password
if [ "$hashed_entered_password" != "$hashed_keystore_password" ]; then
    echo "Incorrect password. Exiting."
    exit 1
fi

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
