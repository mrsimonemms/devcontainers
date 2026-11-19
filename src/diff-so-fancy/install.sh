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

# diff-so-fancy is a Perl script and needs the full Perl distribution (not
# just perl-base) for its UTF-8 I/O support
if ! perl -e 'use open ":encoding(UTF-8)"' >/dev/null 2>&1; then
    echo "Installing Perl"
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -y
        apt-get install -y --no-install-recommends perl
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache perl
    else
        echo "Error: Perl is required but no supported package manager was found"
        exit 1
    fi
fi

install_github_release_binary 'so-fancy/diff-so-fancy' diff-so-fancy "$VERSION" \
    "diff-so-fancy"

echo 'Done!'
