DOCKER_REPO ?= ghcr.io/mrsimonemms/devcontainers
IMG_DIR = images

build-all:
	@$(MAKE) install-devcontainers

	@if ! command devcontainer --version; then \
		npm i -g @devcontainers/cli; \
	fi

	@$(MAKE) build-base build-images
.PHONY: build-all

build-base:
	@docker build -t ${DOCKER_REPO}/base base
.PHONY: build-base

build-images:
	@for img_path in $(shell ls -d ${IMG_DIR}/*); do \
		name=$$(echo $${img_path} | sed "s/${IMG_DIR}\///"); \
		img=${DOCKER_REPO}/$${name}:latest; \
		\
		devcontainer build \
			--platform=linux/amd64 \
			--image-name=$${img} \
			--workspace-folder=$${img_path}; \
	done
.PHONY: build-images

install-devcontainers:
	@if ! command devcontainer --version; then \
		echo "Installing Dev Containers CLI"; \
		npm i -g @devcontainers/cli; \
	fi
.PHONY: install-devcontainers
