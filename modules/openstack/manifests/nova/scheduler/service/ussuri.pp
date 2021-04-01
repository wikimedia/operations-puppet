class openstack::nova::scheduler::service::ussuri
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::ussuri::${::lsbdistcodename}"

    package { 'nova-scheduler':
        ensure => 'present',
    }
}
