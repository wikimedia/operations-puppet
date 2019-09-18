class openstack::nova::conductor::service::newton
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::newton::${::lsbdistcodename}"

    package { 'nova-conductor':
        ensure => 'present',
    }
}
