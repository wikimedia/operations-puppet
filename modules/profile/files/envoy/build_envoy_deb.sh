#!/bin/bash
# Simple script to build envoyproxy inside a chroot similar to the ones pbuilder creates.
set -exo pipefail

DISTRO=${1:-buster}
ENVOY_SRC=${ENVOY_SRC:-/usr/src/envoyproxy}
PBUILDER_DIR=${PBUILDER_DIR:-/var/cache/pbuilder}
CHROOT_BASE="$(mktemp -d -p "$PBUILDER_DIR")"
CHROOT_DIR="${CHROOT_BASE}/chroot"
CHROOTEXEC="chroot $CHROOT_DIR"

bind_mounts=(/dev /dev/pts /proc /sys /run $(realpath "${ENVOY_SRC}/../"))

function create_image {
    local base="${PBUILDER_DIR}/base-${DISTRO}-amd64.cow"
    echo "Copying the base image..."
    cp -al "$base" "${CHROOT_DIR}"
    for dir in "${bind_mounts[@]}";
    do
        dst="${CHROOT_DIR}${dir}"
        test -d "$dst" || mkdir -p "$dst"
        mount -B "$dir" "$dst"
    done
}

function add_repos {
    $CHROOTEXEC echo "deb http://apt.wikimedia.org/wikimedia ${DISTRO}-wikimedia main" > /etc/apt/sources.list.d/wikimedia.list
    $CHROOTEXEC apt-get install wget gnupg -y
    $CHROOTEXEC wget -O - -o /dev/null http://apt.wikimedia.org/autoinstall/keyring/wikimedia-archive-keyring.gpg | apt-key add -
    $CHROOTEXEC echo "deb http://security.debian.org/debian-security $DISTRO/updates  main contrib non-free" > /etc/apt/sources.list.d/security.list
    $CHROOTEXEC apt-get update
    $CHROOTEXEC apt-get upgrade -y
}


function cleanup_image {
    test -d "$CHROOT_BASE" || return
    # Perform unmounts, in reverse order to the mounts
    for (( idx=${#bind_mounts[@]}-1 ; idx>=0 ; idx-- ));
    do
        dir=${bind_mounts[$idx]}
        echo "unmounting $dir filesystem"
        umount "${CHROOT_DIR}${dir}"
    done
    rm -rf "$CHROOT_BASE"
}

trap cleanup_image EXIT

create_image
add_repos
if [ "$DISTRO" == "stretch" ]; then
   $CHROOTEXEC apt-get -y install docker-ce debhelper bash-completion
else
    $CHROOTEXEC apt-get -y install docker.io debhelper bash-completion
fi
$CHROOTEXEC apt-get -y install git-buildpackage
$CHROOTEXEC /bin/bash -c "export LC_ALL=C; cd $ENVOY_SRC && gbp buildpackage --git-builder='debuild -b -uc -us'"
echo "Your build is successful, please cleanup /tmp if not needed anymore."
