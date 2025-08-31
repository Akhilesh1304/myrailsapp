#!/bin/bash
set -e

# Remove any existing server.pid
rm -f /myapp/tmp/pids/server.pid

# Run the command
exec "$@"
