# SPDX-License-Identifier: Apache-2.0

class openstack::nova::common::epoxy::bookworm(
) {
    require ::openstack::serverpackages::epoxy::bookworm

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
