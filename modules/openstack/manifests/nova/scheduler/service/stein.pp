class openstack::nova::scheduler::service::stein
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::stein::${::lsbdistcodename}"

    package { 'nova-scheduler':
        ensure => 'present',
    }
}
