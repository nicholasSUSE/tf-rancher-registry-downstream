#!/bin/bash -x

# logs saved at:
# /var/log/cloud-init-output.log

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PUBLIC_DNS=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/public-hostname)

echo "executing rancher-save-images.sh"
sudo chmod +rwx rancher-save-images.sh
./rancher-save-images.sh --image-list ./rancher-images.txt

echo "executing rancher-load-images.sh"
sudo chmod +rwx rancher-load-images.sh
./rancher-load-images.sh --image-list ./rancher-images.txt --registry "$PUBLIC_DNS:5000"

curl https://localhost:5000/v2/_catalog --insecure | jq '.'