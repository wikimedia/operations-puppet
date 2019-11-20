class openstack::nova::conductor::service::ocata
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::ocata::${::lsbdistcodename}"

    package { 'nova-conductor':
        ensure => 'present',
    }
}
