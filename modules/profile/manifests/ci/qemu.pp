# SPDX-License-Identifier: Apache-2.0
# == profile::ci::qemu
#
# Setup the bits we need to have Qemu and a base VM image
#
# https://www.mediawiki.org/wiki/Continuous_integration/Qemu
#
class profile::ci::qemu {
    requires_realm('labs')

    file { '/srv/vm-images':
        ensure  => directory,
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        require => Mount['/srv'],
    }

    ensure_packages([
        'coreutils',
        'curl',
        'debootstrap',
        'qemu-system',
        'libguestfs-tools',
    ])

    file { '/usr/local/bin/ci-build-images':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/ci/ci-build-images.sh',
    }

    exec { 'Download image and verify checksum':
        require => File['/srv/vm-images'],
        command => '/usr/local/bin/ci-build-images /srv/vm-images',
        creates => '/srv/vm-images/delta.qcow2',
        # The image customization takes a while
        timeout => 900,  # seconds
    }
}
