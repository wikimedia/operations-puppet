class openstack::nova::conductor::service::ussuri
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::ussuri::${::lsbdistcodename}"

    package { 'nova-conductor':
        ensure => 'present',
    }
}
