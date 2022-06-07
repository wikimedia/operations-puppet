# SPDX-License-Identifier: Apache-2.0
class initramfs {
    package { 'initramfs-tools':
        ensure => installed,
    }

    exec { 'update-initramfs':
        refreshonly => true,
        command     => 'update-initramfs -u -k all',
        path        => '/bin:/usr/bin:/sbin:/usr/sbin',
        require     => Package['initramfs-tools'],
    }
}
