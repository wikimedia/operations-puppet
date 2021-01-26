class openstack::nova::conductor::service::train
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::train::${::lsbdistcodename}"

    package { 'nova-conductor':
        ensure => 'present',
    }
}
