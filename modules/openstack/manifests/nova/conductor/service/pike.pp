class openstack::nova::conductor::service::pike
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::pike::${::lsbdistcodename}"

    package { 'nova-conductor':
        ensure => 'present',
    }
}
