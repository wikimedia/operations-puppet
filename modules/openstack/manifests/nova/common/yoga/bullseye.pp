# SPDX-License-Identifier: Apache-2.0

class openstack::nova::common::yoga::bullseye(
) {
    require ::openstack::serverpackages::yoga::bullseye

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
