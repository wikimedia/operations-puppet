#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# This script ensures that the directory /srv/mediawiki contains
# the latest code from the most recent mediawiki-multiversion image.
#
# It checks whether the node already has the current version of
# the mediawiki-multiversion image. If it does not, the script:
# * downloads the image
# * runs it in a container
# * copies the files to a temporary directory
# * synchronises them to /srv/mediawiki using rsync
#
# TODO: properly log to syslog and logstash
# This script requires root privileges to run.
set -e

MOUNT_PATH="/srv/mediawiki"
REGISTRY='docker-registry.discovery.wmnet'
IMAGE_NAME='restricted/mediawiki-multiversion'
IMAGE_BASE_NAME="${REGISTRY}"/"${IMAGE_NAME}"
MEDIAWIKI_CONTAINER_DIR="/srv/mediawiki"
# IMAGES_TO_KEEP=5
LOG_FILE="/var/log/mediawiki-update-$(date +'%Y%m%d').log"

echo "Starting mediawiki image update script at $(date)" | tee -a "$LOG_FILE"

copy_directory() {
    local container=$1
    local mount_path=$2
    local container_dir=$3

    # Check if /srv/mediawiki exists on the host
    if [ ! -d "$mount_path" ]; then
      echo "$mount_path is not present" | tee -a "$LOG_FILE"
      return 1
    fi

    # Create a temporary directory for rsync. We are doing this in two steps as using rsync
    # to copy from the container to the host, would require rsync to be installed in the container.
    # nerdctl provides only cp.
    TEMP_DIR=$(mktemp -d)
    echo "Created temporary directory: $TEMP_DIR" | tee -a "$LOG_FILE"
    # Copy files from container to temp directory (keep trailing slashes)
    if ! nerdctl --namespace k8s.io cp "$container:$container_dir/." "$TEMP_DIR"; then
        echo "Failed to copy files from container to temp directory" | tee -a "$LOG_FILE"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    # Rsync files from temp directory to mount path (keep trailing slashes)
    echo "Starting rsync from $TEMP_DIR to $mount_path" | tee -a "$LOG_FILE"
    if ! rsync -a --delete "$TEMP_DIR/" "$mount_path/" >> "$LOG_FILE" 2>&1; then
        echo "Failed to rsync files from temp directory to mount path" | tee -a "$LOG_FILE"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    echo "Rsync completed successfully" | tee -a "$LOG_FILE"
    # Fix permissions on /srv/mediawiki
    /usr/local/sbin/fix-staging-perms
    # Clean up temporary directory
    rm -rf "$TEMP_DIR"
    echo "Remove temporary directory" | tee -a "$LOG_FILE"
}

# Check the latest version of the image on the registry
# This should be improved, in such a way where we pick up the
# image name from helm-file defaults
LATEST_VERSION=$(skopeo list-tags "docker://$IMAGE_BASE_NAME" | jq -r '.Tags[]' | sort -V | tail -n1)
if [ -z "$LATEST_VERSION" ]; then
    echo "Borked latest version" | tee -a "$LOG_FILE"
    exit 1
fi

# Check the local version of the image
LOCAL_VERSION=$(nerdctl --namespace k8s.io images | grep "$IMAGE_BASE_NAME" | awk '{print $2}' | sort -V | tail -n1)
if [ -z "$LOCAL_VERSION" ]; then
    echo "No local version found, first run" | tee -a "$LOG_FILE"
    LOCAL_VERSION="0.0.0"
fi
# Compare versions
if [ "$LATEST_VERSION" = "$LOCAL_VERSION" ]; then
    echo "Already at latest version $LATEST_VERSION" | tee -a "$LOG_FILE"
    exit 0
fi
# We are updating then
IMAGE="$IMAGE_BASE_NAME:$LATEST_VERSION"
echo "Updating to version $LATEST_VERSION" | tee -a "$LOG_FILE"

# Pull it
echo "Pulling image $IMAGE" | tee -a "$LOG_FILE"
if ! nerdctl --insecure-registry --namespace k8s.io pull "$IMAGE"; then
    echo "Failed to pull image $IMAGE" | tee -a "$LOG_FILE"
    exit 1
fi

# Temporary container and mount it, we use sleep infinity to keep it running
# as it will be termonated after the copy is done.
CONTAINER_NAME="mediawiki-multiversion-temp-$(date +%s)"
echo "Creating temporary container $CONTAINER_NAME" | tee -a "$LOG_FILE"
if ! nerdctl --namespace k8s.io run --name "$CONTAINER_NAME" -d "$IMAGE" sleep infinity; then
    echo "Failed to create container $CONTAINER_NAME" | tee -a "$LOG_FILE"
    exit 1
fi

# Copy
# TODO: use a cleanup function w/ trap EXIT
if ! copy_directory "$CONTAINER_NAME" "$MOUNT_PATH" "$MEDIAWIKI_CONTAINER_DIR"; then
    echo "Copy failed" | tee -a "$LOG_FILE"
    nerdctl --namespace k8s.io rm -f "$CONTAINER_NAME"
    exit 1
fi

# Cleanup temporary container
echo "Cleaning up temporary container $CONTAINER_NAME" | tee -a "$LOG_FILE"
nerdctl --namespace k8s.io rm -f "$CONTAINER_NAME"

# Remove old images TBA
# Get list of images (newest first)
# echo "Getting list of images" | tee -a "$LOG_FILE"
# IMAGE_LIST=$(nerdctl --namespace k8s.io images --format "{{.Tag}}	{{.ID}}" "$IMAGE_BASE_NAME" | sort -r)

echo "Done" | tee -a "$LOG_FILE"