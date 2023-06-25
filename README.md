# Dev Containers

Prebuilt Dev Container images

<!-- toc -->

* [Purpose](#purpose)
* [Features](#features)
* [Images](#images)
  * [Base](#base)
  * [Full](#full)
* [Usage](#usage)

<!-- Regenerate with "pre-commit run -a markdown-toc" -->

<!-- tocstop -->

## Purpose

This replicates the [Gitpod workspace images](https://www.gitpod.io/docs/configure/workspaces/workspace-image)
in [Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers).
The replaces a commercial product with a free piece of software and takes advantage
of truly local development.

## Features

* [Cobra CLI](./features/cobra-cli)

## Images

There are a number of images that exist.

### Base

> `ghcr.io/mrsimonemms/devcontainers/base`

This provides a like-for-like mirror of [gitpod/workspace-base](https://github.com/gitpod-io/workspace-images/tree/main/base).
This is an Ubuntu image with not much installed except the base packages. If you
want to have a small Dev Container image, use this image.

### Full

> `ghcr.io/mrsimonemms/devcontainers/full`

This provides a like-for-like mirror of [gitpod/workspace-full](https://github.com/gitpod-io/workspace-images/tree/main/chunks),
which is the default image on all Gitpod workspaces. This uses the supported
Dev Container [features](https://containers.dev/features) instead of custom-built
image chunks like Gitpod. The advantage of using this image is that the features
are pre-built which shifts the build effort into GitHub Actions rather than on
your local machine.

See the [devcontainer.json](/images/full/.devcontainer/devcontainer.json) for
a full list of features.

This also installs and supports Minikube, something which is still not possible
in Gitpod, despite a [lot of work being done](https://github.com/gitpod-io/gitpod/issues/4889).

## Usage

These images can be used in any way that Dev Containers supports. Typically,
this would be by specifying the `image` in your `devcontainer.json` file:

```json
{
  "name": "example",
  "image": "ghcr.io/mrsimonemms/devcontainers/full"
}
```

As this image is pre-built, it will vastly speed up your workflow.
