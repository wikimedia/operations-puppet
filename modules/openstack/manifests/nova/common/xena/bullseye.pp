# SPDX-License-Identifier: Apache-2.0

class openstack::nova::common::xena::bullseye(
) {
    require ::openstack::serverpackages::xena::bullseye

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
