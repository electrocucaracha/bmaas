# Bare Metal as a Service
<!-- markdown-link-check-disable-next-line -->
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![GitHub Super-Linter](https://github.com/electrocucaracha/bmaas/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
![visitors](https://visitor-badge.glitch.me/badge?page_id=electrocucaracha.bmaas)

## Summary

This project was created to understand the Bare-Metal provisioning
process. It supports three different projects to perform it.

* _Manual process_: The [PXE server folder](pxe_server) contains
instructions to deploy services required by a dedicated
Provisioning server.
* _Bifrost tool_: The [Bifrost folder](bifrost) contains instructions
to deploy the [OpenStack Bare Metal as a Service(BMaaS)][3] project.
* _Tinkerbell_: The [Tinkerbell folder](tinkerbell) contains
instructions to deploy the [CNCF Tinkerbell][4] project.

## Virtual Machines

The [Vagrant tool][1] can be used for provisioning an Ubuntu Bionic
Virtual Machine. It's highly recommended to use the  _setup.sh_ script
of the [bootstrap-vagrant project][2] for installing Vagrant
dependencies and plugins required for this project. That script
supports two Virtualization providers (Libvirt and VirtualBox) which
are determine by the **PROVIDER** environment variable.

```bash
curl -fsSL http://bit.ly/initVagrant | PROVIDER=libvirt bash
```

Once Vagrant is installed, it's possible to provision a Virtual
Machine using the following instructions:

```bash
vagrant up <pxe_server|bifrost|tinkerbell>
```

The `node` VM is used to test target machines. This machine use
network booting provided by the PXE Server.

```bash
vagrant up node
```

[1]: https://www.vagrantup.com/
[2]: https://github.com/electrocucaracha/bootstrap-vagrant
[3]: https://docs.openstack.org/bifrost/latest/
[4]: https://tinkerbell.org/
