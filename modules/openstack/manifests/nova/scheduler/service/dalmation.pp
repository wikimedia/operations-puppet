# SPDX-License-Identifier: Apache-2.0

class openstack::nova::scheduler::service::dalmation
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::dalmation::${::lsbdistcodename}"

    package { 'nova-scheduler':
        ensure => 'present',
    }
}
