# SPDX-License-Identifier: Apache-2.0

class openstack::nova::common::dalmatian::bookworm(
) {
    require ::openstack::serverpackages::dalmatian::bookworm

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
