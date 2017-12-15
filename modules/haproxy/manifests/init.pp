# Class haproxy

class haproxy(
    $template = 'haproxy/haproxy.cfg.erb',
    $socket   = '/run/haproxy/haproxy.sock',
    $pid      = '/run/haproxy/haproxy.pid',
) {

    package { [
        'socat',
        'haproxy',
    ]:
        ensure => present,
    }

    file { '/etc/haproxy/conf.d':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
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
        content => template('modules/haproxy/check_haproxy'),
    }

    if os_version('debian >= jessie') {

        # defaults file cannot be dynamic anymore on systemd
        # pregenerate them on systemd start/reload
        file { '/usr/local/bin/generate_haproxy_default.sh':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
            source => 'puppet:///modules/haproxy/generate_haproxy_default.sh',
        }

        file { '/lib/systemd/system/haproxy.service':
            ensure  => present,
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///modules/haproxy/haproxy.service',
            require => File['/usr/local/bin/generate_haproxy_default.sh'],
            notify  => Exec['/bin/systemctl daemon-reload'],
        }

        exec { '/bin/systemctl daemon-reload':
            user        => 'root',
            refreshonly => true,
        }
    }
    else {
        file { '/etc/default/haproxy':
            ensure  => present,
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            content => template('haproxy/default.erb'),
        }
    }

    nrpe::monitor_service { 'haproxy':
        description  => 'haproxy process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1: -C haproxy',
    }

    nrpe::monitor_service { 'haproxy_alive':
        description  => 'haproxy alive',
        nrpe_command => '/usr/lib/nagios/plugins/check_haproxy --check=alive',
    }
}
