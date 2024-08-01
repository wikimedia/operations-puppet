# SPDX-License-Identifier: Apache-2.0

class openstack::nova::common::caracal::bookworm(
) {
    require ::openstack::serverpackages::caracal::bookworm

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
