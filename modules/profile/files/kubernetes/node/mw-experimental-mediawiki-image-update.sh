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
# This script requires root privileges to run. Any user can add a lock

set -euo pipefail

MOUNT_PATH="/srv/mediawiki"
MEDIAWIKI_CONTAINER_DIR="/srv/mediawiki"
LOG_FILE="/var/log/mediawiki-update-$(date +'%Y%m%d').log"
FORCE_COPY=false
RELEASE="/etc/helmfile-defaults/mediawiki/release/mw-experimental-pinkllama.yaml"
LOCK_FILE="/var/lock/mw-experimental-mediawiki-image-update.lock"


if [ ! -f "$RELEASE" ]; then
    echo "Release file not found: $RELEASE" | tee -a "$LOG_FILE"
    exit 1
fi

REGISTRY=$(grep -E '^\s*registry:' "$RELEASE" | awk '{print $2}')
IMAGE=$(grep -E '^\s*image:' "$RELEASE" | awk '{print $2}')
FULL_IMAGE="${REGISTRY}/${IMAGE}"

IMAGE_NAME="${IMAGE%%:*}"         # image name
LATEST_RELEASE_TAG="${IMAGE##*:}" # image tag

echo "Latest release tag for $IMAGE_NAME is: $LATEST_RELEASE_TAG" | tee -a "$LOG_FILE"

# Check arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f)
      FORCE_COPY=true
      echo "Forcing code update" | tee -a "$LOG_FILE"
      shift
      ;;
    --lock)
      # Lock to prevent code updates (either manual or via the timer)
      touch "$LOCK_FILE"
      echo "Lock created at $LOCK_FILE" | tee -a "$LOG_FILE"
      exit 0
      ;;
    --unlock)
      # Remove the lock file if it exists
      if [ -f "$LOCK_FILE" ]; then
        rm "$LOCK_FILE"
        echo "Removing lock $LOCK_FILE" | tee -a "$LOG_FILE"
      else
        echo "No lock file found at $LOCK_FILE" | tee -a "$LOG_FILE"
      fi
      exit 0
      ;;
    *)
      echo "Unknown option: $1" | tee -a "$LOG_FILE"
      echo "Usage: $0 [-f] [--lock] [--unlock]" | tee -a "$LOG_FILE"
      exit 1
      ;;
  esac
done

# Check for lock file
if [ -f "$LOCK_FILE" ]; then
    echo "Updating /srv/mediawiki has been locked. To unlock, run: $0 --unlock" | tee -a "$LOG_FILE"
    exit 0
fi

# cleanup_old_images() {
#    # TODO: Implement cleanup
#}

copy_directory() {
    local container=$1
    local target_path=$2
    local container_dir=$3

    echo "Copying from $container:$container_dir to $target_path" | tee -a "$LOG_FILE"

    TEMP_DIR=$(mktemp -d)
    echo "Created temporary directory $TEMP_DIR" | tee -a "$LOG_FILE"

    # Copy contents from the container to the temporary directory
    if ! nerdctl --namespace k8s.io cp "$container:${container_dir}/." "$TEMP_DIR"; then
        echo "Failed to copy files from container to temp dir" | tee -a "$LOG_FILE"
        rm -rf "$TEMP_DIR"
        return 1
    fi

    # Sync from temporary directory to target path
    echo "Starting rsync from $TEMP_DIR to $target_path" | tee -a "$LOG_FILE"
    if ! rsync -a --delete "$TEMP_DIR/" "$target_path/"; then
        echo "Rsync failed" | tee -a "$LOG_FILE"
        rm -rf "$TEMP_DIR"
        return 1
    fi

    echo "Rsync completed, fixing perms" | tee -a "$LOG_FILE"
    /usr/local/sbin/fix-staging-perms

    # Cleanup
    rm -rf "$TEMP_DIR"
    echo "Cleaned up temporary directory $TEMP_DIR" | tee -a "$LOG_FILE"
}

echo "Starting mw-experimental mediawiki image update script at $(date)" | tee -a "$LOG_FILE"

# Check if the image is already present locally using nerdctl inspect
if nerdctl --namespace k8s.io inspect "$FULL_IMAGE" &>/dev/null; then
    EXISTS_LOCALLY=true
else
    EXISTS_LOCALLY=false
    echo "Image $IMAGE not found locally" | tee -a "$LOG_FILE"
fi

# To update or not to update?
if $EXISTS_LOCALLY && ! $FORCE_COPY; then
    echo "Image $IMAGE already exists locally" | tee -a "$LOG_FILE"
    exit 0
elif $EXISTS_LOCALLY && $FORCE_COPY; then
    echo "Image $IMAGE exists locally but force copy requested" | tee -a "$LOG_FILE"
fi

# We are updating, so pull latest image
echo "Pulling image $FULL_IMAGE" | tee -a "$LOG_FILE"
crictl pull "$FULL_IMAGE" 2>&1 | tee -a "$LOG_FILE"

# Start container
CONTAINER_NAME="mediawiki-multiversion-temp-$(date +%s)"
echo "Creating temporary container $CONTAINER_NAME" | tee -a "$LOG_FILE"

trap "echo 'Cleaning up container'; nerdctl --namespace k8s.io rm -f $CONTAINER_NAME" EXIT

if ! nerdctl --namespace k8s.io run --net=none --name "$CONTAINER_NAME" -d "$FULL_IMAGE" sleep infinity; then
    echo "Failed to create container $CONTAINER_NAME" | tee -a "$LOG_FILE"
    exit 1
fi

if ! copy_directory "$CONTAINER_NAME" "$MOUNT_PATH" "$MEDIAWIKI_CONTAINER_DIR"; then
    echo "Copy failed" | tee -a "$LOG_FILE"
    exit 1
fi

echo -e "Done" | tee -a "$LOG_FILE"
