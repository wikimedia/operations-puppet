# SPDX-License-Identifier: Apache-2.0

class openstack::nova::common::flamingo::bookworm(
) {
    require ::openstack::serverpackages::flamingo::bookworm

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
