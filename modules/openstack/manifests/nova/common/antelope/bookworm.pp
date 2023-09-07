# SPDX-License-Identifier: Apache-2.0

class openstack::nova::common::antelope::bookworm(
) {
    require ::openstack::serverpackages::antelope::bookworm

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
