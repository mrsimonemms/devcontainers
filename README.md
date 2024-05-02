# Dev Containers

Pre-build [Development Containers](https://containers.dev/)

<!-- toc -->

* [Purpose](#purpose)
* [Features](#features)
* [Images](#images)
  * [Base](#base)
  * [Full](#full)
* [Usage](#usage)
* [Contributing](#contributing)
  * [Open in a container](#open-in-a-container)

<!-- Regenerate with "pre-commit run -a markdown-toc" -->

<!-- tocstop -->

## Purpose

This is a series of pre-built Devcontainer image to allow local development.

## Features

* [Cobra CLI](./features/cobra-cli)

## Images

There are a number of images that exist.

### Base

> `ghcr.io/mrsimonemms/devcontainers/base`

This provides a base image to use for all your development environment need.
This is an Ubuntu image with sensible defaults, including
[the best-looking Git diffs](https://github.com/so-fancy/diff-so-fancy),
Docker support, tab-completion and useful Git aliases.

### Full

> `ghcr.io/mrsimonemms/devcontainers/full`

An image with some modern tooling installed.

* [Go](https://github.com/devcontainers/features/tree/main/src/go) ✅
* [Homebrew](https://github.com/meaningful-ooo/devcontainer-features/tree/main/src/homebrew)
  ✅
* [Kubernetes, Helm and Minikube](https://github.com/devcontainers/features/tree/main/src/kubectl-helm-minikube)
  ✅
* [Kubectx](https://github.com/devcontainers-contrib/features/tree/main/src/kubectx-kubens)
  ✅
* [K9s](https://github.com/rio/features/tree/main/src/k9s) ✅
* [Nix](https://github.com/devcontainers/features/tree/main/src/nix) ✅
* [Node.js](https://github.com/devcontainers/features/tree/main/src/node) ✅
* [Pre-Commit](https://github.com/devcontainers-contrib/features/tree/main/src/pre-commit)
  ✅
* [Python](https://github.com/devcontainers/features/tree/main/src/python) ✅

The advantage of using this image is that the features are pre-built which shifts
the build effort into GitHub Actions rather than on your local machine.

This can be easily extended with additional features by adding them to your
`.devcontainer/devcontainer.json` file.

## Usage

These images can be used in any way that Dev Containers supports. Typically,
this would be by specifying the `image` in your `devcontainer.json` file:

```json
{
  "name": "devcontainer",
  "image": "ghcr.io/mrsimonemms/devcontainers/full"
}
```

As this image is pre-built, it will vastly speed up your workflow.

## Contributing

### Open in a container

* [Open in a container](https://code.visualstudio.com/docs/devcontainers/containers)
