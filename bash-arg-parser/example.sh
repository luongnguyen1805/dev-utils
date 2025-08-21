#!/usr/bin/env bash

# Suppose you would like to upload a package-file (zip) to Host 
# Usage: [-h HOST] [PACKAGE]

set -euo pipefail

# Default values first
HOST=
PACKAGE=

. ./parser.sh
parse -h:1 HOST pos:1 PACKAGE --- "$@"

echo "Attempting to upload file '$PACKAGE' to '$HOST'"


