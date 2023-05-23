#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /opt/scripts/liblog.sh
. /opt/scripts/libbitnami.sh

print_welcome_page

echo ""
exec "$@"
