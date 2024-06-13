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

DOCKER_REPO ?= ghcr.io/mrsimonemms/devcontainers
IMG_DIR = images
PLATFORM ?= linux/amd64

all: build-all

build-all:
	@$(MAKE) install-devcontainers

	@$(MAKE) build-base build-images
.PHONY: build-all

build:
	devcontainer build \
		--platform=${PLATFORM} \
		--image-name=${DOCKER_REPO}/${IMG_NAME} \
		--workspace-folder=${CONTEXT}
.PHONY: build

build-base:
	$(MAKE) build IMG_NAME="base" CONTEXT="${IMG_DIR}/base"
.PHONY: build-base

build-images:
	@for img_path in $(shell ls -d ${IMG_DIR}/* | grep -v '/base'); do \
		name=$$(echo $${img_path} | sed "s/${IMG_DIR}\///"); \
		\
		$(MAKE) build IMG_NAME="$${name}" CONTEXT="$${img_path}"; \
	done
.PHONY: build-images

cruft-update:
ifeq (,$(wildcard .cruft.json))
	@echo "Cruft not configured"
else
	@cruft check || cruft update --skip-apply-ask --refresh-private-variables
endif
.PHONY: cruft-update

install-devcontainers:
	@if ! command devcontainer --version; then \
		echo "Installing Dev Containers CLI"; \
		npm i -g @devcontainers/cli; \
	fi
.PHONY: install-devcontainers
