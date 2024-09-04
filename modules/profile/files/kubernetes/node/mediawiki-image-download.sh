#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Script to download mediawiki images, and prune old ones from the system.
# This script should be invoked by scap when deploying to kubernetes,
# to pre-pull the docker images on every node. See T323349
set -e
IMAGE_BASE_NAME="docker-registry.discovery.wmnet/restricted/mediawiki-multiversion"
IMAGES_TO_KEEP=15
if [ -z "$1" ]; then
    echo "Usage $0 <mediawiki-multiversion-tag>"
    exit 1
fi
IMAGE="$IMAGE_BASE_NAME:$1"
# This if clause is meant to provide a way to probabilistically tune the
# percentage of nodes that will actually pull the mediawiki image. This allows
# us to run some tests about how much useful this script is
# NOTE: We are doing some bash trickery here since bash doesn't support floats
PULL_THRESHOLD="25/100"  # This is a percentage
# Make it useful for a quick comparison to $RANDOM
ABSOLUTE_THRESHOLD=$(( 32767 * ${PULL_THRESHOLD}))
if [ $RANDOM -le $ABSOLUTE_THRESHOLD ]; then
    echo "Pulling '$IMAGE'..."
    docker --config /var/lib/kubelet pull "$IMAGE"
    echo "Removing all mediawiki images but the last ${IMAGES_TO_KEEP}"
    # Our tags for the docker images are in YYYY-MM-DD-HH-MM-SS format, so we can rely on them
    # to get a consistent sorting.
    # Please note that as of today `docker image ls` will return the results in the same order.
    TO_REMOVE=$(docker image ls --format "{{.Tag}}\t{{.ID}}" "$IMAGE_BASE_NAME" | sort -r | awk '{print $2}' | tail -n +${IMAGES_TO_KEEP} | sort -u)
    # Please note, we don't double quote TO_REMOVE at the end of the line on purpose
    test -n "$TO_REMOVE" && docker rmi $TO_REMOVE || /bin/true
fi
