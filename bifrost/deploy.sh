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

if ! command -v docker; then
    # NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
    curl -fsSL http://bit.ly/install_pkg | PKG=docker bash
fi

if [[ -z $(sudo docker ps -aqf "name=ipmi-server") ]]; then
    # https://github.com/vapor-ware/ipmi-simulator
    sudo docker run -d -p 623:623/udp --name ipmi-server \
    --restart=always vaporio/ipmi-simulator
fi

BIFROST_INVENTORY_SOURCE="$(pwd)/testvm.json"
export BIFROST_INVENTORY_SOURCE
sudo git clone --depth 1 https://opendev.org/openstack/bifrost -b stable/xena /opt/stack/bifrost
pxe_nic="${BIFROST_PXE_NIC:-$(ip route get 8.8.8.8 | grep "^8." | awk '{ print $5 }')}"
pushd /opt/stack/bifrost
./bifrost-cli install \
    --network-interface "${pxe_nic}" \
    --dhcp-pool 10.11.0.10-10.11.0.100
# shellcheck disable=SC1091
source /opt/stack/bifrost/bin/activate
export OS_CLOUD=bifrost
echo "OS_CLOUD=bifrost" | sudo tee --append /etc/environment

./bifrost-cli enroll "$BIFROST_INVENTORY_SOURCE" \
    -e network_interface="${pxe_nic}"
popd

baremetal node list
ipmitool -H 127.0.0.1 -U ADMIN -P ADMIN -I lanplus chassis status
