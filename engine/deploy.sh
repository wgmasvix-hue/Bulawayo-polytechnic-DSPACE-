#!/bin/bash

set -e

PLATFORM=$1
CONFIG=$2

if [ -z "$PLATFORM" ]; then
    echo "Usage:"
    echo "chengetai deploy <platform> <config>"
    exit 1
fi

MANIFEST="templates/$PLATFORM/manifest.yaml"

if [ ! -f "$MANIFEST" ]; then
    echo "Unknown platform: $PLATFORM"
    exit 1
fi

echo "=================================="
echo " ChengetAI Deploy Engine"
echo "=================================="
echo "Platform : $PLATFORM"
echo "Manifest : $MANIFEST"
echo

bash installers/$PLATFORM/install.sh
