# SPDX-License-Identifier: Apache-2.0

class openstack::designate::service::flamingo
{
    $packages = [
        'designate-sink',
        'designate-common',
        'designate-mdns',
        'designate',
        'designate-api',
        'designate-doc',
        'designate-central',
        'python3-git',
    ]

    package { $packages:
        ensure => 'present',
    }
}
