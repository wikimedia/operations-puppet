# SPDX-License-Identifier: Apache-2.0

class openstack::nova::common::flamingo::trixie(
) {
    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
