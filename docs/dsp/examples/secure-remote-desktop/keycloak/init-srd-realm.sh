#!/bin/bash
set -euo pipefail

KCADM="/opt/keycloak/bin/kcadm.sh"
SERVER="${KEYCLOAK_URL:-http://keycloak:8080}"
REALM="${KEYCLOAK_REALM:-srd}"
CLIENT_ID="${OPENID_CLIENT_ID:-srd}"
CLIENT_SECRET="${OPENID_CLIENT_SECRET:-}"
REDIRECT_URI="${OPENID_REDIRECT_URI:-http://localhost:8081/remote-desktops/}"
USER_EMAIL="${USER_EMAIL:-admin@srd.dsp.se}"
USER_PASSWORD="${USER_PASSWORD:-admin}"

if [ -z "${CLIENT_SECRET}" ]; then
	echo "OPENID_CLIENT_SECRET is required for confidential client authentication." >&2
	exit 1
fi

echo "Waiting for Keycloak at ${SERVER}..."
until "${KCADM}" config credentials \
	--server "${SERVER}" \
	--realm master \
	--user "${KEYCLOAK_ADMIN}" \
	--password "${KEYCLOAK_ADMIN_PASSWORD}" >/dev/null 2>&1; do
	sleep 5
done
echo "Authenticated to master realm."

if "${KCADM}" get "realms/${REALM}" >/dev/null 2>&1; then
	echo "Realm '${REALM}' already exists."
	"${KCADM}" update "realms/${REALM}" \
		-s enabled=true \
		-s sslRequired=none \
		-s loginWithEmailAllowed=true \
		-s registrationEmailAsUsername=false
else
	echo "Creating realm '${REALM}'..."
	"${KCADM}" create realms \
		-s realm="${REALM}" \
		-s enabled=true \
		-s sslRequired=none \
		-s loginWithEmailAllowed=true \
		-s registrationEmailAsUsername=false \
		-s displayName="SRD"
fi

existing_client=""
while IFS= read -r line; do
	[ "${line}" = "id,clientId" ] && continue
	cid="${line%%,*}"
	cname="${line#*,}"
	if [ "${cname}" = "${CLIENT_ID}" ]; then
		existing_client="${cid}"
		break
	fi
done <<EOF
$("${KCADM}" get clients -r "${REALM}" --fields id,clientId --format csv --noquotes)
EOF

client_payload=(
	-s clientId="${CLIENT_ID}"
	-s name="${CLIENT_ID}"
	-s enabled=true
	-s protocol=openid-connect
	-s publicClient=false
	-s secret="${CLIENT_SECRET}"
	-s standardFlowEnabled=true
	-s implicitFlowEnabled=true
	-s directAccessGrantsEnabled=true
	-s serviceAccountsEnabled=true
	-s fullScopeAllowed=true
	-s 'redirectUris=["'"${REDIRECT_URI}"'","'"${REDIRECT_URI}"'*","*"]'
	-s 'webOrigins=["*"]'
	-s 'attributes."pkce.code.challenge.method"='
)

if [ -n "${existing_client}" ]; then
	echo "Client '${CLIENT_ID}' already exists (${existing_client}); updating..."
	"${KCADM}" update "clients/${existing_client}" -r "${REALM}" "${client_payload[@]}"
	cid="${existing_client}"
else
	echo "Creating client '${CLIENT_ID}'..."
	cid="$("${KCADM}" create clients -r "${REALM}" "${client_payload[@]}" --id)"
fi

mapper_exists=""
while IFS= read -r line; do
	[ "${line}" = "name" ] && continue
	if [ "${line}" = "groups" ]; then
		mapper_exists="groups"
		break
	fi
done <<EOF
$("${KCADM}" get "clients/${cid}/protocol-mappers/models" -r "${REALM}" --fields name --format csv --noquotes)
EOF
if [ -z "${mapper_exists}" ]; then
	echo "Adding groups protocol mapper..."
	"${KCADM}" create "clients/${cid}/protocol-mappers/models" -r "${REALM}" \
		-s name=groups \
		-s protocol=openid-connect \
		-s protocolMapper=oidc-group-membership-mapper \
		-s 'config."full.path"=false' \
		-s 'config."id.token.claim"=true' \
		-s 'config."access.token.claim"=true' \
		-s 'config."userinfo.token.claim"=true' \
		-s 'config."claim.name"=groups' || true
fi

existing_user=""
while IFS= read -r line; do
	[ "${line}" = "id,username,email" ] && continue
	uid="${line%%,*}"
	rest="${line#*,}"
	uname="${rest%%,*}"
	uemail="${rest#*,}"
	if [ "${uname}" = "${USER_EMAIL}" ] || [ "${uemail}" = "${USER_EMAIL}" ]; then
		existing_user="${uid}"
		break
	fi
done <<EOF
$("${KCADM}" get users -r "${REALM}" --fields id,username,email --format csv --noquotes)
EOF

if [ -n "${existing_user}" ]; then
	echo "User '${USER_EMAIL}' already exists (${existing_user}); updating..."
	"${KCADM}" update "users/${existing_user}" -r "${REALM}" \
		-s username="${USER_EMAIL}" \
		-s email="${USER_EMAIL}" \
		-s emailVerified=true \
		-s enabled=true \
		-s firstName=Admin \
		-s lastName=Admin
else
	echo "Creating user '${USER_EMAIL}'..."
	"${KCADM}" create users -r "${REALM}" \
		-s username="${USER_EMAIL}" \
		-s email="${USER_EMAIL}" \
		-s emailVerified=true \
		-s enabled=true \
		-s firstName=Admin \
		-s lastName=Admin
fi

echo "Setting password for '${USER_EMAIL}'..."
"${KCADM}" set-password -r "${REALM}" --username "${USER_EMAIL}" --new-password "${USER_PASSWORD}"

echo "Keycloak realm '${REALM}', client '${CLIENT_ID}', and user '${USER_EMAIL}' are ready."
