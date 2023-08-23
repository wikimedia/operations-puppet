# SPDX-License-Identifier: Apache-2.0

class openstack::nova::common::antelope::bullseye(
) {
    require ::openstack::serverpackages::antelope::bullseye

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
