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

export TINKERBELL_CERTS_PATH=/var/local/certs

sudo docker-compose up -d

# Setup Local Registry
sudo docker login --username "${REGISTRY_USERNAME:-docker}" --password "${REGISTRY_PASSWORD:-secret}" http://localhost:5000
while IFS= read -r image; do
    image_name="${image#*/}"
    if [ "$(curl "http://localhost:5000/v2/${image_name%:*}/tags/list" -o /dev/null -w '%{http_code}\n' -s)" != "200" ]; then
        skopeo copy --dest-tls-verify=false "docker://$image" "docker://localhost:5000/$image_name"
    fi
done < actions.txt

if ! tink template list | grep -q hello-world; then
    tink template create --path hello-world.tmpl --name hello-world
fi
template_id=$(tink template list | grep hello-world | awk -F '|' '{ print $2}' | xargs)
tink hardware push --file testvm.json
if ! tink workflow list | grep -q 00:00:00:00:00:02; then
    tink workflow create --template "$template_id" --hardware '{"device_1": "00:00:00:00:00:02"}'
fi
