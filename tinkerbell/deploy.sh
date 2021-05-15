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
source /etc/environment

export TINKERBELL_CERTS_PATH=/var/local/certs
max_attempts=3
mac_address="00:00:00:00:00:02"

sudo docker-compose up -d

# Setup Local Registry
sudo docker login --username "${REGISTRY_USERNAME:-docker}" --password "${REGISTRY_PASSWORD:-secret}" http://localhost:5000
while IFS= read -r image; do
    image_name="${image#*/}"
    if [ "$(curl --user "${REGISTRY_USERNAME:-docker}:${REGISTRY_PASSWORD:-secret}" "http://localhost:5000/v2/${image_name%:*}/tags/list" -o /dev/null -w '%{http_code}\n' -s)" != "200" ]; then
        if command -v skopeo; then
            skopeo copy --dest-tls-verify=false "docker://$image" "docker://localhost:5000/$image_name"
        else
            docker pull "$image"
            docker tag "$image" "localhost:5000/$image_name"
            docker push "localhost:5000/$image_name"
        fi
    fi
done < actions.txt

# Create tinkerbell template
attempt_counter=0
templates=$(tink template get --no-headers)
until echo "$templates" | grep -q hello_world_workflow; do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
        echo "Max attempts reached"
        exit 1
    fi
    < hello-world.tmpl tink template create || true

    attempt_counter=$((attempt_counter+1))
    sleep 5
    templates=$(tink template get --no-headers)
done
template_id=$(tink template get --no-headers | grep hello_world_workflow | awk -F '|' '{ print $2}' | xargs)

# Register Hardware
attempt_counter=0
hardware=$(tink hardware get --no-headers)
until echo "$hardware" | grep -q "$mac_address" ; do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
        echo "Max attempts reached"
        exit 1
    fi
    < testvm.json tink hardware push || true
    attempt_counter=$((attempt_counter+1))
    sleep 5
    hardware=$(tink hardware get --no-headers)
done

# Create tinkerbell workflow
workflows=$(tink workflow get --no-headers)
echo "$workflows" | grep -q "$template_id" || tink workflow create --template "$template_id" --hardware "{\"device_1\": \"$mac_address\"}"
