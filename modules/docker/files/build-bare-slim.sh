#!/bin/bash
set -e
# Things you can override with env variables, but you shouldn't really if not testing.
SRCDIR=${SRCDIR:-/srv/images/base}
REGISTRY=${REGISTRY:-docker-registry.discovery.wmnet}
PUBLIC_REGISTRY=${PUBLIC_REGISTRY:-docker-registry.wikimedia.org}
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
    echo "### Initializing the root filesystem ###"
    echo "### ⚠️: errors in apt updates now can be ignored safely ###"
    debuerreotype-init rootfs $distro $ts
    debuerreotype-minimizing-config rootfs
    echo "### Fixing apt configuration ###"
    # Fix the apt sources here.
    # Please note we're not using debuerreotype here because
    # we want to use the wikimedia sources from the start
    # to save layers later.
    cp "${SRCDIR}/sources/${distro}.sources.list" rootfs/etc/apt/sources.list
    cp  "${SRCDIR}/wikimedia.pub.gpg" "rootfs/etc/apt/trusted.gpg.d/wikimedia-${distro}.pub.gpg"
    cp "${SRCDIR}/wikimedia.preferences" rootfs/etc/apt/preferences.d/wikimedia
    echo 'APT::Install-Recommends "false";' > rootfs/etc/apt/apt.conf.d/00InstallRecommends
    echo "### Updating packages ###"
    # If $http_proxy is set, we need to tell apt to use it now.
    test -n "$http_proxy" && echo "Acquire::http::Proxy \"$http_proxy\";" > rootfs/etc/apt/apt.conf.d/80_proxy
    debuerreotype-apt-get rootfs update -qq
    debuerreotype-apt-get rootfs dist-upgrade -yqq
    test -n "$http_proxy" && rm -f rootfs/etc/apt/apt.conf.d/80_proxy
    echo "### slimify and prepare the tarball ###"
    debuerreotype-slimify rootfs
    debuerreotype-tar rootfs $output
}

pushd $TMPDIR
_distro=$1
_date=$(date -u --iso-8601=minutes | sed 's/+.*//')Z
_date_day=$(date -u +%Y%m%d)
echo "🏗 Creating the tarball for $_distro"
create_rootfs_tar $_distro $_date rootfs.tar.xz
_img="${REGISTRY}/${_distro}"
_imgfull="${_img}:${_date_day}"

echo "🗑️ Now building the docker container"
cp "$SRCDIR/Dockerfile" .
docker build . -f Dockerfile -t "$_imgfull"
popd
docker tag "$_imgfull" "${_img}:latest"
echo "🔥 Publishing images"
docker push "$_imgfull"
docker push "${_img}:latest"
# now remove the latest tag from the public image if present
# We need to ensure people won't try to build images referencing it
# See T268612
echo "🚮 Removing stale local images."
docker rmi "${PUBLIC_REGISTRY}/${_distro}:latest" || /bin/true

# Old image naming compatibility: Also tag the images with wikimedia-$distro
# for buster.
if [[ "$_distro" == "buster" ]]; then
    _imglegacy="${REGISTRY}/wikimedia-${_distro}:latest"
    _imglegacydate="${REGISTRY}/wikimedia-${_distro}:${_date_day}"
    docker tag "$_imgfull" "${_imglegacy}"
    docker push "${_imglegacy}"
    docker tag "$_imgfull" "${_imglegacydate}"
    docker push "${_imglegacydate}"
    # Ensure we don't keep around images tagged with public registry on
    # build hosts. See T268612
    docker rmi "${PUBLIC_REGISTRY}/wikimedia-${_distro}:latest" || /bin/true
    docker rmi "${PUBLIC_REGISTRY}/wikimedia-${_distro}:${_date_day}" || /bin/true
fi
