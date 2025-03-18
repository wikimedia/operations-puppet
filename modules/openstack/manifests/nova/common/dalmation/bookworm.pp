# SPDX-License-Identifier: Apache-2.0

class openstack::nova::common::dalmation::bookworm(
) {
    require ::openstack::serverpackages::dalmation::bookworm

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
