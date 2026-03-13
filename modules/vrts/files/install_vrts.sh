#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Install VRTS Script
set -x
. /etc/vrts/install-script-vars

# Download VRTS
echo "Downloading VRTS"
if ! /usr/bin/curl -sL "${DOWNLOAD_URL}/znuny-${1}.tar.gz" -o "/tmp/znuny-${1}.tar.gz"; then
    echo "ERROR: Failed Downloading ${DOWNLOAD_URL}/znuny-${1}.tar.gz"
    exit 1
fi

# Extract VRTS
/usr/bin/sudo /usr/bin/tar xfz "/tmp/znuny-${1}.tar.gz" -C /opt

# Set Permissions
/usr/bin/sudo -u root /opt/otrs/bin/otrs.SetPermissions.pl --web-group=www-data

# Create Symlink
/usr/bin/sudo ln -sfn "/opt/znuny-${1}" /opt/otrs
