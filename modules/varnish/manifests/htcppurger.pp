class varnish::htcppurger(
    $varnishes = [ 'localhost:80', 'localhost:3128' ],
    $mc_addrs  = [ '239.128.0.112' ],
) {
    Class[varnish::packages] -> Class[varnish::htcppurger]

    package { 'vhtcpd':
        ensure => latest,
    }

    file { '/etc/default/vhtcpd':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['vhtcpd'],
        content => template('varnish/vhtcpd-default.erb'),
    }

    service { 'vhtcpd':
        ensure     => running,
        require    => Package['vhtcpd'],
        subscribe  => File['/etc/default/vhtcpd'],
        hasstatus  => true,
        hasrestart => true,
    }

    nrpe::monitor_service { 'vhtcpd':
        description  => 'Varnish HTCP daemon',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u vhtcpd -a vhtcpd',
    }
}
