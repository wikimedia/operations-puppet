# SPDX-License-Identifier: Apache-2.0

class openstack::nova::conductor::service::caracal
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::caracal::${::lsbdistcodename}"

    package { 'nova-conductor':
        ensure => 'present',
    }
}
