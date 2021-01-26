class openstack::nova::scheduler::service::train
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::train::${::lsbdistcodename}"

    package { 'nova-scheduler':
        ensure => 'present',
    }
}
