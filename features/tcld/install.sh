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

GIT_REPO=${GIT_REPO:-"https://github.com/temporalio/tcld.git"}
VERSION=${VERSION:-"latest"}
TARGET_PATH=${TARGET_PATH:-"/usr/local/bin"}
TCLD_DIR=/tmp/tcld

rm -rf "${TCLD_DIR}"

if [ "${VERSION}" = "latest" ]; then
  echo "Getting latest tag version"

  API_URL=https://api.github.com/repos/temporalio/tcld/releases/latest
else
  echo "Getting tag version for ${VERSION}"

  API_URL="https://api.github.com/repos/temporalio/tcld/releases/tags/${VERSION}"
fi

TAG=$(curl -sL "${API_URL}" | grep tag_name | cut -d : -f 2,3 | tr -d \", | tr -d '[:space:]')

echo "Cloning and building tcld"
mkdir -p "${TCLD_DIR}"
cd "${TCLD_DIR}"
git clone "${GIT_REPO}" "${TCLD_DIR}"
git checkout "${TAG}"
make
mv ./tcld "${TARGET_PATH}"
