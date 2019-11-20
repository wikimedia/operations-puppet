class openstack::neutron::service::ocata
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::ocata::${::lsbdistcodename}"

    package { 'neutron-server':
        ensure => 'present',
    }
}
