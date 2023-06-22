#!/bin/sh
set -e

VERSION="${VERSION:-latest}"

if [ "${VERSION}" != "latest" ]; then
  if [ $(echo "${VERSION}" | cut -c1-1) != "v" ]; then
    VERSION="v${VERSION}"
  fi
fi

echo "Installing feature 'cobra-cli' - version=${VERSION}"
go install github.com/spf13/cobra-cli@${VERSION}
