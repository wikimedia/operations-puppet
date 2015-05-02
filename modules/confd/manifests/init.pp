# == Class confd
#
# Installs confd and (optionally) starts it via a base::service_unit define.

class confd(
    $ensure='present',
    $running=false,
    $backend='etcd',
    $node=undef,
    $srv_dns=$::domain,
    $scheme='https',
    $interval=undef,
    ) {

    package { 'confd':
        ensure => present,
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
        service_params => $params,
        require        => Package['confd']
    }

    # Any change to a service configuration or to a template should reload confd.
    Confd::File <| |> ~> Service['confd']

    nrpe::nrpe::monitor_systemd_unit { 'confd':
        require => Service['confd'],
    }
}
