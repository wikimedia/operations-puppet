#!/bin/bash
set -e
# Things you can override with env variables, but you shouldn't really if not testing.
SRCDIR=${SRCDIR:-/srv/images/base}
REGISTRY=${REGISTRY:-docker-registry.discovery.wmnet}
usage() {
    echo "Usage: $0 <distribution>"
    exit 1
}

# We need a command line argument.
if [ $# -ne 1 ]; then
    usage
fi
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

TMPDIR=$(mktemp -d)
cleanup() {
    cd $(dirs -l -0) && dirs -c
    rm -rf $TMPDIR
}

trap cleanup EXIT

create_rootfs_tar() {
    local distro=$1
    local ts=$2
    local output=$3
    debuerreotype-init rootfs $distro $ts
    debuerreotype-minimizing-config rootfs
    # Fix the apt sources here.
    # Please note we're not using debuerreotype here because
    # we want to use the wikimedia sources from the start
    # to save layers later.
    cp "${SRCDIR}/sources/${distro}.sources.list" rootfs/etc/apt/sources.list
    cp  "${SRCDIR}/wikimedia.pub.gpg" "rootfs/etc/apt/trusted.gpg.d/wikimedia-${distro}.pub.gpg"
    cp "${SRCDIR}/wikimedia.preferences" rootfs/etc/apt/preferences.d/wikimedia
    echo 'APT::Install-Recommends "false";' > rootfs/etc/apt/apt.conf.d/00InstallRecommends

    debuerreotype-apt-get rootfs update -qq
    debuerreotype-apt-get rootfs dist-upgrade -yqq
    debuerreotype-slimify rootfs
    debuerreotype-tar rootfs $output
}

pushd $TMPDIR
_distro=$1
_date=$(date -u --iso-8601=minutes | sed 's/+.*//')Z
_date_day=$(date -u --iso-8601)

create_rootfs_tar $_distro $_date rootfs.tar.xz
cp "$SRCDIR/Dockerfile" .
docker build . -f Dockerfile -t "${REGISTRY}/${_distro}:${_date_day}"
docker push "${REGISTRY}/${_distro}:$_date_day"
popd


