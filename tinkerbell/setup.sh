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

# shellcheck source=tinkerbell/defaults.env
source defaults.env

# setup_network_forwarding() - Enables IP forwarding for docker
function setup_network_forwarding {
    if [ "$(sysctl -n net.ipv4.ip_forward)" != "1" ]; then
        if [ -d /etc/sysctl.d ]; then
            echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-tinkerbell.conf
        elif [ -f /etc/sysctl.conf ]; then
            echo "net.ipv4.ip_forward=1" | sudo tee --append /etc/sysctl.conf
        fi

        sysctl net.ipv4.ip_forward=1
    fi
}

sudo mkdir -p /var/local/postgresql/data
sudo mkdir -p /var/local/registry/{images,auth}
sudo mkdir -p /var/local/osie/html/{misc/osie/current,workflow}
sudo mkdir -p "$TINKERBELL_CERTS_PATH"

sudo chown -R "$USER:" "$TINKERBELL_CERTS_PATH"
pushd "$TINKERBELL_CERTS_PATH"
if [ ! -f ca-key.pem ]; then
    # editorconfig-checker-disable
    cfssl gencert -initca - <<EOF | cfssljson -bare ca
{
	"CN": "Autogenerated CA",
	"key": {
		"algo": "rsa",
		"size": 2048
	},
	"names": [{
		"L": "@FACILITY@"
	}]
}
EOF
fi
# editorconfig-checker-disable
cat <<EOF >ca-config.json
{
	"signing": {
		"default": {
			"expiry": "168h"
		},
		"profiles": {
			"server": {
				"expiry": "8760h",
				"usages": ["signing", "key encipherment", "server auth"]
			},
			"signing": {
				"expiry": "8760h",
				"usages": ["signing", "key encipherment"]
			}
		}
	}
}
EOF
# editorconfig-checker-enable
if [ ! -f server.pem ]; then
    # editorconfig-checker-disable
    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server - <<EOF | cfssljson -bare server
{
	"CN": "tinkerbell",
	"hosts": [
		"tinkerbell.registry",
		"tinkerbell.tinkerbell",
		"tinkerbell",
		"localhost",
		"127.0.0.1"
	],
	"key": {
		"algo": "rsa",
		"size": 2048
	},
	"names": [{
		"L": "@FACILITY@"
	}]
}
EOF
    # editorconfig-checker-enable
fi
cat server.pem ca.pem >bundle.pem
popd

if [[ -n ${TINKERBELL_GRPC_AUTHORITY+x} ]] && ! grep -q TINKERBELL_GRPC_AUTHORITY /etc/environment; then
    echo "export TINKERBELL_GRPC_AUTHORITY=$TINKERBELL_GRPC_AUTHORITY" | sudo tee --append /etc/environment
fi
if [[ -n ${TINKERBELL_CERT_URL+x} ]] && ! grep -q TINKERBELL_CERT_URL /etc/environment; then
    echo "export TINKERBELL_CERT_URL=$TINKERBELL_CERT_URL" | sudo tee --append /etc/environment
fi

# Setup OSIE shared folder
if [ ! -f /var/local/osie/html/workflow/workflow-helper.sh ]; then
    curl -fSL 'https://tinkerbell-oss.s3.amazonaws.com/osie-uploads/latest.tar.gz' | tar -xvz -C /tmp/
    pushd /tmp/osie*/
    sudo mv workflow-helper.sh workflow-helper-rc /var/local/osie/html/workflow/
    sudo mv ./* /var/local/osie/html/misc/osie/current
    popd
fi
htpasswd -Bbn "${REGISTRY_USERNAME:-docker}" "${REGISTRY_PASSWORD:-secret}" | sudo tee /var/local/registry/auth/htpasswd
setup_network_forwarding
