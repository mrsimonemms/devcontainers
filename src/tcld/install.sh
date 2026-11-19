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

GIT_REPO=${GIT_REPO:-"https://github.com/temporalio/tcld.git"}
VERSION=${VERSION:-"latest"}
TARGET_PATH=${TARGET_PATH:-"/usr/local/bin"}
TCLD_DIR=/tmp/tcld
# Prevent pollution of main /go dir as this is run as sudo
GOPATH=/tmp/go
GOCACHE=/tmp/gocache

rm -rf "${TCLD_DIR}"

if [ "${VERSION}" = "latest" ]; then
  # "latest" always means the latest official tcld release
  echo "Getting latest tcld release"

  if ! TAG=$(github_latest_release_tag "temporalio/tcld"); then
    echo "Error: unable to resolve the latest tcld release" >&2
    exit 1
  fi
else
  # Explicit versions are used directly as a tag in the configured repository
  TAG="${VERSION}"
fi

echo "Using tag ${TAG} from ${GIT_REPO}"

# Retry git network operations a bounded number of times
GIT_MAX_ATTEMPTS=3

attempt=1
while true; do
  rc=0
  git ls-remote --exit-code --tags "${GIT_REPO}" "refs/tags/${TAG}" >/dev/null || rc=$?
  if [ "${rc}" -eq 0 ]; then
    break
  elif [ "${rc}" -eq 2 ]; then
    # --exit-code returns 2 when the repository has no matching ref
    echo "Error: tag '${TAG}' not found in ${GIT_REPO}" >&2
    exit 1
  elif [ "${attempt}" -ge "${GIT_MAX_ATTEMPTS}" ]; then
    echo "Error: unable to reach ${GIT_REPO} after ${attempt} attempts" >&2
    exit 1
  fi
  echo "Warning: git ls-remote failed (exit ${rc}), retrying in $((attempt * 5))s" >&2
  sleep $((attempt * 5))
  attempt=$((attempt + 1))
done

echo "Cloning and building tcld"
attempt=1
until git clone --depth 1 --branch "${TAG}" "${GIT_REPO}" "${TCLD_DIR}"; do
  if [ "${attempt}" -ge "${GIT_MAX_ATTEMPTS}" ]; then
    echo "Error: unable to clone ${GIT_REPO} at ${TAG} after ${attempt} attempts" >&2
    exit 1
  fi
  echo "Warning: git clone failed, retrying in $((attempt * 5))s" >&2
  sleep $((attempt * 5))
  rm -rf "${TCLD_DIR}"
  attempt=$((attempt + 1))
done
cd "${TCLD_DIR}"
# make test breaks on linux/arm64 under QEMU
make clean bins
./tcld version
mv ./tcld "${TARGET_PATH}"
