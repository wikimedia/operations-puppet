class openstack::nova::conductor::service::mitaka
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::mitaka::${::lsbdistcodename}"

    package { 'nova-conductor':
        ensure => 'present',
    }
}
