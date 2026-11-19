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

arch=$(release_arch x86_64 aarch64)

if [ "${VERSION}" = "latest" ]; then
    # Every nexgen release is a prerelease, which GitHub's releases/latest
    # redirect ignores. The public releases feed lists them newest first.
    ensure_curl
    feed=$(mktemp)
    if ! http_fetch "https://github.com/temporalio/nexgen/releases.atom" "$feed"; then
        echo "Error: could not fetch the nexgen releases feed" >&2
        exit 1
    fi
    VERSION=$(grep -oE '/releases/tag/[^"]+' "$feed" | head -n 1 | sed 's|.*/releases/tag/||')
    rm -f "$feed"
    if [ -z "${VERSION}" ]; then
        echo "Error: could not resolve the latest nexgen release" >&2
        exit 1
    fi
    echo "Resolved latest nexgen release: ${VERSION}"
fi

install_github_release_binary 'temporalio/nexgen' nexgen "$VERSION" \
    "nexgen-{tag}-${arch}-unknown-linux-gnu.tar.gz"

echo 'Done!'
