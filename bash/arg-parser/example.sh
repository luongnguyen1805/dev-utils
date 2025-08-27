#!/usr/bin/env bash

# Script will upload a package-file (zip) to Host 
# Usage: [-h HOST] [PACKAGE]

set -euo pipefail

# Default values first
HOST=
PACKAGE=

. ./parser.sh
parse -h--host:1 HOST ::1 PACKAGE --- "$@"

echo "Attempting to upload file '$PACKAGE' to '$HOST'"

