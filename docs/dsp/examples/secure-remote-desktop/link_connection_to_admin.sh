#!/bin/bash
# Convenience wrapper: READ + ADMINISTER for the demo admin user.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME="${USERNAME:-admin@srd.dsp.se}" GRANT_ADMIN=true \
	exec "$SCRIPT_DIR/link_connection.sh"
