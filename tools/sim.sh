#!/usr/bin/env bash
# Start the Connect IQ simulator and load a build.
#
# Garmin builds the simulator against webkit2gtk 4.0, which Arch no longer has.
# The links in sdk/compat/ point the old names at the libraries that are there.
#
# Usage: tools/sim.sh [build.prg] [device]
set -uo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
sdk=$(cat ~/.Garmin/ConnectIQ/current-sdk.cfg 2>/dev/null | tr -d '\n')
sdk=${sdk:-$(ls -d ~/.Garmin/ConnectIQ/Sdks/*/ | tail -1)}
prg=${1:-$repo/bin/omawatch.prg}
device=${2:-instinct3amoled45mm}

pkill -f "connectiq-sdk-lin.*bin/simulator" 2>/dev/null
sleep 2
LD_LIBRARY_PATH="$repo/sdk/compat" "$sdk/bin/connectiq" >/dev/null 2>&1 &
sleep 8
exec "$sdk/bin/monkeydo" "$prg" "$device"
