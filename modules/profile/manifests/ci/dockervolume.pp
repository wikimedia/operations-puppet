# SPDX-License-Identifier: Apache-2.0
# == Class profile::ci::dockervolume
#
# Configures an LVM logical volume just for Docker.
#
# Parameters:
#
#   size => size of the volume passed to lvcreate(8).
#           default to 24G.
#
class profile::ci::dockervolume(
    $size = lookup('profile::ci::dockervolume::size', {'default_value' => '24G'})
) {
    labs_lvm::volume { 'docker':
        size      => $size,
        mountat   => '/var/lib/docker',
        mountmode => '711',
    }

    # Ensure creation of the docker volume before second-local-disk (/srv)
    # since the latter uses a relative size of 100%
    if defined(Class['profile::labs::lvm::srv']) {
        Labs_lvm::Volume['docker'] -> Class['profile::labs::lvm::srv']
    }

    # Ensure volume is created and mounted before Docker is installed
    if defined(Class['docker']) {
        Labs_lvm::Volume['docker'] -> Class['docker']
    }
}
