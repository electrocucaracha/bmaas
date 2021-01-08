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

if ! command -v bindep; then
    # NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
    curl -fsSL http://bit.ly/install_pkg | PKG=bindep bash
fi
curl -fsSL http://bit.ly/install_pkg | PKG="$(bindep -b dhcp)" bash

echo 'INTERFACES="eth1"' | sudo tee /etc/default/isc-dhcp-server
sudo tee <<EOF /etc/dhcp/dhcpd.conf
option domain-name "electrocucaracha.lan";
option domain-name-servers ns1.electrocucaracha.lan, ns2.electrocucaracha.lan;

default-lease-time 600; 
max-lease-time 7200;

# If this DHCP server is the official DHCP server for the local
# network, the authoritative directive should be uncommented.
authoritative;

subnet 10.11.0.0 netmask 255.255.255.0 {
  option routers             10.11.0.1;
  range                      10.11.0.10 10.11.0.100;
}

# https://wiki.syslinux.org/wiki/index.php?title=PXELINUX#DHCP_config_-_Simple
allow booting;
allow bootp;

# Group the PXE bootable hosts together
group {
  # PXE-specific configuration directives...
  next-server $(ip address show eth1 | awk '/inet / {print $2}' | cut -d/ -f1);
  filename "pxelinux.0";

  host vm-node01 {
    hardware ethernet 00:00:00:00:00:02;
    fixed-address 10.11.0.5;
  }
}
EOF

sudo systemctl restart isc-dhcp-server
sudo systemctl enable isc-dhcp-server
