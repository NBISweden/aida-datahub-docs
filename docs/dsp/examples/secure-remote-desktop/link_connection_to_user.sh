#!/bin/bash
# Convenience wrapper: READ only for the demo regular user.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME="${USERNAME:-user@srd.dsp.se}" \
	exec "$SCRIPT_DIR/link_connection.sh"
