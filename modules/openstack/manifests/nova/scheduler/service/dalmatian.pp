# SPDX-License-Identifier: Apache-2.0

class openstack::nova::scheduler::service::dalmatian
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::dalmatian::${::lsbdistcodename}"

    package { 'nova-scheduler':
        ensure => 'present',
    }
}
