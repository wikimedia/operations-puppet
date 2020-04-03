class openstack::nova::scheduler::service::rocky
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::rocky::${::lsbdistcodename}"

    package { 'nova-scheduler':
        ensure => 'present',
    }
}
