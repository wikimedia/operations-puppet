class openstack::nova::scheduler::service::pike
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::pike::${::lsbdistcodename}"

    package { 'nova-scheduler':
        ensure => 'present',
    }
}
