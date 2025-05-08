# Dev Containers

Pre-build [Development Containers](https://containers.dev/)

<!-- toc -->

* [Purpose](#purpose)
* [Features](#features)
* [Images](#images)
  * [Base](#base)
  * [Full](#full)
  * [Temporal Min](#temporal-min)
  * [Temporal Full](#temporal-full)
* [Usage](#usage)
* [Contributing](#contributing)
  * [Open in a container](#open-in-a-container)

<!-- Regenerate with "pre-commit run -a markdown-toc" -->

<!-- tocstop -->

## Purpose

This is a series of pre-built Devcontainer image to allow local development.

## Features

* [Cobra CLI](./features/cobra-cli)
* [Temporal Cloud CLI](./features/tcld)

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
* [Kubernetes, Helm and Minikube](https://github.com/devcontainers/features/tree/main/src/kubectl-helm-minikube)
  ✅
* [Kubectx](https://github.com/devcontainers-contrib/features/tree/main/src/kubectx-kubens)
  ✅
* [K9s](https://github.com/rio/features/tree/main/src/k9s) ✅
* [Node.js](https://github.com/devcontainers/features/tree/main/src/node) ✅
* [Pre-Commit](https://github.com/devcontainers-contrib/features/tree/main/src/pre-commit)
  ✅
* [Python](https://github.com/devcontainers/features/tree/main/src/python) ✅

The advantage of using this image is that the features are pre-built which shifts
the build effort into GitHub Actions rather than on your local machine.

This can be easily extended with additional features by adding them to your
`.devcontainer/devcontainer.json` file.

This is built to both `linux/amd64` and `linux/arm64` to cover use with both a
"standard" 64 bit machine and a modern Mac.

Both [Homebrew](https://github.com/meaningful-ooo/devcontainer-features/tree/main/src/homebrew)
and [Nix](https://github.com/devcontainers/features/tree/main/src/nix) were in
the original builds, but I found that I rarely (if ever) used them in my devcontainers
so removed them. This reduced the image size by around 2.5GB. These are also not
supported by the `linux/arm64` platform.

### Temporal Min

> `ghcr.io/mrsimonemms/devcontainers/temporal_min`

An image designed to make working with [Temporal](https://temporal.io/) easier
with the minimum Temporal dependencies installed. This image should be used for
all Temporal work and adding the required [features](https://containers.dev/features)
in your `.devcontainer/devcontainer.json`.

* [Pre-Commit](https://github.com/devcontainers-contrib/features/tree/main/src/pre-commit)
  ✅
* [Poetry](https://github.com/devcontainers-extra/features/tree/main/src/poetry)
  ✅
* [Python](https://github.com/devcontainers/features/tree/main/src/python) ✅
* [Temporal CLI](https://github.com/devcontainers-extra/features/tree/main/src/temporal-cli)
  ✅

### Temporal Full

> `ghcr.io/mrsimonemms/devcontainers/temporal_full`

An image designed to make working with [Temporal](https://temporal.io/) easier,
with native support for all official SDKs.

* [Dotnet](https://github.com/devcontainers/features/tree/main/src/dotnet)
* [Go](https://github.com/devcontainers/features/tree/main/src/go) ✅
* [Java](https://github.com/devcontainers/features/tree/main/src/java) ✅
* [Node.js](https://github.com/devcontainers/features/tree/main/src/node) ✅
* [PHP](https://github.com/devcontainers/features/tree/main/src/php) ✅
* [Pre-Commit](https://github.com/devcontainers-contrib/features/tree/main/src/pre-commit)
  ✅
* [Poetry](https://github.com/devcontainers-extra/features/tree/main/src/poetry)
  ✅
* [Python](https://github.com/devcontainers/features/tree/main/src/python) ✅
* [Ruby](https://github.com/devcontainers/features/tree/main/src/ruby) ✅
* [Temporal CLI](https://github.com/devcontainers-extra/features/tree/main/src/temporal-cli)
  ✅

This image is quite large. Unless full support for everything is required,
use the [Temporal Min](#temporal-min) image and adding the required [features](https://containers.dev/features)
in your `.devcontainer/devcontainer.json`.

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
