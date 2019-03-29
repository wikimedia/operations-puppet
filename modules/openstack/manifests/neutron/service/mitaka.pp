class openstack::neutron::service::mitaka
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::mitaka::${::lsbdistcodename}"

    package { 'neutron-server':
        ensure => 'present',
    }
}
