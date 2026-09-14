#!/bin/bash

GUACAMOLE_URL="http://localhost:8081/remote-desktops"
GUACAMOLE_DATA_SOURCE="postgresql"
GUACAMOLE_USERNAME="guacadmin"
GUACAMOLE_PASSWORD="guacadmin"
CONNECTION_NAME="Remote-Desktop"
SSH_PORT="2022"

authToken=$(curl -kX POST $GUACAMOLE_URL/api/tokens \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "username=$GUACAMOLE_USERNAME&password=$GUACAMOLE_PASSWORD" | jq -r '.authToken')

curl -kX POST "$GUACAMOLE_URL/api/session/data/$GUACAMOLE_DATA_SOURCE/connections?token=${authToken}" \
     -H "Content-Type: application/json" \
     -d '{
           "parentIdentifier": "ROOT",
           "name": "'$CONNECTION_NAME'",
           "protocol": "rdp",
           "attributes": {},
           "parameters": {
             "hostname": "remote-desktop",
             "port": "3389",
             "username": "ubuntu",
             "password": "ubuntu",
             "security": "any",
             "ignore-cert": "true",
             "disable-copy": "true",
             "enable-sftp": "true",
             "sftp-hostname": "remote-desktop",
             "sftp-port": "'$SSH_PORT'",
             "sftp-username": "ubuntu",
             "sftp-password": "ubuntu",
             "sftp-root-directory": "/home/ubuntu",
             "sftp-directory": "/home/ubuntu"
           }
         }'