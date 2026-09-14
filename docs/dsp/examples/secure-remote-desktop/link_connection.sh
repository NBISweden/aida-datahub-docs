#!/bin/bash
# Grant a Guacamole user READ on a connection.
# Set GRANT_ADMIN=true to also grant ADMINISTER.
#
# Usage:
#   USERNAME=user@srd.dsp.se ./link_connection.sh
#   USERNAME=admin@srd.dsp.se GRANT_ADMIN=true ./link_connection.sh

GUACAMOLE_URL="${GUACAMOLE_URL:-http://localhost:8081/remote-desktops}"
GUACAMOLE_DATA_SOURCE="${GUACAMOLE_DATA_SOURCE:-postgresql}"
GUACAMOLE_USERNAME="${GUACAMOLE_USERNAME:-guacadmin}"
GUACAMOLE_PASSWORD="${GUACAMOLE_PASSWORD:-guacadmin}"
USERNAME="${USERNAME:?Set USERNAME to the Guacamole user (usually the email claim)}"
CONNECTION_NAME="${CONNECTION_NAME:-Remote-Desktop}"
GRANT_ADMIN="${GRANT_ADMIN:-false}"

authToken=$(curl -skX POST "$GUACAMOLE_URL/api/tokens" \
	-H "Content-Type: application/x-www-form-urlencoded" \
	-d "username=$GUACAMOLE_USERNAME&password=$GUACAMOLE_PASSWORD" | jq -r '.authToken')

USER_IDENTIFIER=$(curl -s -kX GET \
	"$GUACAMOLE_URL/api/session/data/$GUACAMOLE_DATA_SOURCE/users?token=${authToken}" |
	jq -r --arg USERNAME "$USERNAME" '.[$USERNAME].username')

echo "USER_IDENTIFIER: $USER_IDENTIFIER"
CONNECTION_IDENTIFIER=$(curl -s -kX GET \
	"$GUACAMOLE_URL/api/session/data/$GUACAMOLE_DATA_SOURCE/connections?token=${authToken}" |
	jq -r --arg NAME "$CONNECTION_NAME" '.[] | select(.name == $NAME) | .identifier')

PERMISSIONS='[
  {
    "op": "add",
    "path": "/connectionPermissions/'"$CONNECTION_IDENTIFIER"'",
    "value": "READ"
  }
]'

if [ "$GRANT_ADMIN" = "true" ] || [ "$GRANT_ADMIN" = "1" ]; then
	PERMISSIONS=$(jq -c '. + [{
    "op": "add",
    "path": "/systemPermissions",
    "value": "ADMINISTER"
  }]' <<<"$PERMISSIONS")
fi

curl -kX PATCH \
	"$GUACAMOLE_URL/api/session/data/$GUACAMOLE_DATA_SOURCE/users/$USER_IDENTIFIER/permissions?token=${authToken}" \
	-H "Content-Type: application/json" \
	-d "$PERMISSIONS"
