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

# Shared helpers for the Features in this repository.
#
# This is the only copy of this file in the repository. scripts/stage-features.sh
# (`make stage`) copies it alongside each install.sh that sources it, so every
# published Feature is self-contained and can install from GHCR on its own.
#
# Release binaries are downloaded from GitHub's public release URLs rather than
# discovered through the anonymous GitHub REST API, which is heavily rate
# limited. Every network request is retried individually with a bounded budget.

# Maximum attempts per request and the total seconds a single request may spend
# waiting between attempts
GITHUB_HTTP_MAX_ATTEMPTS=${GITHUB_HTTP_MAX_ATTEMPTS:-5}
GITHUB_HTTP_RETRY_BUDGET=${GITHUB_HTTP_RETRY_BUDGET:-120}
# Where release binaries are installed
GITHUB_RELEASE_BIN_DIR=${GITHUB_RELEASE_BIN_DIR:-/usr/local/bin}

ensure_curl() {
    # Install curl and CA certificates if curl isn't available
    if type curl >/dev/null 2>&1; then
        return 0
    fi

    echo "Installing curl"
    if [ -x /usr/bin/apt-get ]; then
        apt-get update -y
        apt-get install -y --no-install-recommends curl ca-certificates
        rm -rf /var/lib/apt/lists/*
    elif [ -x /sbin/apk ]; then
        apk add --no-cache curl ca-certificates
    else
        echo "Error: curl is required and no supported package manager was found" >&2
        return 1
    fi
}

release_arch() {
    # Print the upstream name for this machine's architecture.
    #
    # Usage: release_arch <x86_64 name> <aarch64 name>
    # Example: release_arch amd64 arm64
    case "$(uname -m)" in
        x86_64 | amd64)
            echo "$1"
            ;;
        aarch64 | arm64)
            echo "$2"
            ;;
        *)
            echo "Error: unsupported architecture $(uname -m). Supported: x86_64, aarch64" >&2
            return 1
            ;;
    esac
}

_http_header() {
    # Print the value of a header from the last response in a curl header dump
    local file=$1
    local name=$2
    tr -d '\r' <"$file" | awk -v name="$name" '
        /^HTTP\// { value = "" }
        tolower($0) ~ "^" name ":" { sub(/^[^:]*:[ \t]*/, ""); value = $0 }
        END { print value }
    '
}

_http_is_transient_curl_error() {
    # curl exit codes worth retrying: DNS, connect, HTTP/2, partial transfer,
    # timeout, TLS handshake, empty reply, send/receive and stream errors
    case "$1" in
        5 | 6 | 7 | 16 | 18 | 28 | 35 | 52 | 55 | 56 | 92) return 0 ;;
        *) return 1 ;;
    esac
}

http_fetch() {
    # Fetch a URL with bounded, per-request retries.
    #
    # Usage: http_fetch <url> <output-file> [--no-follow]
    #
    # Retries transport errors and 408/429/500/502/503/504 responses with
    # exponential backoff. Rate limits honour Retry-After or the
    # X-RateLimit-Reset time; if the wait exceeds the retry budget it fails with
    # the reset time. 404 fails immediately.
    #
    # Sets HTTP_STATUS and HTTP_REDIRECT_URL.
    # Returns 0 on success (2xx, or 3xx with --no-follow), 2 on 404, 1 otherwise.
    local url=$1
    local output=$2
    local follow_flag="-L"
    if [ "${3:-}" = "--no-follow" ]; then
        follow_flag=""
    fi

    local headers
    headers=$(mktemp)
    local attempt=1
    local waited=0
    local backoff=2
    local curl_rc write_out wait reason retry_after remaining reset now reset_note

    while true; do
        curl_rc=0
        # shellcheck disable=SC2086
        write_out=$(curl -sS $follow_flag --connect-timeout 15 --max-time 600 \
            -D "$headers" -o "$output" -w '%{http_code} %{redirect_url}' "$url") || curl_rc=$?
        HTTP_STATUS=${write_out%% *}
        HTTP_REDIRECT_URL=${write_out#* }
        wait=""
        reset_note=""

        if [ "$curl_rc" -ne 0 ]; then
            if ! _http_is_transient_curl_error "$curl_rc"; then
                echo "Error: request to ${url} failed (curl exit ${curl_rc})" >&2
                rm -f "$headers"
                return 1
            fi
            reason="transport error (curl exit ${curl_rc})"
        else
            case "$HTTP_STATUS" in
                2??)
                    rm -f "$headers"
                    return 0
                    ;;
                3??)
                    if [ -z "$follow_flag" ]; then
                        rm -f "$headers"
                        return 0
                    fi
                    echo "Error: unexpected redirect status ${HTTP_STATUS} from ${url}" >&2
                    rm -f "$headers"
                    return 1
                    ;;
                404)
                    rm -f "$headers"
                    return 2
                    ;;
                403 | 429)
                    retry_after=$(_http_header "$headers" retry-after)
                    remaining=$(_http_header "$headers" x-ratelimit-remaining)
                    reset=$(_http_header "$headers" x-ratelimit-reset)
                    now=$(date +%s)
                    if [ -n "$reset" ]; then
                        reset_note=" (rate limit resets at $(date -u -d "@${reset}" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "epoch ${reset}"))"
                    fi

                    if [ -n "$retry_after" ]; then
                        case "$retry_after" in
                            *[!0-9]*) wait=$(($(date -u -d "$retry_after" +%s 2>/dev/null || echo "$now") - now)) ;;
                            *) wait=$retry_after ;;
                        esac
                    elif [ "$remaining" = "0" ] && [ -n "$reset" ]; then
                        wait=$((reset - now))
                    elif [ "$HTTP_STATUS" = "429" ]; then
                        wait=$backoff
                    else
                        echo "Error: access denied (HTTP 403) for ${url}" >&2
                        rm -f "$headers"
                        return 1
                    fi
                    if [ "$wait" -lt 1 ]; then
                        wait=1
                    fi
                    reason="rate limited (HTTP ${HTTP_STATUS})${reset_note}"
                    ;;
                408 | 500 | 502 | 503 | 504)
                    retry_after=$(_http_header "$headers" retry-after)
                    case "$retry_after" in
                        '' | *[!0-9]*) wait=$backoff ;;
                        *) wait=$retry_after ;;
                    esac
                    reason="HTTP ${HTTP_STATUS}"
                    ;;
                *)
                    echo "Error: request to ${url} failed with HTTP ${HTTP_STATUS}" >&2
                    rm -f "$headers"
                    return 1
                    ;;
            esac
        fi

        if [ -z "$wait" ]; then
            wait=$backoff
        fi

        if [ "$attempt" -ge "$GITHUB_HTTP_MAX_ATTEMPTS" ]; then
            echo "Error: ${url} failed after ${attempt} attempts: ${reason}" >&2
            rm -f "$headers"
            return 1
        fi

        if [ $((waited + wait)) -gt "$GITHUB_HTTP_RETRY_BUDGET" ]; then
            echo "Error: ${url} failed: ${reason}. Waiting ${wait}s would exceed the ${GITHUB_HTTP_RETRY_BUDGET}s retry budget" >&2
            rm -f "$headers"
            return 1
        fi

        echo "Warning: ${url} failed: ${reason}. Retrying in ${wait}s (attempt $((attempt + 1)) of ${GITHUB_HTTP_MAX_ATTEMPTS})" >&2
        sleep "$wait"
        waited=$((waited + wait))
        attempt=$((attempt + 1))
        backoff=$((backoff * 2))
    done
}

github_latest_release_tag() {
    # Print the tag of the latest (non-prerelease) GitHub release.
    #
    # Usage: github_latest_release_tag <owner/repo>
    #
    # Follows the public github.com/<owner>/<repo>/releases/latest redirect
    # rather than calling the REST API.
    local repo=$1
    local rc=0
    local tag

    ensure_curl || return 1

    http_fetch "https://github.com/${repo}/releases/latest" /dev/null --no-follow || rc=$?
    if [ "$rc" -eq 2 ]; then
        echo "Error: repository ${repo} not found" >&2
        return 1
    elif [ "$rc" -ne 0 ]; then
        echo "Error: could not resolve the latest release of ${repo}" >&2
        return 1
    fi

    case "$HTTP_REDIRECT_URL" in
        */releases/tag/*)
            tag=${HTTP_REDIRECT_URL##*/releases/tag/}
            ;;
        *)
            echo "Error: ${repo} has no latest release (redirected to ${HTTP_REDIRECT_URL:-nowhere})" >&2
            return 1
            ;;
    esac

    if [ -z "$tag" ]; then
        echo "Error: could not resolve the latest release of ${repo}" >&2
        return 1
    fi

    echo "$tag"
}

github_release_download() {
    # Download a release asset from GitHub's public download URL.
    #
    # Usage: github_release_download <owner/repo> <tag|latest> <asset> <output-file>
    #
    # "latest" uses /releases/latest/download/<asset>, so it only suits assets
    # whose names don't change between releases.
    # Returns 0 on success, 2 if the asset (or tag) doesn't exist, 1 otherwise.
    local repo=$1
    local tag=$2
    local asset=$3
    local output=$4
    local url

    if [ "$tag" = "latest" ]; then
        url="https://github.com/${repo}/releases/latest/download/${asset}"
    else
        url="https://github.com/${repo}/releases/download/${tag}/${asset}"
    fi

    echo "Downloading ${url}"
    http_fetch "$url" "$output"
}

_github_release_tag_exists() {
    local repo=$1
    local tag=$2
    http_fetch "https://github.com/${repo}/releases/tag/${tag}" /dev/null
}

install_github_release_binary() {
    # Download a release asset and install a binary from it.
    #
    # Usage: install_github_release_binary <owner/repo> <binary> <version> <asset> [<asset>...]
    #
    # <asset> is the asset file name for this machine. It may contain {tag}
    # (the release tag) and {version} (the tag without a leading "v"). Several
    # asset names can be given; they are tried in order and the first that
    # exists is used.
    #
    # <version> is "latest" or an explicit release tag; an explicit version is
    # tried as given and then with the leading "v" added or removed. When every
    # asset name is fixed, "latest" downloads from /releases/latest/download.
    # Otherwise "latest" is resolved through the public releases/latest
    # redirect first.
    #
    # .tar.gz/.tgz assets are extracted and <binary> found inside; any other
    # asset is installed as the binary itself.
    local repo=$1
    local binary=$2
    local version=$3
    shift 3
    local assets=("$@")

    local templated=false
    local asset
    for asset in "${assets[@]}"; do
        case "$asset" in
            *'{tag}'* | *'{version}'*) templated=true ;;
        esac
    done

    ensure_curl || return 1

    local tags=()
    if [ "$version" = "latest" ]; then
        if [ "$templated" = true ]; then
            local latest_tag
            latest_tag=$(github_latest_release_tag "$repo") || return 1
            tags=("$latest_tag")
        else
            tags=("latest")
        fi
    else
        tags=("$version")
        case "$version" in
            v*) tags+=("${version#v}") ;;
            *) tags+=("v${version}") ;;
        esac
    fi

    local work_dir
    work_dir=$(mktemp -d)
    local download="${work_dir}/asset"
    local tag name rc found=""

    for tag in "${tags[@]}"; do
        for asset in "${assets[@]}"; do
            name=${asset//\{tag\}/$tag}
            name=${name//\{version\}/${tag#v}}
            rc=0
            github_release_download "$repo" "$tag" "$name" "$download" || rc=$?
            if [ "$rc" -eq 0 ]; then
                found="$name"
                break 2
            elif [ "$rc" -ne 2 ]; then
                rm -rf "$work_dir"
                return 1
            fi
        done
    done

    if [ -z "$found" ]; then
        rm -rf "$work_dir"
        if [ "$version" = "latest" ] && [ "$templated" = false ]; then
            echo "Error: the latest release of ${repo} has no asset named: ${assets[*]}" >&2
            return 1
        fi
        for tag in "${tags[@]}"; do
            if _github_release_tag_exists "$repo" "$tag"; then
                echo "Error: release ${tag} of ${repo} has no asset for this platform (tried: ${assets[*]})" >&2
                return 1
            fi
        done
        echo "Error: release ${version} not found in ${repo}" >&2
        return 1
    fi

    local source="$download"
    case "$found" in
        *.tar.gz | *.tgz)
            mkdir -p "${work_dir}/extract"
            tar -xzf "$download" -C "${work_dir}/extract"
            source=$(find "${work_dir}/extract" -type f -name "$binary" | head -n 1)
            if [ -z "$source" ]; then
                echo "Error: ${binary} not found in ${found}" >&2
                rm -rf "$work_dir"
                return 1
            fi
            ;;
    esac

    mkdir -p "$GITHUB_RELEASE_BIN_DIR"
    install -m 0755 "$source" "${GITHUB_RELEASE_BIN_DIR}/${binary}"
    rm -rf "$work_dir"
    echo "Installed ${binary} from ${repo} (${found}) to ${GITHUB_RELEASE_BIN_DIR}/${binary}"
}
