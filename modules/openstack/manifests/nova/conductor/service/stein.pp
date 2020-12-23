class openstack::nova::conductor::service::stein
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::stein::${::lsbdistcodename}"

    package { 'nova-conductor':
        ensure => 'present',
    }
}
