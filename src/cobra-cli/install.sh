#!/bin/bash
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

TARGET_GOPATH="${TARGET_GOPATH:-"/go"}"
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
VERSION="${VERSION:-latest}"

if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "code" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

if [ "${VERSION}" != "latest" ]; then
  if [ $(echo "${VERSION}" | cut -c1-1) != "v" ]; then
    VERSION="v${VERSION}"
  fi
fi

echo "Installing feature 'cobra-cli' - version=${VERSION}"
go install github.com/spf13/cobra-cli@${VERSION}

chown -R "${USERNAME}:golang" "${TARGET_GOPATH}"
chmod -R g+r+w "${TARGET_GOPATH}"

cobra-cli completion bash > /etc/bash_completion.d/cobra-cli

echo "Symlinking $PWD/.cobra.yaml to $HOME/.cobra.yaml"
ln -s $PWD/.cobra.yaml $HOME/.cobra.yaml
