# SPDX-License-Identifier: Apache-2.0

class openstack::nova::common::zed::bullseye(
) {
    require ::openstack::serverpackages::zed::bullseye

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
