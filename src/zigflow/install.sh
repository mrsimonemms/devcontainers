#!/usr/bin/env bash

set -e

. ./library_scripts.sh

install_gh_release_binary 'zigflow/zigflow' 'zigflow' "$VERSION"

echo 'Done!'
