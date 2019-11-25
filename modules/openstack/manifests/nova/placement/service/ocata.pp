class openstack::nova::placement::service::ocata
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::ocata::${::lsbdistcodename}"

    package { 'nova-placement-api':
        ensure => 'present',
    }
}
