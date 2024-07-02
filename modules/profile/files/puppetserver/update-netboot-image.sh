#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

if [[ $# -eq 0 ]]; then
    echo 'You need to specific the name of the distro for which firmware should be added, e.g. "buster"'
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

TFTPBOOT_DIR="/srv/puppet_fileserver/volatile/tftpboot/${distro}-installer"
TFTPBOOT_TEMP_DIR="${WD}/${distro}-installer"
echo -e "\n\n"
echo "The updated netboot environment can be found in ${TFTPBOOT_TEMP_DIR}"
echo "Next steps:"
echo "1) Check if everything looks fine in the new dir, comparing the files with previous versions etc.."
echo "2) Save ${TFTPBOOT_DIR} under a different name, so you can roll it back easily if needed."
echo "3) mv ${TFTPBOOT_TEMP_DIR} ${TFTPBOOT_DIR}"
echo "4) rm -rf ${WD}".
echo "5) Remember to run puppet on install servers to update their tftpboot config."
echo -e "\n\n"
