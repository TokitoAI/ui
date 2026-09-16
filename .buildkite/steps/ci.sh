#!/usr/bin/env bash
# Everything CI gates on, inside the pinned image.
set -euo pipefail
exec "$(dirname "$0")/run-in-image.sh" ci
