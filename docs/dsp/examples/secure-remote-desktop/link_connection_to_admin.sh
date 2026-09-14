#!/bin/bash

GUACAMOLE_URL="http://localhost:8081/remote-desktops"
GUACAMOLE_DATA_SOURCE="postgresql"
GUACAMOLE_USERNAME="guacadmin"
GUACAMOLE_PASSWORD="guacadmin"
EMAIL="admin@srd.dsp.se"
USERNAME="admin@srd.dsp.se"
CONNECTION_NAME="Remote-Desktop"

authToken=$(curl -kX POST $GUACAMOLE_URL/api/tokens \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "username=$GUACAMOLE_USERNAME&password=$GUACAMOLE_PASSWORD" | jq -r '.authToken')

USER_IDENTIFIER=$(curl -s -kX GET "$GUACAMOLE_URL/api/session/data/$GUACAMOLE_DATA_SOURCE/users?token=${authToken}" \
  | jq -r --arg USERNAME "$USERNAME" '.[$USERNAME].username')

echo "USER_IDENTIFIER: $USER_IDENTIFIER"
CONNECTION_IDENTIFIER=$(curl -s -kX GET "$GUACAMOLE_URL/api/session/data/$GUACAMOLE_DATA_SOURCE/connections?token=${authToken}" \
  | jq -r --arg NAME "$CONNECTION_NAME" '.[] | select(.name == $NAME) | .identifier')
curl -kX PATCH "$GUACAMOLE_URL/api/session/data/postgresql/users/$USER_IDENTIFIER/permissions?token=${authToken}" \
     -H "Content-Type: application/json" \
     -d '[
           {
             "op": "add",
             "path": "/connectionPermissions/'"$CONNECTION_IDENTIFIER"'",
             "value": "READ"
           },
           {
             "op": "add",
             "path": "/systemPermissions",
             "value": "ADMINISTER"
           }
         ]'