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

clean_download() {
    # The purpose of this function is to download a file with minimal impact on container layer size
    # this means if no valid downloader is found (curl or wget) then we install a downloader (currently wget) in a
    # temporary manner, and making sure to
    # 1. uninstall the downloader at the return of the function
    # 2. revert back any changes to the package installer database/cache (for example apt-get lists)
    # The above steps will minimize the leftovers being created while installing the downloader
    # Supported distros:
    #  debian/ubuntu/alpine

    url=$1
    output_location=$2
    tempdir=$(mktemp -d)
    downloader_installed=""

    _apt_get_install() {
        tempdir=$1

        # copy current state of apt list - in order to revert back later (minimize contianer layer size)
        cp -p -R /var/lib/apt/lists $tempdir
        apt-get update -y
        apt-get -y install --no-install-recommends wget ca-certificates
    }

    _apt_get_cleanup() {
        tempdir=$1

        echo "removing wget"
        apt-get -y purge wget --auto-remove

        echo "revert back apt lists"
        rm -rf /var/lib/apt/lists/*
        rm -r /var/lib/apt/lists && mv $tempdir/lists /var/lib/apt/lists
    }

    _apk_install() {
        tempdir=$1
        # copy current state of apk cache - in order to revert back later (minimize contianer layer size)
        cp -p -R /var/cache/apk $tempdir

        apk add --no-cache  wget
    }

    _apk_cleanup() {
        tempdir=$1

        echo "removing wget"
        apk del wget
    }
    # try to use either wget or curl if one of them already installer
    if type curl >/dev/null 2>&1; then
        downloader=curl
    elif type wget >/dev/null 2>&1; then
        downloader=wget
    else
        downloader=""
    fi

    # in case none of them is installed, install wget temporarly
    if [ -z $downloader ] ; then
        if [ -x "/usr/bin/apt-get" ] ; then
            _apt_get_install $tempdir
        elif [ -x "/sbin/apk" ] ; then
            _apk_install $tempdir
        else
            echo "distro not supported"
            exit 1
        fi
        downloader="wget"
        downloader_installed="true"
    fi

    if [ $downloader = "wget" ] ; then
        wget -q $url -O $output_location
    else
        curl -sfL $url -o $output_location
    fi

    # NOTE: the cleanup procedure was not implemented using `trap X RETURN` only because
    # alpine lack bash, and RETURN is not a valid signal under sh shell
    if ! [ -z $downloader_installed  ] ; then
        if [ -x "/usr/bin/apt-get" ] ; then
            _apt_get_cleanup $tempdir
        elif [ -x "/sbin/apk" ] ; then
            _apk_cleanup $tempdir
        else
            echo "distro not supported"
            exit 1
        fi
    fi

}


ensure_nanolayer() {
    # Ensure existance of the nanolayer cli program
    local variable_name=$1

    local required_version=$2

    local __nanolayer_location=""

    # If possible - try to use an already installed nanolayer
    if [ -z "${NANOLAYER_FORCE_CLI_INSTALLATION}" ]; then
        if [ -z "${NANOLAYER_CLI_LOCATION}" ]; then
            if type nanolayer >/dev/null 2>&1; then
                echo "Found a pre-existing nanolayer in PATH"
                __nanolayer_location=nanolayer
            fi
        elif [ -f "${NANOLAYER_CLI_LOCATION}" ] && [ -x "${NANOLAYER_CLI_LOCATION}" ] ; then
            __nanolayer_location=${NANOLAYER_CLI_LOCATION}
            echo "Found a pre-existing nanolayer which were given in env variable: $__nanolayer_location"
        fi

        # make sure its of the required version
        if ! [ -z "${__nanolayer_location}" ]; then
            local current_version
            current_version=$($__nanolayer_location --version)


            if ! [ $current_version == $required_version ]; then
                echo "skipping usage of pre-existing nanolayer. (required version $required_version does not match existing version $current_version)"
                __nanolayer_location=""
            fi
        fi

    fi

    # If not previuse installation found, download it temporarly and delete at the end of the script
    if [ -z "${__nanolayer_location}" ]; then

        if [ "$(uname -sm)" = 'Linux x86_64' ] || [ "$(uname -sm)" = "Linux aarch64" ]; then
            tmp_dir=$(mktemp -d -t nanolayer-XXXXXXXXXX)

            clean_up () {
                ARG=$?
                rm -rf $tmp_dir
                exit $ARG
            }
            trap clean_up EXIT


            if [ -x "/sbin/apk" ] ; then
                clib_type=musl
            else
                clib_type=gnu
            fi

            tar_filename=nanolayer-"$(uname -m)"-unknown-linux-$clib_type.tgz

            # clean download will minimize leftover in case a downloaderlike wget or curl need to be installed
            clean_download https://github.com/devcontainers-extra/nanolayer/releases/download/$required_version/$tar_filename $tmp_dir/$tar_filename

            tar xfzv $tmp_dir/$tar_filename -C "$tmp_dir"
            chmod a+x $tmp_dir/nanolayer
            __nanolayer_location=$tmp_dir/nanolayer


        else
            echo "No binaries compiled for non-x86-linux architectures yet: $(uname -m)"
            exit 1
        fi
    fi

    # Expose outside the resolved location
    export ${variable_name}=$__nanolayer_location

}

# Shared helpers for the Features in this repository.
#
# This is the only copy of this file in the repository. scripts/stage-features.sh
# (`make stage`) copies it alongside each install.sh that sources it, so every
# published Feature is self-contained and can install from GHCR on its own.

install_gh_release_binary() {
    # Install binaries from a GitHub release using nanolayer and the
    # devcontainers-extra gh-release Feature.
    #
    # Usage: install_gh_release_binary <owner/repo> <binaryNames> <version> [extra nanolayer args...]
    # Example: install_gh_release_binary 'air-verse/air' 'air' "$VERSION" --option assetRegex='\.tar\.gz$'
    #
    # Note: gh-release looks up release assets through the anonymous GitHub
    # REST API, so it is subject to its rate limits.
    local repo=$1
    local binary_names=$2
    local version=$3
    shift 3

    # nanolayer is a cli utility which keeps container layers as small as possible
    # source code: https://github.com/devcontainers-extra/nanolayer
    # `ensure_nanolayer` will find any existing nanolayer installations, and if
    # missing - will download a temporary copy that automatically get deleted at
    # the end of the script
    ensure_nanolayer nanolayer_location "v0.5.6"

    "$nanolayer_location" \
        install \
        devcontainer-feature \
        "ghcr.io/devcontainers-extra/features/gh-release:1.0.25" \
        --option repo="$repo" --option binaryNames="$binary_names" --option version="$version" \
        "$@"
}

github_latest_release_tag() {
    # Print the tag of the latest GitHub release for a repository.
    #
    # Usage: github_latest_release_tag <owner/repo>
    #
    # This follows the github.com/<owner>/<repo>/releases/latest redirect rather
    # than calling the anonymous REST API, so it is not subject to its rate
    # limits. Returns non-zero with an error message if the tag can't be found.
    local repo=$1
    local url
    local tag

    if ! type curl >/dev/null 2>&1; then
        echo "Error: curl is required to resolve the latest release of ${repo}" >&2
        return 1
    fi

    if ! url=$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/${repo}/releases/latest"); then
        echo "Error: failed to reach https://github.com/${repo}/releases/latest" >&2
        return 1
    fi

    case "$url" in
        */releases/tag/*)
            tag=${url##*/releases/tag/}
            ;;
        *)
            echo "Error: could not resolve the latest release of ${repo} (redirected to ${url})" >&2
            return 1
            ;;
    esac

    if [ -z "$tag" ]; then
        echo "Error: could not resolve the latest release of ${repo}" >&2
        return 1
    fi

    echo "$tag"
}
