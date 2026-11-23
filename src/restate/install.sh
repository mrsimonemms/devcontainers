#!/usr/bin/env bash
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

. ./library_scripts.sh

REPO="restatedev/restate"

INSTALL_CLI="${INSTALLCLI:-"true"}"
CLI_VERSION="${CLIVERSION:-"latest"}"
INSTALL_SERVER="${INSTALLSERVER:-"true"}"
SERVER_VERSION="${SERVERVERSION:-"latest"}"
INSTALL_RESTATECTL="${INSTALLRESTATECTL:-"false"}"
RESTATECTL_VERSION="${RESTATECTLVERSION:-"latest"}"

if [ "$INSTALL_CLI" != "true" ] && [ "$INSTALL_SERVER" != "true" ] && [ "$INSTALL_RESTATECTL" != "true" ]; then
    echo "No Restate components enabled. Nothing to install."
    exit 0
fi

arch=$(release_arch x86_64 aarch64)

# Resolve "latest" once so every enabled component gets the same release
latest_tag=""
for requested in "${INSTALL_CLI}:${CLI_VERSION}" "${INSTALL_SERVER}:${SERVER_VERSION}" "${INSTALL_RESTATECTL}:${RESTATECTL_VERSION}"; do
    if [ "$requested" = "true:latest" ]; then
        latest_tag=$(github_latest_release_tag "$REPO")
        break
    fi
done

version() {
    if [ "$1" = "latest" ]; then
        echo "$latest_tag"
    else
        echo "$1"
    fi
}

if [ "$INSTALL_CLI" = "true" ]; then
    install_github_release_binary "$REPO" restate "$(version "$CLI_VERSION")" \
        "restate-cli-${arch}-unknown-linux-musl.tar.xz"
fi

if [ "$INSTALL_SERVER" = "true" ]; then
    install_github_release_binary "$REPO" restate-server "$(version "$SERVER_VERSION")" \
        "restate-server-${arch}-unknown-linux-musl.tar.xz"
fi

if [ "$INSTALL_RESTATECTL" = "true" ]; then
    install_github_release_binary "$REPO" restatectl "$(version "$RESTATECTL_VERSION")" \
        "restatectl-${arch}-unknown-linux-musl.tar.xz"
fi

echo 'Done!'
