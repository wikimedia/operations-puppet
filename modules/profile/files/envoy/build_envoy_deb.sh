#!/bin/bash
# Simple script to build envoyproxy inside a chroot similar to the ones pbuilder creates.
set -exo pipefail

DISTRO=${1:-buster}
EXTRA_CMD=""
ENVOY_SRC=${ENVOY_SRC:-/usr/src/envoyproxy}
PBUILDER_DIR=${PBUILDER_DIR:-/var/cache/pbuilder}
CHROOT_BASE="$(mktemp -d -p "$PBUILDER_DIR")"
CHROOT_DIR="${CHROOT_BASE}/chroot"
CHROOTEXEC="chroot $CHROOT_DIR"

if [ "$2" = "future" ]; then
    EXTRA_CMD="--git-upstream-tree=branch --git-debian-branch=envoy-future --git-upstream-branch=envoy-future-upstream"
fi

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
    components="main"
    echo "deb http://apt.wikimedia.org/wikimedia ${DISTRO}-wikimedia ${components}" > ${CHROOT_DIR}/etc/apt/sources.list.d/wikimedia.list
    $CHROOTEXEC apt-get install wget gnupg -y
    $CHROOTEXEC wget -O - -o /dev/null http://apt.wikimedia.org/autoinstall/keyring/wikimedia-archive-keyring.gpg | $CHROOTEXEC apt-key add -
    echo "deb http://security.debian.org/debian-security $DISTRO/updates  main contrib non-free" > ${CHROOT_DIR}/etc/apt/sources.list.d/security.list
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
$CHROOTEXEC apt-get -y install docker.io
$CHROOTEXEC apt-get -y install git-buildpackage fakeroot debhelper bash-completion
$CHROOTEXEC /bin/bash -c "export LC_ALL=C; cd $ENVOY_SRC && gbp buildpackage $EXTRA_CMD --git-builder='debuild -b -uc -us'"
echo "Your build is successful, please cleanup /tmp/envoy-docker-build if not needed anymore."
