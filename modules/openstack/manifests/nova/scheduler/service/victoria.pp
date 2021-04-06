class openstack::nova::scheduler::service::victoria
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::victoria::${::lsbdistcodename}"

    package { 'nova-scheduler':
        ensure => 'present',
    }
}
