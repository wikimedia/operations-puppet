# SPDX-License-Identifier: Apache-2.0

class openstack::designate::service::antelope
{
    # this class seems simple enough to don't require per-debian release split
    # now, will revisit later
    require "openstack::serverpackages::antelope::${::lsbdistcodename}"

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
