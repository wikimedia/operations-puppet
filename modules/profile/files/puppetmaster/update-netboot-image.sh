#!/bin/bash

if [[ $# -eq 0 ]]; then
    echo 'You need to specific the name of the distro for which firmware should be added, e.g. "jessie"'
    exit 1
fi

if [[ ! -x /bin/pax ]]; then
    echo "pax isn't installed, bailing out"
    exit 1
fi

distro=$1

WD=`mktemp -d`
cd "$WD"

export http_proxy=http://webproxy.eqiad.wmnet:8080
wget http://ftp.us.debian.org/debian/dists/"$distro"/main/installer-amd64/current/images/netboot/netboot.tar.gz
mkdir "$distro"-installer
tar -C "$distro"-installer -zxf netboot.tar.gz

# add non-free firmware to the image
wget http://cdimage.debian.org/cdimage/unofficial/non-free/firmware/"$distro"/current/firmware.tar.gz
mkdir firmware
tar -C firmware -zxf firmware.tar.gz
pax -x sv4cpio -s'%firmware%/firmware%' -w firmware | gzip -c >firmware.cpio.gz
cat firmware.cpio.gz >> "$distro"-installer/debian-installer/amd64/initrd.gz

echo The updated netboot environment can be found in "$WD"/"$distro"-installer, if everyone looks fine, move it to /var/lib/puppet/volatile/tftpboot
echo and make sure to remove "$WD"
