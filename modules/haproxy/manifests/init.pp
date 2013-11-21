# Class haproxy
# Installs haproxy and ensures that it is running.
class haproxy($endpoint_hostname, $endpoint_ip) {
    package { 'haproxy':
        ensure => present,
    }

    file { '/etc/haproxy/haproxy.cfg':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('haproxy/haproxy.cfg.erb'),
        notify  => Service['haproxy']
    }

    service { 'haproxy':
        ensure     => running,
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
    }
}
