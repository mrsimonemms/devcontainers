
# Restate (restate)

Restate is the platform for building resilient applications that tolerate all infrastructure faults w/o the need for a PhD

## Example Usage

```json
"features": {
    "ghcr.io/mrsimonemms/devcontainers/restate:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| installCLI | Install the Restate CLI binary | boolean | true |
| cliVersion | Select the version of the CLI you would like to install | string | latest |
| installServer | Install the Restate server binary | boolean | true |
| serverVersion | Select the version of the Server you would like to install | string | latest |
| installRestatectl | Install the Restatectl binary | boolean | false |
| restatectlVersion | Select the version of the restatectl you would like to install | string | latest |

## Restate

This Feature installs [the Restate binaries](https://github.com/restatedev/restate)

## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions
with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/mrsimonemms/devcontainers/blob/main/src/restate/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
