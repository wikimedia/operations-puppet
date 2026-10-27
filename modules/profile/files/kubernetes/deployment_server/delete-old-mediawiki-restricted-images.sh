#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# Prune old MediaWiki image tags from the restricted section of the
# Wikimedia Docker registry. Deployed and scheduled by
# profile::kubernetes::deployment_server::mediawiki::builder.
#
# Note: --older-than and --keep-last-n-images are combined, not alternatives.
# A tag is deleted only if it is both older than OLDER_THAN *and* outside the
# most recent KEEP_LAST_IMAGES tags for its repository, so a quiet week never
# empties a repository.

set -uo pipefail
set -x

KEEP_LAST_IMAGES=300
IMAGE_NAMES=(
    "mediawiki-singleversion-cli"
    "mediawiki-multiversion-cli"
    "mediawiki-singleversion"
    "mediawiki-multiversion"
    "mediawiki-singleversion-debug"
    "mediawiki-multiversion-debug"
    "mediawiki-webserver"
)

# Keep going through every repository even if one fails, but make the unit
# fail (and hence alert) if any of them did.
rc=0
for image_name in "${IMAGE_NAMES[@]}"; do
    echo "Deleting old tags for ${image_name}"
    if ! docker-registryctl -c /etc/docker-pusher/config.json \
        delete-tags "docker-registry.discovery.wmnet/restricted/${image_name}:*" \
        --older-than "3 weeks" \
        -f \
        --keep-last-n-images "${KEEP_LAST_IMAGES}"; then
        echo "Failed to delete old tags for ${image_name}" >&2
        rc=1
    fi
done

exit "${rc}"
