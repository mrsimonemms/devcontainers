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

BIN="/usr/local/bin"
REPO_OWNER="bufbuild"
REPO_NAME="buf"
VERSION="${VERSION:-"latest"}" # Default to latest if not set

# Resolve "latest" to a real tag
if [ "${VERSION}" = "latest" ]; then
    echo "Fetching latest version from GitHub..."
    API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"

    # Extract tag_name from JSON response
    VERSION=$(curl -sL "${API_URL}" | grep '"tag_name":' | cut -d : -f 2,3 | tr -d \", | tr -d '[:space:]')

    if [ -z "${VERSION}" ]; then
        echo "Error: Failed to fetch the latest version tag from GitHub."
        exit 1
    fi
fi

VERSION="${VERSION#v}"
IFS=',' read -ra BINARIES <<< "$binary_names"

for binary in "${BINARIES[@]}"; do
    echo "Downloading ${binary}..."
    DOWNLOAD_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/v${VERSION}/${binary}-$(uname -s)-$(uname -m)"

    if ! curl -fsSL "$DOWNLOAD_URL" -o "${BIN}/${binary}"; then
        echo "Error: Failed to download ${binary} version v${VERSION}."
        echo "URL: ${DOWNLOAD_URL}"
        rm -f "${BIN}/${binary}"
        exit 1
    fi

    chmod +x "${BIN}/${binary}"
done

echo 'Done!'
