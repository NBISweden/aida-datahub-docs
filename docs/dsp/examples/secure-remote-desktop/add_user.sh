#!/bin/bash

# Variables
GUACAMOLE_URL="http://localhost:8081/remote-desktops"
GUACAMOLE_DATA_SOURCE="postgresql"
GUACAMOLE_USERNAME="guacadmin"
GUACAMOLE_PASSWORD="guacadmin"

# Create user in Keycloak
KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8080}"
KEYCLOAK_REALM="${KEYCLOAK_REALM:-srd}"
KEYCLOAK_ADMIN="${KEYCLOAK_ADMIN:-admin}"
KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-admin}"

# You can override these by passing them as environment variables or inline:
EMAIL="${EMAIL:-admin@srd.dsp.se}"
PASSWORD="${PASSWORD:-changeme}"

# Request Guacamole auth token
authToken=$(curl -skX POST "$GUACAMOLE_URL/api/tokens" \
	-H "Content-Type: application/x-www-form-urlencoded" \
	-d "username=$GUACAMOLE_USERNAME&password=$GUACAMOLE_PASSWORD" | jq -r '.authToken')

# Create user payload
USER_PAYLOAD=$(
	jq -n \
		--arg username "$EMAIL" \
		--arg password "$PASSWORD" \
		'{
    username: $username,
    password: $password,
    attributes: {}
  }'
)

# Create the user
curl -skX POST "$GUACAMOLE_URL/api/session/data/$GUACAMOLE_DATA_SOURCE/users?token=${authToken}" \
	-H "Content-Type: application/json" \
	-d "$USER_PAYLOAD"

echo "User $EMAIL created (if not already present)."

# Get Keycloak admin access token
KC_TOKEN=$(curl -sk -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
	-d "client_id=admin-cli" \
	-d "username=${KEYCLOAK_ADMIN}" \
	-d "password=${KEYCLOAK_ADMIN_PASSWORD}" \
	-d "grant_type=password" | jq -r '.access_token')

if [ -z "$KC_TOKEN" ] || [ "$KC_TOKEN" == "null" ]; then
	echo "Failed to obtain Keycloak admin token"
	exit 1
fi

# Create user in Keycloak
CREATE_USER_RESPONSE=$(
	curl -sk -o /dev/null -w "%{http_code}" -X POST "${KEYCLOAK_URL}/admin/realms/${KEYCLOAK_REALM}/users" \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $KC_TOKEN" \
		-d "{
    \"username\": \"$EMAIL\",
    \"email\": \"$EMAIL\",
    \"enabled\": true,
    \"emailVerified\": true
  }"
)

if [ "$CREATE_USER_RESPONSE" == "201" ] || [ "$CREATE_USER_RESPONSE" == "409" ]; then
	echo "User $EMAIL exists or was created in Keycloak."
else
	echo "Failed to create user in Keycloak. HTTP status: $CREATE_USER_RESPONSE"
	exit 1
fi

# Get user ID from Keycloak
USER_ID=$(curl -sk -X GET "${KEYCLOAK_URL}/admin/realms/${KEYCLOAK_REALM}/users?username=${EMAIL}" \
	-H "Authorization: Bearer $KC_TOKEN" | jq -r '.[0].id')

if [ -z "$USER_ID" ] || [ "$USER_ID" == "null" ]; then
	echo "Failed to retrieve Keycloak user ID for $EMAIL"
	exit 1
fi

# Set Keycloak user password
PASSWORD_PAYLOAD="{\"type\":\"password\",\"value\":\"$PASSWORD\",\"temporary\":false}"
curl -sk -X PUT "${KEYCLOAK_URL}/admin/realms/${KEYCLOAK_REALM}/users/${USER_ID}/reset-password" \
	-H "Content-Type: application/json" \
	-H "Authorization: Bearer $KC_TOKEN" \
	-d "$PASSWORD_PAYLOAD"

echo "User $EMAIL password set in Keycloak."
