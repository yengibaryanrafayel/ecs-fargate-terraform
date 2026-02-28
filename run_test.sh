#!/bin/bash
# Usage: ./run_test.sh
# Reads password from COGNITO_PASSWORD env var or prompts securely.

if [ -z "$COGNITO_PASSWORD" ]; then
  read -s -p "Cognito password: " COGNITO_PASSWORD
  echo ""
fi

python3 scripts/test.py \
  --us-api-url   "https://8pau1hbkxb.execute-api.us-east-1.amazonaws.com/" \
  --eu-api-url   "https://tz64f5yvv1.execute-api.eu-west-1.amazonaws.com/" \
  --user-pool-id "us-east-1_xxdoVGu8y" \
  --client-id    "5ko2erp72vb196afet9h0khu60" \
  --email        "yengibaryanraf@gmail.com" \
  --password     "$COGNITO_PASSWORD"
