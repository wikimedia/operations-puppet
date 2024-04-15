# SPDX-License-Identifier: Apache-2.0

class openstack::nova::common::bobcat::bookworm(
) {
    require ::openstack::serverpackages::bobcat::bookworm

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
