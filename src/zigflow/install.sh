#!/usr/bin/env bash

set -e

. ./library_scripts.sh

arch=$(release_arch x86_64 arm64)

install_github_release_binary 'zigflow/zigflow' zigflow "$VERSION" \
    "zigflow_linux_${arch}"

echo 'Done!'
