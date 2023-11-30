#!/bin/bash -x
set -e

# Path to the certificate file
CERT_FILE="./certs/domain.crt"

# Delete the old certificate if it exists
if [ -f "$CERT_FILE" ]; then
    echo "Deleting old certificate..."
    rm "$CERT_FILE"
fi

# Download the new certificate
scp -o StrictHostKeyChecking=no -i ./certs/id_rsa ubuntu@${1}:/home/ubuntu/certs/domain.crt "$CERT_FILE"
