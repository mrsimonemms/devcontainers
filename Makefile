DOCKER_REPO ?= ghcr.io/mrsimonemms/devcontainers
IMG_DIR = images
PLATFORM ?= linux/amd64

build-all:
	@$(MAKE) install-devcontainers

	@if ! command devcontainer --version; then \
		npm i -g @devcontainers/cli; \
	fi

	@$(MAKE) build-base build-images
.PHONY: build-all

build:
	devcontainer build \
		--platform=${PLATFORM} \
		--image-name=${DOCKER_REPO}/${IMG_NAME} \
		--workspace-folder=${CONTEXT}
.PHONY: build

build-base:
	$(MAKE) build IMG_NAME="base" CONTEXT="base"
.PHONY: build-base

build-images:
	@for img_path in $(shell ls -d ${IMG_DIR}/*); do \
		name=$$(echo $${img_path} | sed "s/${IMG_DIR}\///"); \
		\
		$(MAKE) build IMG_NAME="$${name}" CONTEXT="$${img_path}"; \
	done
.PHONY: build-images

install-devcontainers:
	@if ! command devcontainer --version; then \
		echo "Installing Dev Containers CLI"; \
		npm i -g @devcontainers/cli; \
	fi
.PHONY: install-devcontainers
