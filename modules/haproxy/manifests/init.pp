# Class haproxy

# Puppet does not start, restart, or reload the service.

class haproxy(
    $template  = 'haproxy/haproxy.cfg.erb',
    ) {

    package { 'haproxy':
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
}
