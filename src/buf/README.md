
# Buf CLI (via Github Releases) (buf)

The [Buf CLI](https://buf.build/product/cli) enables building and management of Protobuf APIs - forked from [@marcozac](https://github.com/marcozac/devcontainer-features/tree/main/src/buf).

## Example Usage

```json
"features": {
    "ghcr.io/mrsimonemms/devcontainers/buf:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a Buf version. | string | latest |
| installProtocGenBufBreaking | Install also protoc-gen-buf-breaking | boolean | true |
| installProtocGenBufLint | Install also protoc-gen-buf-lint | boolean | true |

## Buf

This is forked from [@marcozac's repo](https://github.com/marcozac/devcontainer-features/tree/main/src/buf)
with a couple of bugfixes:

* Changed the installation script to use `ghcr.io/devcontainers-extra/features/gh-release`
  since `ghcr.io/devcontainers-contrib/features/gh-release` is now removed.
* Fixed [#28](https://github.com/marcozac/devcontainer-features/issues/28)


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/mrsimonemms/devcontainers/blob/main/src/buf/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
