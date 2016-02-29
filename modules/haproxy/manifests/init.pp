# Class haproxy

class haproxy(
    $template = 'haproxy/haproxy.cfg.erb',
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
        notify  => Exec['/usr/local/bin/generate_haproxy_default.sh'],
    }

    file { '/usr/lib/nagios/plugins/check_haproxy':
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/haproxy/check_haproxy',
    }

    # if any haproxy config file (including those outside of this class) is changed,
    # update the haproxy config (but do not refresh the service immediatelly)
    file { '/usr/local/bin/generate_haproxy_default.sh':
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/haproxy/generate_haproxy_default.sh',
        notify => Exec['/usr/local/bin/generate_haproxy_default.sh'],
    }

    exec { '/usr/local/bin/generate_haproxy_default.sh':
        refreshonly => true,
    }

    exec { '/tmp/haproxy-config-checksum':
        command => 'find /etc/haproxy/ -name "*.cfg" | xargs md5sum > /tmp/haproxy-config-checksum',
    }

    file { '/tmp/haproxy-config-checksum':
        notify  => Exec['/usr/local/bin/generate_haproxy_default.sh']
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
