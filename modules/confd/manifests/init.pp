# == Class confd
#
# Installs confd and (optionally) starts it via a base::service_unit define.

class confd(
    $ensure=present,
    $running=true,
    $backend='etcd',
    $node=undef,
    $srv_dns=$::domain,
    $scheme='https',
    $interval=undef,
) {

    package { 'confd':
        ensure => $ensure,
    }

    if $running {
        $params = { ensure => 'running'}
    }
    else {
        $params = { ensure => 'stopped'}
    }

    base::service_unit { 'confd':
        ensure         => $ensure,
        refresh        => true,
        systemd        => true,
        upstart        => true,
        service_params => $params,
        require        => Package['confd'],
    }

    file { '/etc/confd':
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0550',
    }

    file { '/etc/confd/conf.d':
        ensure  => directory,
        recurse => true,
        purge   => true,
        owner   => root,
        group   => root,
        mode    => '0550',
        before  => Service['confd'],
    }

    file { '/etc/confd/templates':
        ensure  => directory,
        recurse => true,
        purge   => true,
        owner   => root,
        group   => root,
        mode    => '0550',
        before  => Service['confd'],
    }

    # Any change to a service configuration or to a template should reload confd.
    Confd::File <| |> ~> Service['confd']

    if $::initsystem == 'systemd' {
        nrpe::monitor_systemd_unit { 'confd':
            require => Service['confd'],
        }
    } else {
        nrpe::monitor_service {'confd':
            description  => 'ensure confd service',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -a /usr/bin/confd -c 1:2',
            require      => Service['confd'],
        }
    }

    # Log to a dedicated file
    file { '/etc/logrotate.d/confd':
        source => 'puppet:///modules/confd/logrotate.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    rsyslog::conf { 'confd':
        source   => 'puppet:///modules/confd/rsyslog.conf',
        priority => 20,
        require  => File['/etc/logrotate.d/confd'],
    }
}
