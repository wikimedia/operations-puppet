# SPDX-License-Identifier: Apache-2.0

class openstack::nova::conductor::service::epoxy
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::epoxy::${::lsbdistcodename}"

    package { 'nova-conductor':
        ensure => 'present',
    }
}
