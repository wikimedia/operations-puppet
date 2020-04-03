class openstack::nova::conductor::service::rocky
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::rocky::${::lsbdistcodename}"

    package { 'nova-conductor':
        ensure => 'present',
    }
}
