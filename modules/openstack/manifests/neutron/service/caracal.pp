# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::service::caracal(
    Stdlib::Port $bind_port,
    Boolean $active,
    ) {
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::caracal::${::lsbdistcodename}"

    service {'neutron-api':
        ensure    => $active,
        require   => Package['neutron-server', 'neutron-api'],
        subscribe => [
                      File['/etc/neutron/neutron.conf'],
                      File['/etc/neutron/policy.yaml'],
                      File['/etc/neutron/plugins/ml2/ml2_conf.ini'],
            ],
    }

    service {'neutron-rpc-server':
        ensure    => $active,
        require   => Package['neutron-server'],
        subscribe => [
                      File['/etc/neutron/neutron.conf'],
                      File['/etc/neutron/policy.yaml'],
                      File['/etc/neutron/plugins/ml2/ml2_conf.ini'],
            ],
    }

    package { 'neutron-api':
        ensure => 'present',
    }
    package { 'neutron-server':
        ensure => 'present',
    }

    file {
        '/etc/init.d/neutron-api':
            content => template('openstack/caracal/neutron/neutron-api.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            notify  => Service['neutron-api'],
            require => Package['neutron-server', 'neutron-api'];
        '/etc/neutron/neutron-api-uwsgi.ini':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/caracal/neutron/neutron-api-uwsgi.ini',
            notify  => Service['neutron-api'],
            require => Package['neutron-server'];
        '/etc/neutron/api-paste.ini':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/caracal/neutron/api-paste.ini',
            notify  => Service['neutron-api'],
            require => Package['neutron-server'];
        '/var/run/neutron/':
            ensure => directory,
            owner  => 'neutron',
            group  => 'neutron',
            mode   => '0755';

    }
}
