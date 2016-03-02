# Class haproxy

class haproxy(
    $ensure    = 'present',
    $template  = 'haproxy/haproxy.cfg.erb',
) {

    package { [
        'socat',
        'haproxy',
    ]:
        ensure => $ensure,
    }

    file { '/etc/haproxy/conf.d':
        ensure => ensure_directory($ensure),
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/default/haproxy':
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('haproxy/default.erb'),
    }

    file { '/etc/haproxy/haproxy.cfg':
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template($template),
    }

    file { '/usr/lib/nagios/plugins/check_haproxy':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/haproxy/check_haproxy',
    }

    nrpe::monitor_service { 'haproxy':
        ensure       => $ensure,
        description  => 'haproxy process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1: -C haproxy',
    }

    nrpe::monitor_service { 'haproxy_alive':
        ensure       => $ensure,
        description  => 'haproxy alive',
        nrpe_command => '/usr/lib/nagios/plugins/check_haproxy --check=alive',
    }
}
