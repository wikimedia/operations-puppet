# SPDX-License-Identifier: Apache-2.0

class openstack::nova::scheduler::service::caracal
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::caracal::${::lsbdistcodename}"

    package { 'nova-scheduler':
        ensure => 'present',
    }
}
