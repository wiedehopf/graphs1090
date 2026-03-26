#!/bin/bash

set -e
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR

VERSION="1.0.$(( $(cat version | cut -d'.' -f3) + 1 ))"
echo "$VERSION" > version
git add version

git commit -m "incrementing version: $VERSION"
