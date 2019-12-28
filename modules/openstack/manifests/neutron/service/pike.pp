class openstack::neutron::service::pike
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::pike::${::lsbdistcodename}"

    package { 'neutron-server':
        ensure => 'present',
    }
}
