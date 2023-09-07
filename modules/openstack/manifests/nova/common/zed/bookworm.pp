# SPDX-License-Identifier: Apache-2.0

class openstack::nova::common::zed::bookworm(
) {
    require ::openstack::serverpackages::zed::bookworm

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
