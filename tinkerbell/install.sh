#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o pipefail
set -o xtrace
set -o errexit
set -o nounset

export PKG_GOLANG_VERSION=1.15.12

# get_cpu_arch() - Gets CPU architecture of the server
function get_cpu_arch {
    case "$(uname -m)" in
        x86_64)
            echo "amd64"
        ;;
        armv8*|aarch64*)
            echo "arm64"
        ;;
        armv*)
            echo "armv7"
        ;;
    esac
}

# shellcheck disable=SC1091
source /etc/os-release || source /usr/lib/os-release
if ! command -v curl; then
    case ${ID,,} in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y -qq -o=Dpkg::Use-Pty=0 curl
        ;;
    esac
fi
pkgs=""
for pkg in docker docker-compose make git skopeo; do
    if ! command -v "$pkg"; then
        pkgs+=" $pkg"
    fi
done
if ! command -v go; then
    pkgs+=" go-lang"
fi
if ! command -v gcc; then
    pkgs+=" build-essential"
fi
if ! command -v htpasswd; then
    pkgs+=" apache2-utils"
fi
if [ -n "$pkgs" ]; then
    # NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
    curl -fsSL http://bit.ly/install_pkg | PKG=$pkgs bash
    # shellcheck disable=SC1091
    source /etc/profile.d/path.sh
fi

if ! command -v tink; then
    git clone --depth 1 https://github.com/tinkerbell/tink /tmp/tink
    pushd /tmp/tink
    make cli
    sudo cp cmd/tink-cli/tink-cli /usr/bin/tink
    popd
fi
for cmd in cfssl cfssljson; do
    if ! command -v "$cmd"; then
        go get -u "github.com/cloudflare/cfssl/cmd/$cmd"
        sudo mv "$HOME/go/bin/$cmd" /usr/bin/
        sudo chmod +x "/usr/bin/$cmd"
    fi
done
