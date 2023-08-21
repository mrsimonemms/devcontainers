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

# This gives the same functionality as Gitpod's implementation
# @link https://www.gitpod.io/docs/configure/user-settings/dotfiles
# @link https://github.com/gitpod-io/gitpod/blob/158a948b4d6bdff636da1d23404f8d9232ea9ff6/components/supervisor/pkg/supervisor/supervisor.go#L524,L687

DOTFILES_DIR="${HOME}/.dotfiles"
files=("install.sh" "install" "bootstrap.sh" "bootstrap" "script/bootstrap" "setup.sh" "setup" "script/setup")

for file in "${files[@]}"; do
  full_path="${DOTFILES_DIR}/${file}"

  if [[ -d "${full_path}" ]]; then
    echo "Dotfile installation script ${full_path} is a directory"
  elif [ -f "${full_path}" ]; then
    echo "Dotfile installation script ${full_path} is a directory"

    if [ ! -x "${full_path}" ]; then
      echo "Dotfile installation script ${full_path} is not executable"
      continue
    fi

    echo "Executing script ${full_path}"

    ${full_path} || echo "Script ${full_path} failed to run"

    echo "Script ${full_path} executed successfully"
  else
    echo "Dotfile installation script ${full_path} is not available"
  fi
done
