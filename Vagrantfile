# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :
##############################################################################
# Copyright (c)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

no_proxy = ENV['NO_PROXY'] || ENV['no_proxy'] || '127.0.0.1,localhost'
(1..254).each do |i|
  no_proxy += ",10.0.2.#{i}"
end

# rubocop:disable Metrics/BlockLength
Vagrant.configure('2') do |config|
  # rubocop:enable Metrics/BlockLength
  config.vm.provider :libvirt
  config.vm.provider :virtualbox

  config.vm.box = 'generic/ubuntu2204'
  config.vm.box_check_update = false
  %i[virtualbox libvirt].each do |provider|
    config.vm.provider provider do |p|
      p.cpus = 1
      p.memory = 1024
    end
  end

  # Configure DNS resolver
  config.vm.provision 'shell', privileged: false, inline: <<-SHELL
    if command -v systemd-resolve && sudo systemd-resolve --status --interface eth0; then
        sudo systemd-resolve --interface eth0 --set-dns 1.1.1.1 --flush-caches
        sudo systemd-resolve --status --interface eth0
    fi
    if [ -f /etc/netplan/01-netcfg.yaml ]; then
        sudo sed -i "s/addresses: .*/addresses: [1.1.1.1, 8.8.8.8, 8.8.4.4]/g" /etc/netplan/01-netcfg.yaml
        sudo netplan apply
    fi
  SHELL

  config.vm.provider 'virtualbox' do |v|
    v.gui = false
    v.customize ['modifyvm', :id, '--nictype1', 'virtio', '--cableconnected1', 'on']
    v.customize ['modifyvm', :id, '--nictype2', 'virtio', '--cableconnected2', 'on']
  end

  config.vm.provider :libvirt do |v|
    v.random_hostname = true
    v.management_network_address = '10.0.2.0/24'
    v.management_network_name = 'administration'
    v.cpu_mode = 'host-passthrough'
    v.memorybacking :access, mode: 'shared'
  end

  if !ENV['http_proxy'].nil? && !ENV['https_proxy'].nil? && Vagrant.has_plugin?('vagrant-proxyconf')
    config.proxy.http = ENV['http_proxy'] || ENV['HTTP_PROXY'] || ''
    config.proxy.https    = ENV['https_proxy'] || ENV['HTTPS_PROXY'] || ''
    config.proxy.no_proxy = no_proxy
    config.proxy.enabled = { docker: false }
  end

  config.vm.define :pxe_server do |pxe_server|
    pxe_server.vm.hostname = 'pxe-server'
    pxe_server.vm.synced_folder './pxe_server/', '/vagrant'

    pxe_server.vm.provider :libvirt do |_v, override|
      override.vm.synced_folder './pxe_server/', '/vagrant', type: 'virtiofs'
    end

    pxe_server.vm.network :private_network,
                          ip: '10.11.0.2',
                          virtualbox__intnet: 'pxe_network',
                          libvirt__network_name: 'pxe_network',
                          libvirt__dhcp_enabled: false

    pxe_server.vm.provision 'shell', privileged: false, inline: <<-SHELL
      set -o errexit
      set -o pipefail

      cd /vagrant
      ./_configure.sh | tee ~/configure.log
      ./deploy_tftp.sh | tee ~/deploy_tftp.log
      ./deploy_dhcp.sh | tee ~/deploy_dhcp.log
      sudo nmap --script broadcast-dhcp-discover -e eth1
      ./deploy_pxe.sh | tee ~/deploy_pxe.log
    SHELL
  end

  config.vm.define :bifrost do |bifrost|
    bifrost.vm.hostname = 'bifrost'
    bifrost.vm.synced_folder './bifrost/', '/vagrant'

    bifrost.vm.provider :libvirt do |_v, override|
      override.vm.synced_folder './bifrost/', '/vagrant', type: 'virtiofs'
    end

    bifrost.vm.network :private_network,
                       ip: '10.11.0.3',
                       virtualbox__intnet: 'pxe_network',
                       libvirt__network_name: 'pxe_network',
                       libvirt__dhcp_enabled: false

    bifrost.vm.provision 'shell', privileged: false do |sh|
      sh.env = {
        BIFROST_PXE_NIC: 'eth0'
      }
      sh.inline = <<~SHELL
        set -o errexit
        set -o pipefail

        cd /vagrant
        ./deploy.sh | tee ~/deploy.log
      SHELL
    end
  end

  config.vm.define :tinkerbell do |tinkerbell|
    tinkerbell.vm.hostname = 'tinkerbell'
    tinkerbell.vm.synced_folder './tinkerbell/', '/vagrant'

    tinkerbell.vm.provider :libvirt do |_v, override|
      override.vm.synced_folder './tinkerbell/', '/vagrant', type: 'virtiofs'
    end

    tinkerbell.vm.network :private_network,
                          ip: '10.11.0.4',
                          virtualbox__intnet: 'pxe_network',
                          libvirt__network_name: 'pxe_network',
                          libvirt__dhcp_enabled: false

    tinkerbell.vm.provision 'shell', privileged: false, inline: <<-SHELL
      set -o errexit
      set -o pipefail

      cd /vagrant
      ./install.sh | tee ~/install.log
      ./setup.sh | tee ~/setup.log
      ./deploy.sh | tee ~/deploy.log
    SHELL
  end

  config.vm.define :node, autostart: false do |node|
    node.vm.network :private_network,
                    mac: '000000000002',
                    virtualbox__intnet: 'pxe_network',
                    libvirt__network_name: 'pxe_network'
    %i[virtualbox libvirt].each do |provider|
      node.vm.provider provider do |p|
        p.memory = 512
      end
    end

    node.vm.provider :libvirt do |lv, override|
      lv.boot 'network'
      lv.mgmt_attach = false
      override.vm.box = nil
      lv.storage :file, size: '40G'
    end

    node.vm.provider :virtualbox do |vb|
      vb.gui = true
      vb.customize [
        'modifyvm', :id, '--boot1', 'net', '--boot2', 'none',
        '--boot3', 'none', '--boot4', 'none'
      ]
      vb.customize ['modifyvm', :id, '--nic1', 'none']
    end
  end
end
