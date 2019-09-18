class openstack::neutron::service::newton
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::newton::${::lsbdistcodename}"

    package { 'neutron-server':
        ensure => 'present',
    }
}
