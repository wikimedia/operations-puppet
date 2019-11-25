class openstack::nova::placement::service::newton
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::newton::${::lsbdistcodename}"

    package { 'nova-placement-api':
        ensure => 'present',
    }
}
