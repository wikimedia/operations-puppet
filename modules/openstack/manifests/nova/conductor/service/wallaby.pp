class openstack::nova::conductor::service::wallaby
{
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::wallaby::${::lsbdistcodename}"

    package { 'nova-conductor':
        ensure => 'present',
    }
}
