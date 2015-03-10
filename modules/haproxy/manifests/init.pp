# Class haproxy

class haproxy(
    $template  = 'haproxy/haproxy.cfg.erb',
) {

    package { [
        'socat',
        'haproxy',
    ]:
        ensure => present,
    }

    file { '/etc/haproxy/conf.d':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    file { '/etc/default/haproxy':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('haproxy/default.erb'),
    }

    file { '/etc/haproxy/haproxy.cfg':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template($template),
    }

    file { '/usr/lib/nagios/plugins/check_haproxy':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///files/icinga/check_haproxy',
    }

    nrpe::monitor_service { 'haproxy':
        description   => 'haproxy process',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1: -C haproxy',
    }

    nrpe::monitor_service { 'haproxy_alive':
        description   => 'haproxy alive',
        nrpe_command  => '/usr/lib/nagios/plugins/check_haproxy --check=alive',
    }
}
