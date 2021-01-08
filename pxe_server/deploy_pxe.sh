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

if [ ! -f /tmp/netboot.tar.gz ]; then
    wget http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/netboot/netboot.tar.gz -O /tmp/netboot.tar.gz
fi
sudo tar xf /tmp/netboot.tar.gz -C /var/lib/tftpboot

# Make unattended installation
sudo rm -rf /tmp/preseeded
mkdir -p /tmp/preseeded
cp preseed.cfg /tmp/preseeded/
pushd /tmp/preseeded
gzip -d < /var/lib/tftpboot/ubuntu-installer/amd64/initrd.gz | sudo cpio -id
find . | sudo cpio -o -H newC | gzip > initrd.gz
sudo mv initrd.gz /var/lib/tftpboot/initrd.gz
popd

# PXELINUX Configuration for 00:00:00:00:00:02
# https://wiki.syslinux.org/wiki/index.php?title=PXELINUX#Configuration
sudo tee << EOF /var/lib/tftpboot/ubuntu-installer/amd64/pxelinux.cfg/01-00-00-00-00-00-02
DEFAULT cli
LABEL cli
  KERNEL ubuntu-installer/amd64/linux
  INITRD initrd.gz
  APPEND ip=dhcp interface=enp0s8 --- quiet
EOF
