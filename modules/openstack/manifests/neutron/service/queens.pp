class openstack::neutron::service::queens
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::queens::${::lsbdistcodename}"

    package { 'neutron-server':
        ensure => 'present',
    }
}
