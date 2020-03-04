class openstack::nova::conductor::service::queens
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::queens::${::lsbdistcodename}"

    package { 'nova-conductor':
        ensure => 'present',
    }
}
