#!/bin/bash -i
# Copyright 2023 Simon Emms <simon@simonemms.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set -e

INSTALL_PROTOC_GEN_BUF_BREAKING="${INSTALLPROTOCGENBUFBREAKING:-"true"}"
INSTALL_PROTOC_GEN_BUF_LINT="${INSTALLPROTOCGENBUFLINT:-"true"}"

binary_names="buf"
if [[ "$INSTALL_PROTOC_GEN_BUF_BREAKING" == "true" ]]; then
    binary_names="$binary_names,protoc-gen-buf-breaking"
fi
if [[ "$INSTALL_PROTOC_GEN_BUF_LINT" == "true" ]]; then
    binary_names="$binary_names,protoc-gen-buf-lint"
fi

source ./library_scripts.sh

# nanolayer is a cli utility which keeps container layers as small as possible
# source code: https://github.com/devcontainers-contrib/nanolayer
# `ensure_nanolayer` is a bash function that will find any existing nanolayer installations,
# and if missing - will download a temporary copy that automatically get deleted at the end
# of the script
ensure_nanolayer nanolayer_location "v0.4.45"

$nanolayer_location \
    install \
    devcontainer-feature \
    "ghcr.io/devcontainers-extra/features/gh-release:1.0.26" \
        --option repo='bufbuild/buf' \
        --option binaryNames="$binary_names" \
        --option version="$VERSION" \
        --option assetRegex='.*\.tar\.gz' \
        --option libName='buf'

rm /usr/local/bin/buf

ln -s /usr/local/lib/buf/buf/bin/buf /usr/local/bin/buf

echo 'Done!'
