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

source dev-container-features-test-lib

check "go is on PATH" bash -c "command -v go"
check "cobra-cli is on PATH" bash -c "command -v cobra-cli"
check "cobra-cli runs" bash -c "cobra-cli --help"
check "bash completion is installed" bash -c "test -f /etc/bash_completion.d/cobra-cli"

reportResults
