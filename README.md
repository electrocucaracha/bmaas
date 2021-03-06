# Bare Metal as a Service
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Summary

This project was created to understand the Bare-Metal provisioning
processs. It supports three differen projects to perform it.

* _Manual process_: The [PXE server folder](pxe_server) contains
instructions to deploy services required by a dedicated
Provisioning server.
* _Bifrost tool_: The [Bifrost folder](bifrost) contains instructions
to deploy the [OpenStack Bare Metal as a Service(BMaaS)][3] project.
* _Tinkerbell_: The [Tinkerbell folder](tinkerbell) contains
instructions to deploy the [CNCF Tinkerbell][4] project.

## Virtual Machines

The [Vagrant tool][1] can be used for provisioning an Ubuntu Bionic
Virtual Machine. It's highly recommended to use the  *setup.sh* script
of the [bootstrap-vagrant project][2] for installing Vagrant
dependencies and plugins required for this project. That script
supports two Virtualization providers (Libvirt and VirtualBox) which
are determine by the **PROVIDER** environment variable.

    $ curl -fsSL http://bit.ly/initVagrant | PROVIDER=libvirt bash

Once Vagrant is installed, it's possible to provision a Virtual
Machine using the following instructions:

    $ vagrant up <pxe_server|bifrost|tinkerbell>

The `node` VM is used to test target machines. This machine use
network booting provided by the PXE Server.

    $ vagrant up node

[1]: https://www.vagrantup.com/
[2]: https://github.com/electrocucaracha/bootstrap-vagrant
[3]: https://docs.openstack.org/bifrost/latest/
[4]: https://tinkerbell.org/
