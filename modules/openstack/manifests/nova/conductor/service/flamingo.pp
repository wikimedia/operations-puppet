# SPDX-License-Identifier: Apache-2.0

class openstack::nova::conductor::service::flamingo
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::flamingo::${::lsbdistcodename}"

    package { 'nova-conductor':
        ensure => 'present',
    }
}
