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

# Stage the Features into a self-contained tree for testing and publishing.
#
# Copies src/ and test/ into <output-dir> and places the canonical
# lib/library_scripts.sh alongside every install.sh that sources it, so each
# packaged Feature can install from GHCR without the repository checkout.
#
# Usage: scripts/stage-features.sh <output-dir>

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LIBRARY_SCRIPTS="${ROOT_DIR}/lib/library_scripts.sh"
OUTPUT_DIR=${1:?"Usage: $0 <output-dir>"}
MARKER=".staged-features"

# The canonical script is the only copy that should exist in the repository
copies=$(find "${ROOT_DIR}/src" -name library_scripts.sh)
if [ -n "${copies}" ]; then
    echo "Error: found per-Feature copies of library_scripts.sh. Edit lib/library_scripts.sh instead and delete:" >&2
    echo "${copies}" >&2
    exit 1
fi

# Only ever replace a directory this script created
if [ -e "${OUTPUT_DIR}" ]; then
    if [ -f "${OUTPUT_DIR}/${MARKER}" ]; then
        rm -rf "${OUTPUT_DIR}"
    elif [ -n "$(ls -A "${OUTPUT_DIR}")" ]; then
        echo "Error: ${OUTPUT_DIR} exists and was not created by this script" >&2
        exit 1
    fi
fi

mkdir -p "${OUTPUT_DIR}"
touch "${OUTPUT_DIR}/${MARKER}"

cp -a "${ROOT_DIR}/src" "${OUTPUT_DIR}/src"
if [ -d "${ROOT_DIR}/test" ]; then
    cp -a "${ROOT_DIR}/test" "${OUTPUT_DIR}/test"
fi

for install_script in "${OUTPUT_DIR}"/src/*/install.sh; do
    if grep -q '^\. \./library_scripts\.sh' "${install_script}"; then
        feature_dir=$(dirname "${install_script}")
        cp "${LIBRARY_SCRIPTS}" "${feature_dir}/library_scripts.sh"
        echo "Staged library_scripts.sh for $(basename "${feature_dir}")"
    fi
done

echo "Features staged in ${OUTPUT_DIR}"
