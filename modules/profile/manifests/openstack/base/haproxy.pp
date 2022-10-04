class profile::openstack::base::haproxy(
    Boolean $logging = lookup('profile::openstack::base::haproxy::logging'),
) {

    class { 'haproxy':
        logging  => $logging,
        template => 'profile/openstack/base/haproxy/haproxy.cfg.erb',
    }

    file { '/etc/haproxy/ipblocklist.txt':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/openstack/haproxy/ipblocklist.txt',
    }

    file { '/etc/haproxy/agentblocklist.txt':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/openstack/haproxy/agentblocklist.txt',
    }
}
